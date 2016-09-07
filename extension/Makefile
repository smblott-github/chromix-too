
src = $(wildcard *.coffee)
js  = $(src:.coffee=.js)

build: $(js)
	@true

auto:
	coffee -cw .

%.js: %.coffee
	coffee -c $<

.PHONY: build auto package

pkg = chromix-too.zip

package:
	! test -f $(pkg) || rm -vf $(pkg)
	$(MAKE) build
	zip chromix-too.zip \
	   manifest.json \
	   utils.js \
	   background.js \
	   foreground.js
