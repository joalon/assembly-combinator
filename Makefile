

.PHONY := all test lint render

all: test

render:
	blender -b assets/combinator.blend --python assets/render.py

test: lint
	busted test.lua

lint:
	luacheck .
