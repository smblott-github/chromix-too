`#!/usr/bin/env node
`
utils = require "./utils.js"
utils.extend global, utils

optimist = require "optimist"
args = optimist.usage("Usage: $0 [--port=PORT] [--host=ADDRESS] [--sock=PATH] [--mode=MODE]")
  .alias("h", "help")
  .default("port", config.port)
  .default("host", config.host)
  .default("sock", config.sock)
  .default("mode", config.mode)
  .argv

if args.help
  optimist.showHelp()
  process.exit 0

responseHandlers = {}
webSock = null

WSS  = require("ws").Server
wss  = new WSS port: args.port, host: args.host
wss.on "connection", (ws) ->
  console.log "#{new Date().toString()}: websocket client connected"
  webSock = ws
  ws.on "message", (msg) ->
    responseHandlers[JSON.parse(msg).clientId]? msg

uniqueId = Math.floor(2000000000 * Math.random()).toString()
clientId = 0

handleWebsocketError = (request) ->
  responseHandlers[request.clientId]? JSON.stringify extend request, error: "websocket is not connected"
  responseHandlers = {}
  webSock = null

server = require("net").createServer (sock) ->
  clientId += 1
  myClientId = "#{uniqueId}-#{clientId}"
  responseHandlers[myClientId] = sock.write.bind sock

  sock.on "data", (data) ->
    try
      request = JSON.parse data
    catch
      console.error "failed to parse JSON: #{data}"
    try
      extend request, clientId: myClientId
      webSock.send JSON.stringify(request), (err) ->
        handleWebsocketError request if err
    catch
      handleWebsocketError request

  sock.on "close", ->
    delete responseHandlers[myClientId]

require("fs").unlink args.sock, ->
  server.listen args.sock, ->
    require("fs").chmod args.sock, args.mode, ->
      console.log "listening on: #{args.sock}"
