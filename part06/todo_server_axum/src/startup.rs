use std::sync::Arc;

use sqlx::SqlitePool;
use tokio::net::TcpListener;

use crate::{router::get_app_router, state::AppState};

pub async fn run_app(listener: TcpListener, app_state: AppState) {
    let app_router = get_app_router(app_state);

    tracing::info!("Server starts listening on {:?}", listener.local_addr());
    axum::serve(listener, app_router)
        .await
        .expect("서버 실행 실패")
}
