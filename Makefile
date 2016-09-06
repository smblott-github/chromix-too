
src = $(wildcard server/*.coffee client/*.coffee bin/*.coffee)
js  = $(src:.coffee=.js)

build: $(js)
	@true

auto:
	coffee -cw .

extension:
	$(MAKE) -C extension build

%.js: %.coffee
	coffee -c $<

server/server.js: server/server.coffee
	coffee -c --bare --no-header $<

.PHONY: build auto extension
