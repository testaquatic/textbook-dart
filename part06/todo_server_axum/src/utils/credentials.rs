use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use jsonwebtoken::{EncodingKey, Header, encode};
use rand::distr::{Alphanumeric, SampleString};
use secrecy::{ExposeSecret, SecretString};

/// 비밀번호를 해싱하고 phc문자열로 변경한다.
pub fn password_to_phc_string(
    password: &SecretString,
) -> Result<SecretString, argon2::password_hash::Error> {
    let mut rng = rand::rng();
    let salt = Alphanumeric.sample_string(&mut rng, 32);
    let hash = Argon2::default()
        .hash_password_with_salt(password.expose_secret().as_bytes(), salt.as_bytes())?;

    Ok(hash.to_string().into())
}

/// 비밀번호를 확인한다.
pub fn verify_password(
    password: &SecretString,
    phc_string: &SecretString,
) -> Result<bool, argon2::password_hash::Error> {
    let password_hash = PasswordHash::new(phc_string.expose_secret())?;
    match Argon2::default().verify_password(password.expose_secret().as_bytes(), &password_hash) {
        Ok(_) => Ok(true),
        Err(argon2::password_hash::Error::PasswordInvalid) => Ok(false),
        Err(e) => Err(e),
    }
}

/// JWT
#[derive(serde::Serialize)]
pub struct JWT {
    /// 사용자 id
    sub: i64,
    email: String,
    /// 유닉스 타임스탬프(초)
    iat: i64,
}

impl JWT {
    pub fn new(sub: i64, email: &str) -> JWT {
        JWT {
            sub,
            email: email.to_string(),
            iat: chrono::Utc::now().timestamp(),
        }
    }

    pub fn token(
        &self,
        jwt_secret: &SecretString,
    ) -> Result<SecretString, jsonwebtoken::errors::Error> {
        encode(
            &Header::default(),
            self,
            &EncodingKey::from_secret(jwt_secret.expose_secret().as_bytes()),
        )
        .map(SecretString::from)
    }
}
