use std::time::Duration;

use axum::{Router, http, middleware, routing};
use tower_http::{
    compression::CompressionLayer,
    cors::{AllowOrigin, CorsLayer},
    timeout::TimeoutLayer,
    trace::TraceLayer,
};
use utoipa::{
    OpenApi,
    openapi::{Info, OpenApiBuilder},
};
use utoipa_swagger_ui::SwaggerUi;

use crate::{
    handler::{self, auth::AuthOpenApi},
    middleware::request_id_middleware::request_id_middleware,
    state::AppState,
};

/// 앱에서 사용할 라우터를 생성한다.
pub fn get_app_router(app_state: AppState) -> Router {
    let cors = CorsLayer::new()
        .allow_methods([
            http::Method::GET,
            http::Method::POST,
            http::Method::PUT,
            http::Method::DELETE,
            http::Method::OPTIONS,
        ])
        .allow_origin(AllowOrigin::any())
        .allow_headers([http::header::CONTENT_TYPE, http::header::AUTHORIZATION])
        .max_age(Duration::from_hours(24));

    Router::new()
        .route("/auth/register", routing::post(handler::auth::register))
        .route("/auth/login", routing::post(handler::auth::login))
        .with_state(app_state)
        .merge(get_open_api_router())
        .layer(CompressionLayer::new())
        .layer(cors)
        .layer(TimeoutLayer::with_status_code(
            http::StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(30),
        ))
        .layer(TraceLayer::new_for_http())
        .layer(middleware::from_fn(request_id_middleware))
}

pub fn get_open_api_router() -> Router {
    let mut api = OpenApiBuilder::new().info(Info::builder().build()).build();

    api.merge(AuthOpenApi::openapi());

    SwaggerUi::new("/swagger-ui")
        .url("/api-docs/openapi.json", api)
        .into()
}
