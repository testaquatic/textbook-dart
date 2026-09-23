use crate::test_app::TestApp;
use reqwest::StatusCode;
use serde_json::json;

#[tokio::test]
async fn returns_an_error_response_for_invalid_input() -> Result<(), anyhow::Error> {
    let test_app = TestApp::new().await?;
    let url = test_app.url("/auth/register");
    let response = test_app
        .post(&url, json!({ "email": "adf", "password": "[PASSWORD]" }))
        .await?;
    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let json: serde_json::Value = response.json().await?;
    assert!(
        json["error"]
            .to_string()
            .contains("올바른 이메일 형식이 아닙니다.")
    );
    Ok(())
}
