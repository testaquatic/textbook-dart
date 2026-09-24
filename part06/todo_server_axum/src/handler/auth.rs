use axum::{
    Json,
    extract::State,
    http,
    response::{IntoResponse, Response},
};
use chrono::Utc;
use utoipa::OpenApi;

use crate::{
    handler::types::{
        auth::{AuthRequest, UserResponse},
        error::{AppError, ErrorResponse},
    },
    service,
    state::AppState,
};

#[utoipa::path(
    post,
    path = "/auth/register",
    description = "회원가입을 한다.",
    summary = "회원가입",
    request_body = AuthRequest,
    responses(
        (
            status = http::StatusCode::CREATED, description = "회원가입 성공",
            body = UserResponse,
            example = json!({
                "token": "[TOKEN]",
                "user": {
                    "id": "[ID]",
                    "email": "test@exmaple.com",
                    "created_at":Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, true)
                }
            })
        ),
        (
            status = http::StatusCode::UNPROCESSABLE_ENTITY,
            description = "잘못된 요청", body = ErrorResponse, 
            example= json!({
                "error": "올바른 이메일 형식이 아닙니다."})
        ),
        (
            status = http::StatusCode::INTERNAL_SERVER_ERROR,
            description="서버 오류", body = ErrorResponse,
            example= json!({
                "error": "내부 서버 오류."})
        )
    )
)]
#[tracing::instrument(name = "register", skip_all)]
pub async fn register(
    State(state): State<AppState>,
    auth_request: Json<AuthRequest>,
) -> Result<Response, AppError> {
    auth_request.check_input()?;

    let user_response = service::users::register(state, &auth_request).await?;

    Ok((http::StatusCode::CREATED, Json(user_response)).into_response())
}

#[utoipa::path(
    post,
    path = "/auth/login",
    description = "로그인을 한다.",
    summary = "로그인",
    request_body = AuthRequest,
    responses(
        (
            status = http::StatusCode::OK, description = "로그인 성공",
            body = UserResponse,
            example = json!({
                "token": "[TOKEN]",
                "user": {
                    "id": "[ID]",
                    "email": "test@exmaple.com",
                    "created_at":Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, true)
                }
            })
        ),
        (
            status = http::StatusCode::UNAUTHORIZED, description = "로그인 실패",
            body = ErrorResponse,
            example= json!({
                "error": "이메일 또는 비밀번호가 올바르지 않습니다."
              })
        ),
        (
            status = http::StatusCode::UNPROCESSABLE_ENTITY,
            description = "잘못된 요청", body = ErrorResponse, 
            example= json!({
                "error": "올바른 이메일 형식이 아닙니다."})
        ),
        (
            status = http::StatusCode::INTERNAL_SERVER_ERROR,
            description="서버 오류", body = ErrorResponse,
            example= json!({
                "error": "내부 서버 오류."})
        )
    )
)]
#[tracing::instrument(skip_all, name = "login")]
pub async fn login(
    State(state): State<AppState>,
    auth_request: Json<AuthRequest>,
) -> Result<Response, AppError> {
    auth_request.check_input()?;

    let response = service::users::login(state, &auth_request).await?;

    Ok(Json(response).into_response())
}

#[derive(OpenApi)]
#[openapi(
    tags((name = "auth", description = "인증 관련 API")),
    paths(register, login)
)]
pub struct AuthOpenApi;
