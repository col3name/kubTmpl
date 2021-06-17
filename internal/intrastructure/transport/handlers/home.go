package handlers

import (
	"fmt"
	"net/http"
)

func Home() func(http.ResponseWriter, *http.Request) {
	return func(writer http.ResponseWriter, request *http.Request) {
		fmt.Fprint(writer, "Hello! Your request was processed.")
	}
}