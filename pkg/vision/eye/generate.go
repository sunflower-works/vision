package eye

//go:generate protoc -I . --go_out=. --go_opt=paths=source_relative frame.proto h264.proto

// Generation prerequisites:
//   - Install protoc (>=3.21) and ensure it's on PATH
//   - Install protoc-gen-go:
//       go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
// Regenerate with:
//       go generate ./pkg/vision/eye
