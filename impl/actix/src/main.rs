use actix_web::{web, App, HttpServer, Responder};

async fn base_handler() -> impl Responder {
    "This is an HTTP benchmark"
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| App::new().route("/", web::get().to(base_handler)))
        .bind("127.0.0.1:3000")?
        .run()
        .await
}

