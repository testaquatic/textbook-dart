use secrecy::SecretString;

pub struct Configuration {
    pub jwt_secret: SecretString,
    pub db_path: String,
    pub port: u16,
}
