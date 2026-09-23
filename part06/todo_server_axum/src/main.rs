use secrecy::SecretString;
use sqlx::SqlitePool;
use todo_server_axum::{
    config::Configuration, startup::run_app, state::AppState, telemetry::init_telemetry,
};
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

    let pool = SqlitePool::connect(config.db_path.as_str())
        .await
        .expect("DB 연결 실패");

    let state = AppState::new(config, pool);

    let listener = TcpListener::bind(format!("localhost:{}", state.config.port))
        .await
        .expect("주소 바인딩 실패");

    run_app(listener, state).await;
}
