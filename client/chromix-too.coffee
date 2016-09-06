
sock_path = require("path").join process.env["HOME"], ".chromix-too.sock"

module.exports = (request, callback, sock = sock_path) ->
  client = require("net").connect sock, ->
    client.write JSON.stringify request

  client.on "data", (data) ->
    callback JSON.parse data.toString "utf8"
    client.destroy()

