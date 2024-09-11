package main

import (
	"net/http"
)

func baseHandler(w http.ResponseWriter, req *http.Request) {
    w.Write([]byte("This is an HTTP benchmark"))
}

func main() {
	http.HandleFunc("/", baseHandler)
	http.ListenAndServe("127.0.0.1:3000", nil)
}
