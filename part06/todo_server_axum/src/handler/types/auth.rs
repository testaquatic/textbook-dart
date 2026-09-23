use regex::Regex;
use secrecy::{ExposeSecret, SecretString};
use serde::Serializer;

use crate::{handler::types::AppError, repository::types::Sqlite3User};

#[derive(serde::Serialize)]
pub struct UserResponse {
    #[serde(serialize_with = "serialize_secret_string")]
    pub token: SecretString,
    pub user: UserInfo,
}

fn serialize_secret_string<S>(
    secret_string: &SecretString,
    serializer: S,
) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    serializer.serialize_str(secret_string.expose_secret())
}

#[derive(serde::Serialize)]
pub struct UserInfo {
    pub id: i64,
    pub email: String,
    pub created_at: String,
}

impl From<Sqlite3User> for UserInfo {
    fn from(user: Sqlite3User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            created_at: user.created_at,
        }
    }
}

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
