APP?=service
ifeq ($(OS),Windows_NT)
	APP=service.exe
endif

GOOS?=linux
GOARCH?=amd64
PORT?=8000
RELEASE?=0.0.1
COMMIT?=$(shell git rev-parse --short HEAD)
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
CONTAINER_IMAGE?=docker.io/mikhailmi/${APP}

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	del ${APP} 2> temporary-del-workaround.txt
else
	rm -f ${APP}
endif

ifeq ($(OS),Windows_NT)
.PHONY: build
build:
	go build -o ${APP} cmd/main.go
else
.PHONY: build
build: clean
	go build -o ${APP} cmd/main.go
endif

.PHONY: docker-build
minidocker-build:
	docker build -t ${CONTAINER_IMAGE}:${RELEASE} .

.PHONY: docker-run
docker-run: docker-build
	docker stop $(APP):$(RELEASE) || true && docker rm $(APP):$(RELEASE) || true
	docker run --name ${APP} -p ${PORT}:${PORT} --rm \
		-e "PORT=${PORT}" \
		$(APP):$(RELEASE)

.PHONY: docker-push
docker-push: docker-build
	docker push ${CONTAINER_IMAGE}:${RELEASE}

.PHONY: minikube
minikube: docker-push minikube-apply minikube-verify

.PHONY: minikube-apply
minikube-apply:
	kubectl apply -f ./kubernetes/service/deployment.yaml
	kubectl apply -f ./kubernetes/service/service.yaml
	kubectl apply -f ./kubernetes/service/ingress.yaml

.PHONY: minikube-verify
minikube-verify:
	kubectl get deployment
	kubectl get service
	kubectl get ingress

.PHONY: run
run: build
ifeq ($(OS),Windows_NT)
	${APP}
else
	PORT=${PORT} ./${APP}
endif

.PHONY: prepare
prepare:
	for t in $(shell find ./kubernetes/service -type f -name "*.yaml"); do \
        cat $$t | \
            sed -E "s/\{\{(\s*)\.Release(\s*)\}\}/$(RELEASE)/g" | \
            sed -E "s/\{\{(\s*)\.ServiceName(\s*)\}\}/$(APP)/g"; \
        echo ---; \
    done > tmp.yaml


.PHONY: stop
stop:
	taskkill /F /IM ${APP}

.PHONY: test
test:
	go test -v -race ./...