
src = server.coffee client.coffee
js  = $(src:.coffee=.js)

build: $(js)
	@true

install:
	$(MAKE) build
	sudo npm install -g .

extension:
	$(MAKE) -C extension build

%.js: %.coffee
	coffee -c --bare --no-header $<

.PHONY: build install extension
