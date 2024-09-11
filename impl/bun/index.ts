Bun.serve({
    hostname: "127.0.0.1",
    port: 3000,
    fetch(req) {
        return new Response("This is an HTTP benchmark")
    },
})
