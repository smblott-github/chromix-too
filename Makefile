src := $(wildcard *.coffee */*.coffee)
js  := $(src:.coffee=.js)

build: $(js)

auto:
	npx watch -n 1 "make build"

%.js: %.coffee
	npx coffee -c --bare --no-header $<

install: build
	sudo npm install -g .

extension:
	$(MAKE) -C extension package

publish: build
	npm publish

.PHONY: build auto install extension publish
