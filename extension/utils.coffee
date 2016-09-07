root = exports ? window

extend = root.extend = (hash1, hash2) ->
  hash1[key] = hash2[key] for own key of hash2
  hash1

extend root,
  config:
    host: "localhost"
    port: "7442"
    timeout: 5000

  makeIdempotent: (func) ->
    (args...) -> ([previousFunc, func] = [func, null])[0]? args...
