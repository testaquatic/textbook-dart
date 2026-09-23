use tokio::net::TcpListener;

use crate::router::get_app_router;

pub async fn run_app(listener: TcpListener) {
    let app_router = get_app_router();

    tracing::info!("Server starts listening on {:?}", listener.local_addr());
    axum::serve(listener, app_router)
        .await
        .expect("서버 실행 실패")
}
