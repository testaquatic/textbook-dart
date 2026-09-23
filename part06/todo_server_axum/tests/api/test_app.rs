use reqwest::Response;
use secrecy::SecretString;
use sqlx::SqlitePool;
use todo_server_axum::{
    config::Configuration, startup::run_app, state::AppState, telemetry::init_telemetry,
};
use tokio::{net::TcpListener, task::JoinHandle};

pub struct TestApp {
    config: Configuration,
    _server_handle: JoinHandle<()>,
    reqwest_client: reqwest::Client,
}

impl TestApp {
    pub async fn new() -> Result<Self, anyhow::Error> {
        init_telemetry();

        // 임시로 하드코딩 했다.
        let mut config = Configuration {
            port: 0,
            db_path: "todo.db".to_string(),
            jwt_secret: SecretString::new("todo-secret-key".into()),
        };

        let listener = TcpListener::bind("localhost:0").await?;
        config.port = listener.local_addr()?.port();

        let pool = SqlitePool::connect(config.db_path.as_str())
            .await
            .expect("DB 연결 실패");

        let state = AppState::new(config.clone(), pool);

        let reqwest_client = reqwest::Client::new();

        let server_handle = tokio::spawn(async { run_app(listener, state).await });

        Ok(Self {
            _server_handle: server_handle,
            reqwest_client,
            config,
        })
    }

    pub fn url(&self, uri: &str) -> String {
        format!("http://localhost:{}{}", self.config.port, uri)
    }

    pub async fn post(
        &self,
        url: &str,
        json: serde_json::Value,
    ) -> Result<Response, reqwest::Error> {
        self.reqwest_client.post(url).json(&json).send().await
    }
}
