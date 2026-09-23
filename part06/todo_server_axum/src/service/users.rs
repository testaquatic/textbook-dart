//! 별도의 구조체를 작성하지 않는다.
//! 복잡성만 늘리는 것 같다.
//! 의존 방향을 레포지토리 -> 서비스 -> 핸들러의 방향 대신에
//! 핸들러 -> 서비스 <- 레포지토리로 구성하는 것이 더 편한 것 같다.

use sqlx::SqlitePool;

use crate::{
    handler::types::auth::{AuthRequest, UserResponse},
    repository::user_repostitory::{create_user, find_user_by_email},
    service::error::ServiceError,
    utils::credentials::password_to_phc_string,
};

pub async fn register(
    pool: &SqlitePool,
    auth_request: &AuthRequest,
) -> Result<UserResponse, ServiceError> {
    let password = auth_request.password.clone();
    let password_hash = tokio::task::spawn_blocking(move || password_to_phc_string(&password))
        .await
        .map_err(|e| {
            tracing::error!(error.internal_server_error = ?e);
            ServiceError::InternalServerError(e.into())
        })?
        .map_err(|e| ServiceError::InternalServerError(e.into()))?;

    let user = find_user_by_email(pool, &auth_request.email).await?;

    if user.is_some() {
        return Err(ServiceError::ValidationError(
            "이미 사용 중인 이메일입니다.".into(),
        ));
    }

    let created_user = create_user(pool, &auth_request.email, &password_hash).await?;

    todo!()
}
