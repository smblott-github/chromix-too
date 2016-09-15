
src = utils.coffee extension/utils.coffee chromix-too.coffee server.coffee client.coffee
js  = $(src:.coffee=.js)

build: $(js)
	@true

auto:
	watch -n 1 make build

install:
	$(MAKE) build
	sudo npm install -g .

extension:
	$(MAKE) -C extension build

%.js: %.coffee
	coffee -c --bare --no-header $<

publish:
	$(MAKE) build
	npm publish

.PHONY: build auto install extension publish
