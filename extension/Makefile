src := $(wildcard *.coffee)
js  := $(src:.coffee=.js)

build: $(js)

auto:
	npx watch -n 1 "make build"

%.js: %.coffee
	npx coffee -c --bare --no-header $<

pkg := chromix-too.zip

$(pkg): $(js) manifest.json
	zip $(pkg) manifest.json $(js)

package: $(pkg)

.PHONY: build auto package
