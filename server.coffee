
config =
  port: "7442"
  host: "localhost"
  sock: require("path").join process.env["HOME"], ".chromix-too.sock"

try
  optimist = require "optimist"
catch
  console.error "optimist package not found (try something like 'npm install optimist')"
  process.exit 1

args = optimist.usage("Usage: $0 [--port=PORT] [--host=ADDRESS] [--sock=PATH]")
  .alias("h", "help")
  .default("port", config.port)
  .default("host", config.host)
  .default("sock", config.sock)
  .argv

if args.help
  optimist.showHelp()
  process.exit(0)

clientHandlers = {}
webSock = null

try
  WSS  = require("ws").Server
catch
  console.error "ws package not found (try something like 'npm install ws')"
  process.exit 1

wss  = new WSS { port: args.port, host: args.host }
wss.on "connection", (ws) ->
  console.log "#{new Date().toString()}: websocket client connected"
  webSock = ws
  ws.on "message", (msg) ->
    clientHandlers[JSON.parse(msg).clientId]? msg

extend = (hash1, hash2) ->
  for own key of hash2
    hash1[key] = hash2[key]
  hash1

clientId = 0
server = require("net").createServer (sock) ->
  myClientId = clientId += 1

  clientHandlers[myClientId] = sock.write.bind sock

  sock.on "data", (data) ->
    try
      request = JSON.parse data
    catch
      console.error "failed to parse JSON: #{data}"
    try
      webSock.send JSON.stringify extend request, clientId: myClientId
    catch
      console.error "failed to send message; perhaps the chrome extension isn't connected"

  sock.on "close", ->
    delete clientHandlers[myClientId]

require("fs").unlink args.sock, ->
  server.listen args.sock
  console.log "listening on: #{args.sock}"
