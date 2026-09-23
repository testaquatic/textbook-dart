use secrecy::{ExposeSecret, SecretString};
use sqlx::SqliteExecutor;

use crate::repository::types::Sqlite3User;

/// 사용자를 DB에 저장한다.
#[tracing::instrument(skip_all, fields(user.id = tracing::field::Empty))]
pub async fn create_user(
    executor: impl SqliteExecutor<'_>,
    email: &str,
    password_hash: &SecretString,
) -> Result<Sqlite3User, sqlx::Error> {
    let user = sqlx::query_as!(
        Sqlite3User,
        r#"
            INSERT INTO users (email, password_hash)
            VALUES (?, ?)
            RETURNING id, email, password_hash, created_at;
            "#,
        email,
        password_hash.expose_secret(),
    )
    .fetch_one(executor)
    .await?;

    tracing::Span::current().record("user.id", user.id);

    Ok(user)
}

/// 사용자를 이메일로 찾는다
#[tracing::instrument(skip_all, fields(user.email = %email))]
pub async fn find_user_by_email(
    executor: impl SqliteExecutor<'_>,
    email: &str,
) -> Result<Option<Sqlite3User>, sqlx::Error> {
    sqlx::query_as!(
        Sqlite3User,
        r#"
            SELECT id, email, password_hash, created_at FROM users WHERE email = ?
            "#,
        email,
    )
    .fetch_optional(executor)
    .await
}

/// 유저를 id로 찾는다.
#[tracing::instrument(skip_all, fields(user.id = %id))]
pub async fn find_user_by_id(
    executor: impl SqliteExecutor<'_>,
    id: i64,
) -> Result<Option<Sqlite3User>, sqlx::Error> {
    sqlx::query_as!(
        Sqlite3User,
        r#"
            SELECT id, email, password_hash, created_at FROM users WHERE id = ?
            "#,
        id
    )
    .fetch_optional(executor)
    .await
}

#[cfg(test)]
mod tests {
    use secrecy::{ExposeSecret, SecretString};
    use sqlx::SqlitePool;

    use crate::repository::user_repostitory::{create_user, find_user_by_email, find_user_by_id};

    async fn create_inmemory_db() -> Result<SqlitePool, anyhow::Error> {
        let pool = sqlx::SqlitePool::connect(":memory:").await?;
        sqlx::migrate!("./migrations").run(&pool).await?;
        Ok(pool)
    }

    #[tokio::test]
    async fn test_create() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_db().await?;
        let result = create_user(
            &pool,
            "test@example.com",
            &SecretString::new("password_hash".into()),
        )
        .await?;

        assert_eq!(result.email, "test@example.com");
        assert_eq!(result.password_hash.expose_secret(), "password_hash");
        Ok(())
    }

    #[tokio::test]
    async fn test_find_by_email() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_db().await?;
        let user1 = create_user(
            &pool,
            "user1@example.com",
            &SecretString::new("pass".into()),
        )
        .await?;
        create_user(
            &pool,
            "user2@example.com",
            &SecretString::new("pass2".into()),
        )
        .await?;

        let result = find_user_by_email(&pool, &user1.email).await?;

        assert!(result.is_some());
        assert_eq!(result.unwrap().email, user1.email);

        Ok(())
    }

    #[tokio::test]
    async fn test_find_by_id() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_db().await?;
        let user1 = create_user(
            &pool,
            "user1@example.com",
            &SecretString::new("pass".into()),
        )
        .await?;
        create_user(
            &pool,
            "user2@example.com",
            &SecretString::new("pass2".into()),
        )
        .await?;

        let result = find_user_by_id(&pool, user1.id).await?;

        assert!(result.is_some());
        assert_eq!(result.unwrap().email, "user1@example.com");

        Ok(())
    }
}
