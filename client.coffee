`#!/usr/bin/env node
`
utils = require "./utils"
utils.extend global, utils

optimist = require "optimist"
args = optimist.usage("Usage: $0 [--sock=PATH]")
  .alias("h", "help")
  .default("sock", config.sock)
  .argv

if args.help
  optimist.showHelp()
  process.exit(0)

chromix = require("./chromix-too")(args.sock).chromix

[ commandName, commandArgs ] =
  if 0 < args._.length then [ args._[0], args._[1...] ] else [ "ping", [] ]
# Extract the query flags (for chrome.tabs.query) from the arguments.  Return the new arguments and the
# query-flags object.
getQueryFlags = (commandArgs) ->
  validQueryFlags = {}
  # These are the valid boolean flags listed here: https://developer.chrome.com/extensions/tabs#method-query.
  for flag in "active pinned audible muted highlighted discarded autoDiscardable currentWindow lastFocusedWindow".split " "
    validQueryFlags[flag] = true
  queryFlags = {}
  commandArgs =
    for arg in commandArgs
      if arg of validQueryFlags
        queryFlags[arg] = true
        continue
      # Use a leading "-" or "!" to negate the test; e.g. "-audible" or "!active".
      else if arg[0] in ["-", "!"] and arg[1..] of validQueryFlags
        queryFlags[arg[1..]] = false
        continue
      # For symmetry, we also allow "+"; e.g. "+audible".
      else if arg[0] in ["+"] and arg[1..] of validQueryFlags
        queryFlags[arg[1..]] = true
        continue
      else
        arg
  [ commandArgs, queryFlags ]

# Filter tabs by the remaining command-line arguements.  We require a match in either the URL or the title.
# If the argument is a bare number, then we require it to match the tab Id.
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

# Return an array of tabs matching the flags and other arguments on the command line.
getMatchingTabs = (commandArgs, callback) ->
  [ commandArgs, queryFlags ] = getQueryFlags commandArgs
  chromix "chrome.tabs.query", {}, queryFlags, (tabs) ->
    tabs = filterTabs commandArgs, tabs
    process.exit 1 if tabs.length == 0
    callback tabs

focusWindow = (windowId) ->
  chromix "chrome.windows.update", {}, windowId, {focused: true}, ->

switch commandName
  when "ls", "list", "tabs"
    getMatchingTabs commandArgs, (tabs) ->
      console.log "#{tab.id} #{tab.url} #{tab.title}" for tab in tabs

  when "tid" # Like "ls", but outputs only the tab Id of the matching tabs.
    getMatchingTabs commandArgs, (tabs) ->
      console.log "#{tab.id}" for tab in tabs

  when "focus", "activate"
    getMatchingTabs commandArgs, (tabs) ->
      for tab in tabs
        chromix "chrome.tabs.update", {}, tab.id, {selected: true}
        focusWindow tab.windowId

  when "select"
    getMatchingTabs commandArgs, (tabs) ->
      for tab in tabs
        chromix "chrome.tabs.update", {}, tab.id, {selected: true}

  when "reload"
    getMatchingTabs commandArgs, (tabs) ->
      chromix "chrome.tabs.reload", {}, tab.id, {} for tab in tabs

  when "url"
    [url, commandArgs...] = commandArgs
    getMatchingTabs commandArgs, (tabs) ->
      chromix "chrome.tabs.update", {}, tab.id, {url} for tab in tabs

  when "rm", "remove", "close"
    getMatchingTabs commandArgs, (tabs) ->
      chromix "chrome.tabs.remove", {}, tab.id for tab in tabs

  when "open", "create"
    for arg in commandArgs
      do (arg) ->
        chromix "chrome.tabs.create", {}, {url: arg}, (tab) ->
          focusWindow tab.windowId
          console.log "#{tab.id} #{tab.url}"

  when "ping"
    chromix "ping", {}, (response) ->
      if response == "ok"
        process.exit 0
      else
        process.exit 1

  when "file"
    for arg in commandArgs
      url = if arg.indexOf("file://") == 0 then arg else "file://#{require("path").resolve arg}"

      do (url) ->
        getMatchingTabs [], (tabs) ->
          tabs = (t for t in tabs when t.url.indexOf(url) == 0)
          if tabs.length == 0
            chromix "chrome.tabs.create", {}, {url: url}, (tab) ->
              focusWindow tab.windowId
              console.log "#{tab.id} #{tab.url}"
          else
            for tab in tabs
                do (tab) ->
                  chromix "chrome.tabs.update", {}, tab.id, {selected: true}, ->
                    chromix "chrome.tabs.reload", {}, tab.id, {}, ->
                      focusWindow tab.windowId

  when "raw", "josn"
    args =
      for arg in commandArgs[1..]
        try
          JSON.parse arg
        catch
          arg
    chromix commandArgs[0], {}, args..., (response) ->
      console.log JSON.stringify response

  else
    console.error "error: unknown command: #{commandName}"
    process.exit 2
