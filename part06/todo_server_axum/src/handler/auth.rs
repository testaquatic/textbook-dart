use axum::{
    Json,
    extract::State,
    http,
    response::{IntoResponse, Response},
};

use crate::{
    handler::types::{auth::AuthRequest, error::AppError},
    service,
    state::AppState,
};

/// todo: 자세한 주석을 작성할 것
#[tracing::instrument(name = "register", skip_all)]
pub async fn register(
    State(state): State<AppState>,
    auth_request: Json<AuthRequest>,
) -> Result<Response, AppError> {
    auth_request.check_input()?;

    let user_response =
        service::users::register(&state.config, &state.db_pool, &auth_request).await?;

    Ok((http::StatusCode::CREATED, Json(user_response)).into_response())
}
