use axum::{routing::get, Router};

async fn base_handler() -> &'static str {
    "This is an HTTP benchmark"
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(base_handler));
    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
