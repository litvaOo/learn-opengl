run: build
	./target/main

build: validate-shaders
	mkdir -p target/ && odin build . -out:target/main -debug

validate-shaders:
	glslang shaders/*
