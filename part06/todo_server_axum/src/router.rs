use axum::{Router, routing};
use tower_http::trace::TraceLayer;

use crate::handler::users::register;

pub fn get_app_router() -> Router {
    Router::new()
        .route("/auth/register", routing::get(register))
        .layer(TraceLayer::new_for_http())
}
