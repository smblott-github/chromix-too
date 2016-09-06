
config =
  host: "localhost" # For URI of server.
  port: "7442"      # For URI of server.
  timeout:  5000    # Heartbeat frequency in milliseconds.

requestHandler = (args...) ->
  console.log args...

makeIdempotent = (func) ->
  (args...) -> ([previousFunc, func] = [func, null])[0]? args...

reTryConnect = ->
  console.log "reTryConnect"
  setTimeout tryConnect, config.timeout

tryConnect = ->
  reTryFunction = makeIdempotent reTryConnect
  try
    sock = new WebSocket "ws://#{config.host}:#{config.port}/"
  catch
    reTryFunction()
  sock.onerror = sock.onclose = reTryFunction
  sock.onmessage = requestHandler

if window.WebSocket?
  tryConnect()
else
  console.log "window.WebSocket is not available."
