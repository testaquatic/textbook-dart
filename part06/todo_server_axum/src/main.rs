use todo_server_axum::{router::get_app_router, telemetry::init_telemetry};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() {
    init_telemetry();
    let app_router = get_app_router();
    let listener = TcpListener::bind("localhost:8080")
        .await
        .expect("TcpListener 바인드 실패");
    
    tracing::info!("Server starts listening on {:?}", listener.local_addr());
    axum::serve(listener, app_router)
        .await
        .expect("서버 실행 실패")
}
