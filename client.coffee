
config =
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

client = require("net").connect args.sock, ->
  client.write JSON.stringify path: "chrome.storage.local.get", args: ["pi"]

  client.on "data", (data) ->
    console.log data.toString "utf8"
    process.exit 0
