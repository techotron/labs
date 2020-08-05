# Links

- [What the compiler is doing]

# Install Compiler
You need to install the protobuf compiler, `protoc`. Then use `proto-gen-go` which is a plugin for `protoc` which allows you to generate Golang code for a given .proto file.

Install the protobuf compiler (this is used in conjunction with the comipler plugin: `protoc-gen-go` to generate the Golang code). [Instructions](https://github.com/protocolbuffers/protobuf/blob/master/src/README.md)

1. Download latest release from here: https://github.com/protocolbuffers/protobuf/releases/
1. Extract: `tar -zxvf protobuf-all-3.12.4.tar.gz`
1. Run the following (checkout Instructions above incase they've changed)

```bash
 ./configure
 make
 make check
 sudo make install
 sudo ldconfig # refresh shared library cache.
```

Install `protoc-gen-go` plugin: `go install google.golang.org/protobuf/cmd/protoc-gen-go`

# Packages for runtime
Install the protobuf package (used in the Go runtime)

```bash
go get github.com/golang/protobuf/proto
```

# Generate Code
This will generate the Go code for using all `.proto` files in the current directory.

```bash
protoc --go_out=paths=source_relative:./ *.proto
```

**Note:** The `--go_out=paths=source_relative` part specifies where the outputted Go files are created. This is necessary since the requirement to add the `option go_package` keyword in the `.proto` file. Otherwise, the outputted Go file would end up in a path like `github.com/techotron/labs/file.proto`

Without the `option go_package` keyword in the `.proto` file, when you run `protoc` against it, it'll still create the file but will output the following warning:

```bash
2020/08/01 21:59:52 WARNING: Missing 'go_package' option in "person.proto",
please specify it with the full Go package path as
a future release of protoc-gen-go will require this be specified.
See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.
```

[What the compiler is doing]: https://buf.build/docs/build-images "What the compiler is doing"
