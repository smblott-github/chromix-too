
utils = require "./extension/utils"
utils.extend exports, utils

utils.extend exports.config,
  sock: require("path").join process.env["HOME"], ".chromix-too.sock"
  mode: "0600"
