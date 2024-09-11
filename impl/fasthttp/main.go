package main

import (
    "github.com/valyala/fasthttp"
)

func baseHandler(c *fasthttp.RequestCtx) { 
    c.WriteString("This is an HTTP benchmark")
}

func main() {
    fasthttp.ListenAndServe("127.0.0.1:3000", baseHandler)
}
