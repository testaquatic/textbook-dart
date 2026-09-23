use axum::{Json, http, response::IntoResponse};

pub mod auth;
pub mod todos;

#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("내부 서버 오류")]
    InternalServerError(anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        let (status_code, json) = match &self {
            AppError::ValidationError(msg) => {
                tracing::info!("Validation error: {}", msg);

                let error_response = ErrorResponse {
                    error: msg.clone(),
                    code: None,
                };

                (http::StatusCode::UNPROCESSABLE_ENTITY, Json(error_response))
            }
            AppError::InternalServerError(e) => {
                tracing::error!("Internal server error: {}", e);

                let error_response = ErrorResponse {
                    error: "내부 서버 오류".to_string(),
                    code: None,
                };

                (
                    http::StatusCode::INTERNAL_SERVER_ERROR,
                    Json(error_response),
                )
            }
        };

        (status_code, json).into_response()
    }
}

#[derive(serde::Serialize)]
pub struct ErrorResponse {
    error: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    code: Option<String>,
}
