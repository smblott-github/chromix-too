
url = null
config =
  host: "localhost" # For URI of server.
  port: "7442"      # For URI of server.
  timeout: 5000     # Heartbeat frequency in milliseconds.

extend = (hash1, hash2) ->
  hash1[key] = hash2[key] for own key of hash2
  hash1

requestHandler = (sock) -> ({data}) ->
  request = JSON.parse data
  request.args ?= []
  {path} = request

  unless path
    sock.send JSON.stringify extend request, error: true
    return

  if path == "ping"
    sock.send JSON.stringify extend request, error: false, response: ["ok"]
    return


  obj = window
  for property in path.split "."
    try
      obj = obj[property]
    catch
      sock.send JSON.stringify extend request, error: true
      return

  unless obj
    sock.send JSON.stringify extend request, error: true
  else
    switch typeof obj
      when "function"
        obj request.args..., (response...) ->
          sock.send JSON.stringify extend request, response: response, error: false
      else
        sock.send JSON.stringify extend request, response: obj, error: false

makeIdempotent = (func) ->
  (args...) -> ([previousFunc, func] = [func, null])[0]? args...

reTryConnect = ->
  console.log "disconnected"
  setTimeout tryConnect, config.timeout

tryConnect = ->
  reTryFunction = makeIdempotent reTryConnect
  try
    url ?= "ws://#{config.host}:#{config.port}/"
    sock = new WebSocket url
  catch
    reTryFunction()
  sock.onerror = sock.onclose = reTryFunction
  sock.onmessage = requestHandler sock
  console.log "connected: #{url}"

if window.WebSocket?
  console.log "disconnected"
  tryConnect()
else
  console.log "window.WebSocket is not available."
