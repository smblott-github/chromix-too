# TODO:
#   - Add a config page to set port (and possibly host) of the server.

handleRequest = (sock) -> ({data}) ->
  request = JSON.parse data
  request.args ?= []
  {path} = request

  if not path?
    sock.send JSON.stringify extend request, error: "requests does not contain a path"

  else if path == "ping"
    sock.send JSON.stringify extend request, response: ["ok"], error: false

  else
    obj = window
    for property in path.split "."
      try
        obj = obj[property]
      catch
        sock.send JSON.stringify extend request, error: "incorrect path: #{path}"
        return

    switch typeof obj
      when "function"
        obj request.args..., (response...) ->
          sock.send JSON.stringify extend request, response: response, error: false
      else
        sock.send JSON.stringify extend request, response: [obj], error: false

reTryConnect = ->
  console.log "disconnected, retry connection in #{config.timeout}ms..."
  setTimeout tryConnect, config.timeout

tryConnect = ->
  reTryFunction = makeIdempotent reTryConnect
  try
    url = "ws://#{config.host}:#{config.port}/"
    sock = new WebSocket url
  catch
    reTryFunction()
  sock.onerror = sock.onclose = reTryFunction
  sock.onmessage = handleRequest sock
  console.log "connected: #{url}"

tryConnect()

