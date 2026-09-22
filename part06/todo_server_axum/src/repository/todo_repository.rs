use crate::model::todo::Sqlite3Todo;

pub struct Sqlite3TodoRepository {
    pub pool: sqlx::Pool<sqlx::Sqlite>,
}

impl Sqlite3TodoRepository {
    pub fn new(pool: sqlx::Pool<sqlx::Sqlite>) -> Self {
        Self { pool }
    }

    /// 사용자의 모든 할 일을 조회한다.
    pub async fn find_by_user_id(
        &self,
        user_id: i64,
        completed: Option<bool>,
        limit: Option<i64>,
        offset: Option<i64>,
    ) -> Result<Vec<Sqlite3Todo>, sqlx::Error> {
        let limit = limit.unwrap_or(20);
        let offset = offset.unwrap_or(0);

        if completed.is_some() {
            sqlx::query_as!(
                Sqlite3Todo,
                r#"
                SELECT * FROM todos WHERE user_id = ? AND completed = ? 
                ORDER BY created_at DESC LIMIT ? OFFSET ?
                "#,
                user_id,
                completed.expect("None체크 완료했음") as i32,
                limit,
                offset
            )
            .fetch_all(&self.pool)
            .await
        } else {
            sqlx::query_as!(
                Sqlite3Todo,
                r#"
                SELECT * FROM todos WHERE user_id = ? 
                ORDER BY created_at DESC LIMIT ? OFFSET ?
                "#,
                user_id,
                limit,
                offset
            )
            .fetch_all(&self.pool)
            .await
        }
    }

    /// 특정 할 일을 ID로 조회한다.
    pub async fn find_by_id(&self, id: i64) -> Result<Option<Sqlite3Todo>, sqlx::Error> {
        sqlx::query_as!(
            Sqlite3Todo,
            r#"
            SELECT * FROM todos WHERE id = ?
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await
    }

    /// 새로운 할 일을 생성한다.
    pub async fn create(&self, user_id: i64, title: &str) -> Result<Sqlite3Todo, sqlx::Error> {
        let row = sqlx::query!(
            r#"
            INSERT INTO todos (title, user_id)
            VALUES (?, ?)
            RETURNING id, title, completed, user_id, created_at, updated_at;
            "#,
            title,
            user_id,
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(Sqlite3Todo {
            id: row
                .id
                .ok_or_else(|| sqlx::error::Error::ColumnNotFound("id".into()))?,
            title: row.title,
            completed: row.completed,
            user_id: row.user_id,
            created_at: row.created_at,
            updated_at: row.updated_at,
        })
    }

    /// 할 일을 수정한다.
    pub async fn update(
        &self,
        id: i64,
        title: Option<&str>,
        completed: Option<bool>,
    ) -> Result<Sqlite3Todo, sqlx::Error> {
        let row = sqlx::query!(
            r#"
            WITH todo AS (
            SELECT title, completed FROM todos WHERE id = ?
            )
            UPDATE todos SET title = COALESCE(?, todo.title), completed = COALESCE(?, todo.completed), updated_at = datetime('now')
            FROM todo WHERE id = ?
            RETURNING id, title, completed, user_id, created_at, updated_at;
            "#,
            id,
            title,
            completed.map(|i| i as i64),
            id
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(Sqlite3Todo {
            id: row
                .id
                .ok_or_else(|| sqlx::error::Error::ColumnNotFound("id".into()))?,
            title: row.title,
            completed: row.completed,
            user_id: row.user_id,
            created_at: row.created_at,
            updated_at: row.updated_at,
        })
    }

    /// 할 일을 삭제한다.
    pub async fn delete(&self, id: i64) -> Result<Sqlite3Todo, sqlx::Error> {
        sqlx::query_as!(
            Sqlite3Todo,
            r#"
            DELETE FROM todos WHERE id = ? RETURNING id, title, completed, user_id, created_at, updated_at;
            "#,
            id
        ).fetch_one(&self.pool)
        .await
    }
}

#[cfg(test)]
mod tests {

    use crate::repository::todo_repository::Sqlite3TodoRepository;

    async fn create_inmemory_todo_repo() -> Result<Sqlite3TodoRepository, anyhow::Error> {
        let pool = sqlx::SqlitePool::connect(":memory:").await?;
        sqlx::migrate!("./migrations").run(&pool).await?;
        sqlx::query!(
            "INSERT INTO users (email, password_hash) VALUES (?, ?)",
            "test@example.com",
            "password"
        )
        .execute(&pool)
        .await?;

        Ok(Sqlite3TodoRepository { pool })
    }

    #[tokio::test]
    async fn test_create() -> Result<(), anyhow::Error> {
        let todo_repo = create_inmemory_todo_repo().await?;

        let todo = todo_repo.create(1, "Test Todo").await?;

        assert_eq!(todo.title, "Test Todo");
        assert_eq!(todo.user_id, 1);
        assert_eq!(todo.completed, 0);

        Ok(())
    }

    #[tokio::test]
    async fn test_find_by_user_id() -> Result<(), anyhow::Error> {
        let todo_repo = create_inmemory_todo_repo().await?;

        todo_repo.create(1, "Test Todo 1").await?;
        todo_repo.create(1, "Test Todo 2").await?;

        let todos = todo_repo.find_by_user_id(1, None, None, None).await?;

        assert_eq!(todos.len(), 2);

        Ok(())
    }

    #[tokio::test]
    async fn test_find_by_id() -> Result<(), anyhow::Error> {
        let todo_repo = create_inmemory_todo_repo().await?;

        let todo = todo_repo.create(1, "Test Todo").await?;

        let todo = todo_repo.find_by_id(todo.id).await?;

        assert!(todo.is_some());

        Ok(())
    }

    #[tokio::test]
    async fn test_update() -> Result<(), anyhow::Error> {
        let todo_repo = create_inmemory_todo_repo().await?;

        let todo = todo_repo.create(1, "Test Todo").await?;

        let todo = todo_repo
            .update(todo.id, Some("Test Todo Updated"), Some(true))
            .await?;

        assert_eq!(todo.title, "Test Todo Updated");
        assert_eq!(todo.completed, 1);

        Ok(())
    }

    #[tokio::test]
    async fn test_delete() -> Result<(), anyhow::Error> {
        let todo_repo = create_inmemory_todo_repo().await?;

        let todo = todo_repo.create(1, "Test Todo").await?;

        let todo = todo_repo.delete(todo.id).await?;

        assert_eq!(todo.id, todo.id);

        Ok(())
    }
}
