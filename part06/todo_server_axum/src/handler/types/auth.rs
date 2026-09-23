use regex::Regex;
use secrecy::{ExposeSecret, SecretString};
use serde::Serializer;

use crate::{handler::types::error::AppError, repository::types::Sqlite3User};

/// 인증 관련 응답
#[derive(serde::Serialize)]
pub struct UserResponse {
    /// JWT 토큰
    #[serde(serialize_with = "serialize_secret_string")]
    pub token: SecretString,
    /// 사용자 정보
    pub user: UserInfo,
}

/// `SecretString`을 직렬화 하기 위한 함수
/// serde 지원을 하는 것 같은데 오류가 발생해서 직접 작성했다.
fn serialize_secret_string<S>(
    secret_string: &SecretString,
    serializer: S,
) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    serializer.serialize_str(secret_string.expose_secret())
}

/// 사용자 정보
#[derive(serde::Serialize)]
pub struct UserInfo {
    pub id: i64,
    pub email: String,
    pub created_at: String,
}

/// DB에서 반환된 정보를 응답에 사용하기 좋게 변환한다.
impl From<Sqlite3User> for UserInfo {
    fn from(user: Sqlite3User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            created_at: user.created_at,
        }
    }
}

/// 인증 관련 요청
#[derive(serde::Deserialize)]
pub struct AuthRequest {
    pub email: String,
    pub password: SecretString,
}
impl AuthRequest {
    pub fn check_input(&self) -> Result<(), AppError> {
        let regexp = Regex::new(r#"^[.\w-]+@([\w-]+\.)+[\w-]{2,}$"#)
            .map_err(|e| AppError::InternalServerError(e.into()))?;

        if self.email.trim().is_empty() {
            return Err(AppError::ValidationError("이메일이 필요합니다.".into()));
        }
        if !regexp.is_match(self.email.as_str()) {
            return Err(AppError::ValidationError(
                "올바른 이메일 형식이 아닙니다.".into(),
            ));
        }
        if self.password.expose_secret().is_empty() {
            return Err(AppError::ValidationError("패스워드가 필요합니다.".into()));
        }

        if self.password.expose_secret().len() < 8 {
            return Err(AppError::ValidationError(
                "패스워드는 8자리 이상이어야 합니다.".into(),
            ));
        }

        Ok(())
    }
}
