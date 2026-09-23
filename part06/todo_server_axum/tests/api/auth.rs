use crate::test_app::TestApp;
use insta::assert_json_snapshot;
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
    assert_json_snapshot!(json);
    Ok(())
}

#[tokio::test]
async fn successfully_register_user() -> Result<(), anyhow::Error> {
    let test_app = TestApp::new().await?;
    let response = test_app
        .post(
            &test_app.url("/auth/register"),
            serde_json::json!({
                "email": "test@example.com",
                "password": "password123",
            }),
        )
        .await?;

    assert_eq!(response.status(), StatusCode::CREATED);
    let json: serde_json::Value = response.json().await?;
    assert_json_snapshot!(json, {
            ".token" => "[TOKEN]",
            ".user.created_at" => "[DATE]"
    });

    Ok(())
}
