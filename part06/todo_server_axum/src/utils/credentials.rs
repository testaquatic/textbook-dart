use argon2::{Argon2, Params, PasswordHash, PasswordHasher, PasswordVerifier};
use jsonwebtoken::{EncodingKey, Header, encode};
use rand::distr::{Alphanumeric, SampleString};
use secrecy::{ExposeSecret, SecretString};

/// 비밀번호를 해싱하고 phc문자열로 변경한다.
pub fn password_to_phc_string(
    password: &SecretString,
) -> Result<SecretString, argon2::password_hash::Error> {
    let mut rng = rand::rng();
    let pepper = Alphanumeric.sample_string(&mut rng, 16);
    let argon2 = Argon2::new_with_secret(
        pepper.as_bytes(),
        argon2::Algorithm::default(),
        argon2::Version::default(),
        Params::default(),
    )?;

    let hash = argon2.hash_password(password.expose_secret().as_bytes())?;

    Ok(hash.to_string().into())
}

/// 비밀번호를 확인한다.
pub fn verify_password(
    password: &SecretString,
    phc_string: &SecretString,
) -> Result<bool, argon2::password_hash::Error> {
    let password_hash = PasswordHash::new(phc_string.expose_secret())?;
    Argon2::default()
        .verify_password(password.expose_secret().as_bytes(), &password_hash)
        .map(|_| true)
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
