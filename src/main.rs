use tokio::net::TcpListener;
use zero2prod::serve;

use std::io;

#[tokio::main]
async fn main() -> io::Result<()> {
    let listener = TcpListener::bind("0.0.0.0:0").await.unwrap();
    serve(listener).await
}
