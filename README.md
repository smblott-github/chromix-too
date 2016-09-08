# Chromix-Too

This project provides external (e.g. command-line or scripted) access to Chrome's internal (Javascript) API's.

For example, the following command closes all tabs on stackoverflow:

    chromix-too rm stackoverflow.com

Chromix-too is a replacement for
[chromix](https://github.com/smblott-github/chromix).  Chromix-too is
considerably simpler, uses a Unix-domain socket for communication between
client and server (which is more secure), and is better packaged (it can be used as a module too).

## Getting started

There are three components: a chrome extension, a server and the `chromix-too` utility.

Install [the extension](https://chrome.google.com/webstore/detail/chromix-too/ppapdfccnamacakfkpfmpfnefpeajboj) from the Chrome Store.

To install the server and the `chromix-too` utility:

```shell
sudo npm install -g chromix-too
```

Next, you need to run the server:

```shell
chromix-too-server
```

And try out the client:

```shell
chromix-too ls
```

Of course, you need to keep the server running all the time.  There are many ways to do this, but I use [daemontools](https://cr.yp.to/daemontools.html);  my daemontools `run` file is just:

```shell
PATH="/usr/local/bin:$PATH"
HOME='/home/blott' exec setuidgid blott chromix-too-server
```

(Or perhaps just leave the server running in a tmux session.)

## Commands

List tabs:

```shell
chromix-too ls
```

List just tab Ids:

```shell
chromix-too tid
```

Focus a tab:

```shell
chromix-too focus https://github.com/smblott-github/chromix
```

Remove a tab:

```shell
chromix-too rm https://github.com/smblott-github/chromix
```

Reload a tab:

```shell
chromix-too reload https://github.com/smblott-github/chromix
```

Open a tab:

```shell
chromix-too open https://github.com/smblott-github/chromix
```

View a file:

```shell
chromix-too file ./README.html
```

(The `file` command also focuses and reloads an existing tab if one exists.)

Verify that everything is running correctly:

```shell
chromix-too ping
```

### Raw JSON

Call any available Chrome function from the command line:

```shell
chromix-too raw chrome.storage.local.set '{"pi": 3.141}'

chromix-too raw chrome.storage.local.get pi
# {"pi":3.141}

chromix-too raw chrome.storage.local.get pi | jq '.pi'
# 3.141
```

## Filters

For all of the commands above (except where it doesn't make sense), you can
filter the list of tabs to which the command applies.

There are three kinds of filter:

1. If the filter is just a bare number, then it is interpreted as a tab Id.

2. If the filter is one of the boolean options described
   [here](https://developer.chrome.com/extensions/tabs#method-query), then the
   corresponding flag is set.  For example, you can use `pinned` to operate on all pinned tabs.

    These boolean flags can be inverted: `-pinned` selects all unpinned tabs.

3. Any remaining filter arguments are treated as queries.  Tabs are removed
   from consideration unless the query text is present in either the tab's URL
   or the tab's title.

Examples:

```shell
# Remove the tab with this tab Id.
chromix-too rm 1234

# Remove all audible tabs.
chromix-too rm audible

# Remove all unpinned tabs.
chromix-too rm -pinned

# List GMail tabs.
chromix-too ls mail.google.com

# Focus my Google Inbox tab.
chromix-too focus Inbox smblott@gmail.com
```

All commands which accept filters fail (so, yield a non-zero exit status) if there are no matching tabs.

## Usage as a module

It is also possible to use `chromix-too` as a node module; here's an example:

```Coffeescript
chromix = require("chromix-too")().chromix

chromix "chrome.storage.local.set", {}, {pi: 3.141}, ->
  chromix "chrome.storage.local.get", {}, "pi", (response) ->
    console.log response.pi
```

The second argument (`{}`, here) is a place holder for future extensions.

The general form is:

```Coffeescript
chromix PATH, REQUEST, ARGS..., CALLBACK
```

The number of `ARGS...` provided must match the number of (non-callback) arguments expected by the relevant
Chrome API call.  When the call is actually made, chromix-too simply
appends its own callback, and that callback must be in the correct argument position.

## Known issues

- There is currently no way to set the websocket port used between the Chrome extension and the server.
- Only background-page API calls are possible.  It is intended to add the ability to invoke functions in a content script at some point in the future.

Contributions are welcome.
