use sqlx::SqlitePool;
use todo_server_axum::{
    config::get_configuration, startup::run_app, state::AppState, telemetry::init_telemetry,
};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() {
    // 로깅 초기화
    init_telemetry();

    // 설정을 불러온다.
    let config = get_configuration().expect("설정 불러오기 실패");

    // DB 풀을 생성한다.
    let pool = SqlitePool::connect(config.db_path.as_str())
        .await
        .expect("DB 연결 실패");

    // 상태를 생성한다.
    let state = AppState::new(config, pool);

    // 리스너를 생성한다.
    let listener = TcpListener::bind(format!("{}:{}", state.config.bind_addr, state.config.port))
        .await
        .expect("주소 바인딩 실패");

    // 서버를 실행한다.
    run_app(listener, state).await;
}
