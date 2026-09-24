use axum::{extract::Request, middleware::Next, response::Response};
use sqlx::types::Json;

use crate::handler::types::{auth::AuthRequest, error::AppError};

pub async fn auth_middleware(
    auth_request: Json<AuthRequest>,
    request: Request,
    next: Next,
) -> Result<Response, AppError> {
    let response = next.run(request).await;
    Ok(response)
}
