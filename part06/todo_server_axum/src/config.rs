use config::Config;
use secrecy::SecretString;

/// 설정
/// todo: 외부의 파일이나 환경변수로부터 읽도록 수정할 것
#[derive(Clone, serde::Deserialize)]
pub struct Configuration {
    pub jwt_secret: SecretString,
    pub db_path: String,
    pub bind_addr: String,
    pub port: u16,
}

/// 설정을 파일이나 환경변수로부터 읽는다.
/// 우선 순위는 환경변수, 파일 순서이다.
pub fn get_configuration() -> Result<Configuration, config::ConfigError> {
    let config_file_name = if cfg!(debug_assertions) {
        "debug.yaml"
    } else {
        "config.yaml"
    };

    Config::builder()
        .add_source(config::File::with_name("configuration/base.yaml"))
        .add_source(config::File::with_name(&format!(
            "configuration/{}",
            config_file_name
        )))
        .add_source(config::Environment::with_prefix("APP").separator("__"))
        .build()?
        .try_deserialize()
}
