use argon2::{Argon2, Params, PasswordHash, PasswordHasher, PasswordVerifier};
use rand::distr::{Alphanumeric, SampleString};
use secrecy::{ExposeSecret, SecretString};

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

pub fn verify_password(
    password: &SecretString,
    phc_string: &SecretString,
) -> Result<bool, argon2::password_hash::Error> {
    let password_hash = PasswordHash::new(phc_string.expose_secret())?;
    Argon2::default()
        .verify_password(password.expose_secret().as_bytes(), &password_hash)
        .map(|_| true)
}
