`#!/usr/bin/env node
`

config =
  port: "7442"
  host: "localhost"
  sock: require("path").join process.env["HOME"], ".chromix-too.sock"

try
  optimist = require "optimist"
catch
  console.error "optimist package not found (try something like 'npm install optimist')"
  process.exit 1

args = optimist.usage("Usage: $0 [--sock=PATH]")
  .alias("h", "help")
  .default("sock", config.sock)
  .argv

if args.help
  optimist.showHelp()
  process.exit(0)

extend = (hash1, hash2) ->
  for own key of hash2
    hash1[key] = hash2[key]
  hash1

# This sends a single request to chrome, unpacks the response, and calls callback.
chromix = (path, request, callback = (->)) ->
  extend request, {path}
  client = require("net").connect args.sock, ->
    client.write JSON.stringify request

  client.on "data", (data) ->
    callback JSON.parse(data.toString "utf8").response...
    client.destroy()

# If invoked as "ct-ls", then the command is "ls"; otherwise, the command is the first argument.
invocationName = require("path").basename process.argv[1]
[ commandName, commandArgs ] =
  if invocationName.indexOf("ct-") == 0
    [ invocationName[3..], process.argv[2..] ]
  else
    [ process.argv[2], process.argv[3...] ]

unless commandName
  console.error "error: no command provided"
  process.exit 2

# Extract the query flags (for chrome.tabs.query) from the arguments.  Return the new arguments and the query
# flags.
getTabQueryFlags = (commandArgs) ->
  tabQueryFlags = {}
  validTabQueryFlags = {}
  # These are the valid boolean flags listed here: https://developer.chrome.com/extensions/tabs#method-query.
  for flag in "active pinned audible muted highlighted discarded autoDiscardable currentWindow lastFocusedWindow".split " "
    validTabQueryFlags[flag] = true
  commandArgs =
    for arg in commandArgs[..]
      if arg of validTabQueryFlags
        tabQueryFlags[arg] = true
        continue
      # Use a leading "-" or "!" to negate the test; e.g. "-audible" or "!active".
      else if arg[0] in ["-", "!"] and arg[1..] of validTabQueryFlags
        tabQueryFlags[arg[1..]] = false
        continue
      else
        arg
  [ commandArgs, tabQueryFlags ]

# Filter tabs by the remaining command-line arguements.  We require a match in either the URL or the title.
# If the argument is a number, then we require it to match the tab Id.
filterTabs = do ->
  integerRegex = /^\d+$/

  (commandArgs, tabs) ->
    for tab in tabs
      continue unless do ->
        for arg in commandArgs
          if integerRegex.test(arg) and tab.id == parseInt arg
            continue
          else if integerRegex.test arg
            return false
          else if tab.url.indexOf(arg) == -1 and tab.title.indexOf(arg) == -1
            return false
        true
      tab

getMatchingTabs = (commandArgs, callback) ->
  [ commandArgs, tabQueryFlags ] = getTabQueryFlags commandArgs
  chromix "chrome.tabs.query", {args: [tabQueryFlags]}, (tabs) ->
    process.exit 1 if tabs.length == 0
    callback filterTabs commandArgs, tabs

focusWindow = (windowId) ->
  chromix "chrome.windows.update", {args: [windowId, {focused: true}]}, ->

switch commandName
  when "ls", "list", "tabs"
    getMatchingTabs commandArgs, (tabs) ->
      console.log "#{tab.id} #{tab.url} #{tab.title}" for tab in tabs

  when "tid" # Like "ls", but outputs only the tab Id of the matching tabs.
    getMatchingTabs commandArgs, (tabs) ->
      console.log "#{tab.id}" for tab in tabs

  when "focus", "activate"
    getMatchingTabs commandArgs, (tabs) ->
      chromix "chrome.tabs.update", {args: [tab.id, selected: true]} for tab in tabs

  when "reload"
    getMatchingTabs commandArgs, (tabs) ->
      chromix "chrome.tabs.reload", {args: [tab.id, {}]} for tab in tabs

  when "rm", "remove", "close"
    getMatchingTabs commandArgs, (tabs) ->
      chromix "chrome.tabs.remove", args: [(tab.id for tab in tabs)]

  when "open", "create"
    for arg in commandArgs
      do (arg) ->
        chromix "chrome.tabs.create", {args: [{url: arg}]}, (tab) ->
          console.log "#{tab.id} #{tab.url}"

  when "file"
    for arg in commandArgs
      url = "file://#{require("path").resolve arg}"
      do (url) ->
        getMatchingTabs [], (tabs) ->
          tabs = (t for t in tabs when t.url.indexOf(url) == 0)
          if tabs.length == 0
            chromix "chrome.tabs.create", {args: [{url: url}]}, (tab) ->
              focusWindow tab.windowId
              console.log "#{tab.id} #{tab.url}"
          else
            for tab in tabs
                do (tab) ->
                  chromix "chrome.tabs.update", {args: [tab.id, selected: true]}, ->
                    chromix "chrome.tabs.reload", {args: [tab.id, {}]}, ->
                      focusWindow tab.windowId

  else
    console.error "error: unknown command: #{commandName}"
    process.exit 2
