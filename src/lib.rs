use axum::{http::StatusCode, routing::get, Router};
use tokio::net::TcpListener;

use std::io;

async fn health_check() -> StatusCode {
    StatusCode::OK
}

pub async fn serve(listener: TcpListener) -> io::Result<()> {
    let app = Router::new().route("/health_check", get(health_check));
    axum::serve(listener, app).await
}
