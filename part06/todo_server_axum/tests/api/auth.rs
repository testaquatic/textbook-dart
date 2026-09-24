use crate::test_app::TestApp;
use insta::assert_json_snapshot;
use reqwest::StatusCode;
use serde_json::json;

#[tokio::test]
async fn return_422_if_submit_invalid_input() -> Result<(), anyhow::Error> {
    let test_app = TestApp::new().await?;
    let url = test_app.url("/auth/register");
    // 이메일 형식 오류
    let response = test_app
        .post(&url, json!({ "email": "adf", "password": "[PASSWORD]" }))
        .await?;
    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let json: serde_json::Value = response.json().await?;
    assert_eq!(
        json["error"].as_str().unwrap(),
        "올바른 이메일 형식이 아닙니다."
    );

    // 비어있는 필드
    let case = [
        (
            json!({ "email": "test@test.com" }),
            "패스워드가 필요합니다.",
        ),
        (json!({ "password": "[PASSWORD]" }), "이메일이 필요합니다."),
        (json!({}), "이메일이 필요합니다."),
    ];
    for (json, msg) in case {
        let response = test_app.post(&url, json).await?;
        println!("{:?}", response);
        assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let json: serde_json::Value = response.json().await?;
        assert_eq!(json["error"].as_str().unwrap(), msg);
    }

    // 짧은 비밀번호
    let response = test_app
        .post(
            &url,
            json!({ "email": "test@test.com", "password": "short" }),
        )
        .await?;
    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let json: serde_json::Value = response.json().await?;
    assert_eq!(
        json["error"].as_str().unwrap(),
        "패스워드는 8자리 이상이어야 합니다."
    );

    Ok(())
}

#[tokio::test]
async fn return_201_if_submit_valid_email_and_password() -> Result<(), anyhow::Error> {
    let test_app = TestApp::new().await?;
    let response = test_app
        .register_user("test@example.com", "password123")
        .await?;

    assert_eq!(response.status(), StatusCode::CREATED);
    let json: serde_json::Value = response.json().await?;
    assert_json_snapshot!(json, {
            ".token" => "[TOKEN]",
            ".user.created_at" => "[DATE]"
    });

    Ok(())
}

#[tokio::test]
async fn return_422_if_submit_an_already_registered_email() -> Result<(), anyhow::Error> {
    let test_app = TestApp::new().await?;
    test_app
        .register_user("exist@example.com", "password123")
        .await?;

    // 같은 이메일로 두번 가입 시도
    let response = test_app
        .register_user("exist@example.com", "password123")
        .await?;

    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let json: serde_json::Value = response.json().await?;
    assert_eq!(
        json["error"].as_str().unwrap(),
        "이미 사용 중인 이메일입니다."
    );

    Ok(())
}

#[tokio::test]
async fn return_200_if_login_with_valid_credentials() -> Result<(), anyhow::Error> {
    let test_app = TestApp::new().await?;
    test_app
        .register_user("valid@example.com", "password123")
        .await?;

    let response = test_app
        .post(
            &test_app.url("/auth/login"),
            serde_json::json!({ "email": "valid@example.com", "password": "password123" }),
        )
        .await?;

    assert_eq!(response.status(), StatusCode::OK);
    let json: serde_json::Value = response.json().await?;
    assert_json_snapshot!(json, {
            ".token" => "[TOKEN]",
            ".user.created_at" => "[DATE]"
    });

    Ok(())
}

#[tokio::test]
async fn return_401_if_login_with_invalid_credentials() -> Result<(), anyhow::Error> {
    let test_app = TestApp::new().await?;
    test_app
        .register_user("valid@example.com", "password123")
        .await?;

    // 잘못된 이메일
    let response = test_app.login("invalid@example.com", "password123").await?;
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    let json: serde_json::Value = response.json().await?;
    assert_eq!(
        json["error"].as_str().unwrap(),
        "이메일 또는 비밀번호가 올바르지 않습니다."
    );

    // 잘못된 패스워드
    let response = test_app
        .login("valid@example.com", "invalid_password")
        .await?;
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    let json: serde_json::Value = response.json().await?;
    assert_eq!(
        json["error"].as_str().unwrap(),
        "이메일 또는 비밀번호가 올바르지 않습니다."
    );

    Ok(())
}
