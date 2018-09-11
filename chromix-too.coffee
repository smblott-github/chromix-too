
# Usage:
#   see examples in ./client.coffee.

utils = require "./utils"
utils.extend global, utils

module.exports = (sock = config.sock) ->

  # This sends a single request to chrome, unpacks the response, and calls any callbacks with the response as
  # argument(s).
  chromix:
    (path, request, extra_arguments...) ->
      extend request, {path}
      request.args ?= []
      callbacks = []

      # Extra arguments which are functions are callbacks (usually just one); all other arguments are added to the
      # list of arguments.
      for arg in extra_arguments
        (if typeof(arg) == "function" then callbacks else request.args).push arg

      client = require("net").connect sock, ->
        client.write JSON.stringify request

      dataParts = []
      client.on "data", (data) ->
        dataParts.push(data);
        if data.length != 65536
          concatData = Buffer.concat(dataParts)
          response = JSON.parse concatData.toString "utf8"
          if response.error
            console.error "error: #{response.error}"
            process.exit 1
          callback response.response... for callback in callbacks
          client.destroy()
