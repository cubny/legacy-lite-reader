GOBIN = $(GOPATH)/bin

help:
	@echo "Please use 'make <target>' where <target> is one of the following:"

	@echo "  docker-run         to run the app with Docker (docker-compose)."
	@echo "  run                to run the app without Docker (go run)."
	@echo "  build              to build the app without Docker (go build)."

	@echo "  pre-commit         to run essential checks before you would make a commit."
	@echo "  dev-dependencies   to install all required Go dev dependencies"
	@echo "  gomod              to run tidy you go.mod file and load vendor files."
	@echo "  update-mocks       to update mocks."
	@echo "  gci                to apply gci."

	@echo "  lint               to perform linting."

	@echo "  test               run all unit tests."
	@echo "  coverage-report    open coverage report generated by make test."

dev-dependencies: | $(GOBIN)/mockgen $(GOBIN)/gci $(GOBIN)/golangci-lint

.PHONY: run
run:
	CGO_ENABLED=0 GOOS=linux go run -mod=vendor ./cmd/main.go

.PHONY: docker-run
docker-run:
	docker-compose -f docker-compose.yaml build
	docker-compose -f docker-compose.yaml up

.PHONY: build
build:
	CGO_ENABLED=0 GOOS=linux go build -mod=vendor -a -installsuffix cgo -o lite-reader ./cmd/main.go

pre-commit: gomod update-mocks lint test


.PHONY: gomod
gomod:
	@go mod tidy
	@go mod vendor

$(GOBIN)/mockgen:
	@go install github.com/golang/mock/mockgen@v1.6.0
	@$(MAKE) gomod

update-mocks: | $(GOBIN)/mockgen
	@find ./internal/mocks ! -name 'definition.go' -type f -exec rm {} +
	GO111MODULE=on go generate -mod=vendor -tags=mocks ./...
	@$(MAKE) gci

.PHONY: test
test:
	@mkdir -p reports
	@go test -coverprofile=reports/codecoverage_all.cov ./... -mod=vendor -cover -race -p=4
	@go tool cover -func=reports/codecoverage_all.cov > reports/functioncoverage.out
	@go tool cover -html=reports/codecoverage_all.cov -o reports/coverage.html
	@echo "View report at $(PWD)/reports/coverage.html"
	@tail -n 1 reports/functioncoverage.out

.PHONY: coverage-report
coverage-report:
	@open reports/coverage.html

$(GOBIN)/gci:
	@go install github.com/daixiang0/gci@v0.3.3
	@$(MAKE) gomod

gci: | $(GOBIN)/gci
	@gci write --Section Standard --Section Default --Section "Prefix(github.com/cubny/lite-reader)"  $(shell ls  -d $(PWD)/*/ | grep -v vendor)

$(GOBIN)/golangci-lint:
	@curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin v1.45.0

.PHONY: lint
lint: | $(GOBIN)/golangci-lint
	golangci-lint run -v

.PHONY: ci-run
ci-run:
	docker-compose build
	docker-compose up

.PHONY: docs
docs:
	docker run -v $(CURDIR):/local -w /local  quay.io/goswagger/swagger generate spec -o ./docs/swagger.json
	docker run -v $(CURDIR):/local -w /local  quay.io/goswagger/swagger generate spec -o ./docs/swagger.yaml
