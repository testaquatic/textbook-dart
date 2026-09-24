use reqwest::Response;
use sqlx::SqlitePool;
use todo_server_axum::{
    config::{Configuration, get_configuration},
    startup::run_app,
    state::AppState,
    telemetry::init_telemetry,
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
        let mut config = get_configuration()?;
        config.port = 0;
        config.db_path = ":memory:".to_string();

        let listener = TcpListener::bind(format!("{}:{}", config.bind_addr, config.port)).await?;
        config.port = listener.local_addr()?.port();

        let pool = SqlitePool::connect(config.db_path.as_str())
            .await
            .expect("DB 연결 실패");

        sqlx::migrate!("./migrations").run(&pool).await?;

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

    pub async fn register_user(
        &self,
        email: &str,
        password: &str,
    ) -> Result<Response, anyhow::Error> {
        let response = self
            .post(
                &self.url("/auth/register"),
                serde_json::json!({
                    "email": email,
                    "password": password,
                }),
            )
            .await?;

        Ok(response)
    }

    pub async fn login(&self, email: &str, password: &str) -> Result<Response, anyhow::Error> {
        let response = self
            .post(
                &self.url("/auth/login"),
                serde_json::json!({"email": email, "password": password}),
            )
            .await?;

        Ok(response)
    }
}
