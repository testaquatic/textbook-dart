use secrecy::SecretString;

/// 설정
/// todo: 외부의 파일이나 환경변수로부터 읽도록 수정할 것
#[derive(Clone)]
pub struct Configuration {
    pub jwt_secret: SecretString,
    pub db_path: String,
    pub port: u16,
}
