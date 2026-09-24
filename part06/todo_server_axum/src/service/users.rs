//! 별도의 구조체를 작성하지 않는다.
//! 복잡성만 늘리는 것 같다.
//! 의존 방향을 레포지토리 -> 서비스 -> 핸들러의 방향 대신에
//! 레포지토리 -> (핸들러 + 서비스)  구성하는 것이 더 편한 것 같다.

use crate::{
    handler::types::auth::{AuthRequest, UserResponse},
    repository::user_repostitory::{self},
    service::error::ServiceError,
    state::AppState,
    utils::credentials::{JWT, password_to_phc_string, verify_password},
};

/// 사용자를 DB에 등록하는 가교 역할을 하는 함수
pub async fn register(
    app_state: AppState,
    auth_request: &AuthRequest,
) -> Result<UserResponse, ServiceError> {
    // 해시를 생성한다.
    let password = auth_request.password.clone();
    let password_hash = tokio::task::spawn_blocking(move || password_to_phc_string(&password))
        .await
        .map_err(|e| {
            tracing::error!(error.internal_server_error = ?e);
            ServiceError::InternalServerError(e.into())
        })?
        .map_err(|e| ServiceError::InternalServerError(e.into()))?;

    // 이미 존재하는 이메일인지 확인한다.
    let mut tx = app_state.db_pool.begin().await?;
    let user = user_repostitory::find_user_by_email(&mut *tx, &auth_request.email).await?;
    if user.is_some() {
        tracing::warn!(
            error.auth = "이미 사용중인 이메일을 사용 시도",
            auth_request.email = %auth_request.email
        );
        tx.rollback().await?;
        return Err(ServiceError::ValidationError(
            "이미 사용 중인 이메일입니다.".into(),
        ));
    }

    // 사용자의 이메일과 해시를 DB에 저장한다.
    let created_user =
        user_repostitory::create_user(&mut *tx, &auth_request.email, &password_hash).await?;
    tx.commit().await?;

    // JWT를 발급한다.
    let email = auth_request.email.clone();
    let jwt_secret = app_state.config.jwt_secret.clone();
    let token = tokio::task::spawn_blocking(move || {
        JWT::new(created_user.id, &email)
            .token(&jwt_secret)
            .map_err(|e| ServiceError::InternalServerError(e.into()))
    })
    .await
    .map_err(|e| ServiceError::InternalServerError(e.into()))??;

    Ok(UserResponse {
        token,
        user: created_user.into(),
    })
}

pub async fn login(
    app_state: AppState,
    auth_request: &AuthRequest,
) -> Result<UserResponse, ServiceError> {
    // 사용자의 정보를 가져온다.
    let user =
        user_repostitory::find_user_by_email(&app_state.db_pool, &auth_request.email).await?;
    let Some(user) = user else {
        tracing::info!(
            error.auth = "존재하지 않은 이메일로 로그인 시도.",
            auth_request.email = %auth_request.email
        );
        return Err(ServiceError::UnauthorizedError(
            "이메일 또는 비밀번호가 올바르지 않습니다.".into(),
        ));
    };

    // 비밀번호가 맞는지 확인한다.
    let password = auth_request.password.clone();
    let password_hash = user.password_hash.clone();
    let is_valid = tokio::task::spawn_blocking(move || verify_password(&password, &password_hash))
        .await
        .map_err(|e| ServiceError::InternalServerError(e.into()))?
        .map_err(|e| ServiceError::InternalServerError(e.into()))?;
    if !is_valid {
        tracing::warn!(
            error.auth = "잘못된 비밀번호로 로그인 시도.",
            auth_request.email = %auth_request.email
        );
        return Err(ServiceError::UnauthorizedError(
            "이메일 또는 비밀번호가 올바르지 않습니다.".into(),
        ));
    }

    // JWT를 발급한다.
    let email = user.email.clone();
    let token = tokio::task::spawn_blocking(move || {
        JWT::new(user.id, &email).token(&app_state.config.jwt_secret)
    })
    .await
    .map_err(|e| ServiceError::InternalServerError(e.into()))?
    .map_err(|e| ServiceError::InternalServerError(e.into()))?;

    Ok(UserResponse {
        token,
        user: user.into(),
    })
}
