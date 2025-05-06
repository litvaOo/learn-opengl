run: build
	./target/main

build:
	mkdir -p target/ && odin build . -out:target/main -debug
