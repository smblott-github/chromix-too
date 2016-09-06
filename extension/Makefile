
src = $(wildcard *.coffee)
js  = $(src:.coffee=.js)

build: $(js)
	@true

auto:
	coffee -cw .

%.js: %.coffee
	coffee -c $<

.PHONY: build auto
