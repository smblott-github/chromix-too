
chromix = require("chromix-too")().chromix

chromix "chrome.storage.local.set", {}, {pi: 3.141}, ->
  chromix "chrome.storage.local.get", {}, "pi", (response) ->
    console.log response.pi

# If the unix-domain socket were not in the default localtion, then use something like:
#
#   chromix = require("chromix-too")("/var/run/chromix-too.sock").chromix
