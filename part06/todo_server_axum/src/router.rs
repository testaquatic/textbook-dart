use axum::{Router, http, routing};
use tower_http::trace::TraceLayer;
use utoipa::{
    OpenApi,
    openapi::{self, Info, OpenApiBuilder, PathItem, PathsBuilder, path::Operation},
};
use utoipa_swagger_ui::SwaggerUi;

use crate::{
    handler::auth::{AuthOpenApi, register},
    state::AppState,
};

/// 앱에서 사용할 라우터를 생성한다.
pub fn get_app_router(app_state: AppState) -> Router {
    Router::new()
        .route("/auth/register", routing::post(register))
        .layer(TraceLayer::new_for_http())
        .with_state(app_state)
        .merge(get_open_api_router())
}

pub fn get_open_api_router() -> Router {
    let mut api = OpenApiBuilder::new().info(Info::builder().build()).build();

    api.merge(AuthOpenApi::openapi());

    SwaggerUi::new("/swagger-ui")
        .url("/api-docs/openapi.json", api)
        .into()
}
