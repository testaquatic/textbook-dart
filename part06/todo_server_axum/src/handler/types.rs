use axum::{Json, response::IntoResponse};

use crate::model::todo::User;

#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("Validation error: {0}")]
    ValidationError(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        match &self {
            AppError::ValidationError(msg) => {
                let error_response = ErrorResponse {
                    error: msg.clone(),
                    code: None,
                };

                tracing::info!("Validation error: {}", msg);

                Json(error_response).into_response()
            }
        }
    }
}

#[derive(serde::Serialize)]
pub struct ErrorResponse {
    error: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    code: Option<String>,
}

#[derive(serde::Deserialize)]
pub struct CreateTodoRequeest {
    pub title: String,
}

#[derive(serde::Serialize)]
pub struct UserResponse {
    pub id: i64,
    pub email: String,
    pub created_at: String,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            created_at: user.created_at.to_rfc3339(),
        }
    }
}
