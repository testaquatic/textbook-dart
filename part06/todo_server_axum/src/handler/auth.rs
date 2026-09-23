use axum::Json;

use crate::handler::types::{
    AppError,
    auth::{AuthRequest, UserResponse},
};

#[tracing::instrument(name = "register", skip_all)]
pub async fn register(auth_request: Json<AuthRequest>) -> Result<Json<UserResponse>, AppError> {
    auth_request.check_input()?;

    Ok(Json(UserResponse {
        id: 1,
        email: "test@exmaple.com".to_string(),
        created_at: "2026-09-23T14:30:00+09:00".to_string(),
    }))
}
