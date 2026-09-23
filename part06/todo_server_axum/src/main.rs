use secrecy::SecretString;
use todo_server_axum::{config::Configuration, startup::run_app, telemetry::init_telemetry};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() {
    init_telemetry();

    // 임시로 하드코딩 했다.
    let config = Configuration {
        port: 8080,
        db_path: "todo.db".to_string(),
        jwt_secret: SecretString::new("todo-secret-key".into()),
    };

    let listener = TcpListener::bind(format!("localhost:{}", config.port))
        .await
        .expect("주소 바인딩 실패");

    run_app(listener).await;
}
