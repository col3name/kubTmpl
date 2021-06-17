package handlers

import "net/http"

func Healthz(w http.ResponseWriter, _ *http.Request)  {
	w.WriteHeader(http.StatusOK)

}
