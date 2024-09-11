package main

import (
	"fmt"
	"log"

	"github.com/panjf2000/gnet/v2"
)

type httpServer struct {
	gnet.BuiltinEventEngine
	eng gnet.Engine
}

func (hs *httpServer) OnBoot(eng gnet.Engine) (action gnet.Action) {
	hs.eng = eng
	return
}

func (hs *httpServer) OnTraffic(c gnet.Conn) gnet.Action {
    response := "HTTP/1.1 200 OK\r\n" +
        "Content-Type: text/plain\r\n" +
        "Content-Length: 25\r\n" +
        "Connection: keep-alive\r\n" +
        "\r\n" +
        "This is an HTTP benchmark\n"
    c.Write([]byte(response))
	return gnet.None
}

func main() {
	port := 3000
	multicore := true
	server := &httpServer{}
	addr := fmt.Sprintf("tcp://127.0.0.1:%d", port)
	log.Fatal(gnet.Run(server, addr, gnet.WithMulticore(multicore)))
}

