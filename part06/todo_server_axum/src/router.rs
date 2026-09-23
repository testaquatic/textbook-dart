use axum::{Router, routing};
use tower_http::trace::TraceLayer;

use crate::{handler::auth::register, state::AppState};

pub fn get_app_router(app_state: AppState) -> Router {
    Router::new()
        .route("/auth/register", routing::post(register))
        .layer(TraceLayer::new_for_http())
        .with_state(app_state)
}
