

.PHONY := all test lint

all: test

test: lint
	busted test.lua

lint:
	luacheck .
