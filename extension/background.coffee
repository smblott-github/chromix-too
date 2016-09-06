
config =
  host: "localhost" # For URI of server.
  port: "7442"      # For URI of server.
  timeout:  1000    # Heartbeat frequency in milliseconds.

extend = (hash1, hash2) ->
  for own key of hash2
    hash1[key] = hash2[key]
  hash1

requestHandler = (sock) -> ({data}) ->
  request = JSON.parse data
  request.args ?= []
  {path} = request

  unless path
    sock.send JSON.stringify extend request, error: true
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
  setTimeout tryConnect, config.timeout

tryConnect = ->
  reTryFunction = makeIdempotent reTryConnect
  try
    sock = new WebSocket "ws://#{config.host}:#{config.port}/"
  catch
    reTryFunction()
  sock.onerror = sock.onclose = reTryFunction
  sock.onmessage = requestHandler sock

if window.WebSocket?
  tryConnect()
else
  console.log "window.WebSocket is not available."
