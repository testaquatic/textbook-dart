use secrecy::{ExposeSecret, SecretString};
use sqlx::SqlitePool;

use crate::repository::types::Sqlite3User;

pub struct Sqlite3UserRepository {
    pool: SqlitePool,
}

impl Sqlite3UserRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }

    /// 사용자를 DB에 저장한다.
    #[tracing::instrument(skip_all, fields(user.id = tracing::field::Empty))]
    pub async fn create(
        &self,
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
        .fetch_one(&self.pool)
        .await?;

        tracing::Span::current().record("user.id", user.id);

        Ok(user)
    }

    /// 사용자를 이메일로 찾는다
    #[tracing::instrument(skip_all, fields(user.email = %email))]
    pub async fn find_by_email(&self, email: &str) -> Result<Option<Sqlite3User>, sqlx::Error> {
        sqlx::query_as!(
            Sqlite3User,
            r#"
            SELECT id, email, password_hash, created_at FROM users WHERE email = ?
            "#,
            email,
        )
        .fetch_optional(&self.pool)
        .await
    }

    /// 유저를 id로 찾는다.
    #[tracing::instrument(skip_all, fields(user.id = %id))]
    pub async fn find_by_id(&self, id: i64) -> Result<Option<Sqlite3User>, sqlx::Error> {
        sqlx::query_as!(
            Sqlite3User,
            r#"
            SELECT id, email, password_hash, created_at FROM users WHERE id = ?
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await
    }
}

#[cfg(test)]
mod tests {
    use secrecy::{ExposeSecret, SecretString};

    use crate::repository::user_repostitory::Sqlite3UserRepository;

    async fn create_inmemory_user_repo() -> Result<Sqlite3UserRepository, anyhow::Error> {
        let pool = sqlx::SqlitePool::connect(":memory:").await?;
        sqlx::migrate!("./migrations").run(&pool).await?;
        Ok(Sqlite3UserRepository { pool })
    }

    #[tokio::test]
    async fn test_create() -> Result<(), anyhow::Error> {
        let user_repo = create_inmemory_user_repo().await?;
        let result = user_repo
            .create(
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
        let user_repo = create_inmemory_user_repo().await?;
        let user1 = user_repo
            .create("user1@example.com", &SecretString::new("pass".into()))
            .await?;
        user_repo
            .create("user2@example.com", &SecretString::new("pass2".into()))
            .await?;

        let result = user_repo.find_by_email(&user1.email).await?;

        assert!(result.is_some());
        assert_eq!(result.unwrap().email, user1.email);

        Ok(())
    }

    #[tokio::test]
    async fn test_find_by_id() -> Result<(), anyhow::Error> {
        let user_repo = create_inmemory_user_repo().await?;
        let user1 = user_repo
            .create("user1@example.com", &SecretString::new("pass".into()))
            .await?;
        user_repo
            .create("user2@example.com", &SecretString::new("pass2".into()))
            .await?;

        let result = user_repo.find_by_id(user1.id).await?;

        assert!(result.is_some());
        assert_eq!(result.unwrap().email, "user1@example.com");

        Ok(())
    }
}
