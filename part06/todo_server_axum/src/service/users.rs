//! 별도의 구조체를 작성하지 않는다.
//! 복잡성만 늘리는 것 같다.
//! 의존 방향을 레포지토리 -> 서비스 -> 핸들러의 방향 대신에
//! 핸들러 -> 서비스 <- 레포지토리로 구성하는 것이 더 편한 것 같다.

use sqlx::SqlitePool;

use crate::{
    config::Configuration,
    handler::types::auth::{AuthRequest, UserResponse},
    repository::user_repostitory::{create_user, find_user_by_email},
    service::error::ServiceError,
    utils::credentials::{JWT, password_to_phc_string},
};

pub async fn register(
    config: &Configuration,
    pool: &SqlitePool,
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
    let mut tx = pool.begin().await?;
    let user = find_user_by_email(&mut *tx, &auth_request.email).await?;
    if user.is_some() {
        tx.rollback().await?;
        return Err(ServiceError::ValidationError(
            "이미 사용 중인 이메일입니다.".into(),
        ));
    }

    // 사용자의 이메일과 해시를 DB에 저장한다.
    let created_user = create_user(&mut *tx, &auth_request.email, &password_hash).await?;
    tx.commit().await?;

    // JWT를 발급한다.
    let email = auth_request.email.clone();
    let jwt_secret = config.jwt_secret.clone();
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
