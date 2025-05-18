use reqwest::{self, StatusCode};
use tokio::net::TcpListener;
use zero2prod::serve;

#[tokio::test]
async fn health_check() {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(serve(listener));
    let addr = format!("http://{}/health_check", addr);
    let resp = reqwest::get(addr).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    assert_eq!(resp.content_length(), Some(0));
}
