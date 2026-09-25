run:
	@air --build.cmd "go build -o ./tmp/main ./cmd/onlinepay" --build.bin "./tmp/main"

build:
	go build -o ./bin/onlinepay ./cmd/onlinepay
	go build -o ./bin/onlinepay-cli ./cmd/onlinepay-cli

fmt:
	gofmt -w .

vet:
	go vet ./...
