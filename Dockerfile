FROM golang:1.16 AS builder
WORKDIR /go/src/step-by-step
COPY go.mod go.sum ./
RUN go mod download
COPY . .
WORKDIR /go/src/step-by-step/cmd
RUN go mod vendor
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /go/src/step-by-step/bin/service
RUN ls

FROM alpine:3.12.3
RUN adduser -D app-executor
USER app-executor
WORKDIR /app
COPY --from=builder /go/src/step-by-step/bin/service /app/service

ENV PORT 8000
EXPOSE $PORT

ENTRYPOINT ["/app/service"]