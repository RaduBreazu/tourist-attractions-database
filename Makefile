all: build run clean

build:
	cabal build -j8

run: build
	cabal exec touristDatabase

.PHONY: clean
clean:
	rm -rf dist-newstyle