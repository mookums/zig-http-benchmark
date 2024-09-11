package main

import (
	"fmt"
	"net/http"
)

func hello(w http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(w, "This is an HTTP benchmark\n")
}

func main() {
	http.HandleFunc("/", hello)
	http.ListenAndServe("127.0.0.1:3000", nil)
}
