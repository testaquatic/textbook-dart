use sqlx::SqliteExecutor;

use crate::repository::types::Sqlite3Todo;

/// 사용자의 모든 할 일을 조회한다.
#[tracing::instrument(skip_all, fields(todos.user_id = %user_id))]
pub async fn find_todo_by_user_id(
    executor: impl SqliteExecutor<'_>,
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
        .fetch_all(executor)
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
        .fetch_all(executor)
        .await
    }
}

/// 특정 할 일을 ID로 조회한다.
#[tracing::instrument(skip_all, fields(todos.id = %id))]
pub async fn find_todo_by_id(
    executor: impl SqliteExecutor<'_>,
    id: i64,
) -> Result<Option<Sqlite3Todo>, sqlx::Error> {
    sqlx::query_as!(
        Sqlite3Todo,
        r#"
            SELECT * FROM todos WHERE id = ?
            "#,
        id
    )
    .fetch_optional(executor)
    .await
}

/// 새로운 할 일을 생성한다.
#[tracing::instrument(skip_all, fields(todos.id = tracing::field::Empty, todos.user_id = %user_id))]
pub async fn create_todo(
    executor: impl SqliteExecutor<'_>,
    user_id: i64,
    title: &str,
) -> Result<Sqlite3Todo, sqlx::Error> {
    let row = sqlx::query!(
        r#"
            INSERT INTO todos (title, user_id)
            VALUES (?, ?)
            RETURNING id, title, completed, user_id, created_at, updated_at;
            "#,
        title,
        user_id,
    )
    .fetch_one(executor)
    .await?;

    let id = row
        .id
        .ok_or_else(|| sqlx::error::Error::ColumnNotFound("id".into()))?;
    tracing::Span::current().record("skip_all", id);

    Ok(Sqlite3Todo {
        id,
        title: row.title,
        completed: row.completed,
        user_id: row.user_id,
        created_at: row.created_at,
        updated_at: row.updated_at,
    })
}

/// 할 일을 수정한다.
#[tracing::instrument(skip_all, fields(todos.id = %id))]
pub async fn update_todo(
    executor: impl SqliteExecutor<'_>,
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
        .fetch_one(executor)
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
#[tracing::instrument(skip_all, fields(todos.id = %id))]
pub async fn delete_todo(
    executor: impl SqliteExecutor<'_>,
    id: i64,
) -> Result<Sqlite3Todo, sqlx::Error> {
    sqlx::query_as!(
            Sqlite3Todo,
            r#"
            DELETE FROM todos WHERE id = ? RETURNING id, title, completed, user_id, created_at, updated_at;
            "#,
            id
        ).fetch_one(executor)
        .await
}

#[cfg(test)]
mod tests {

    use secrecy::SecretString;
    use sqlx::SqlitePool;

    use crate::repository::{
        todo_repository::{
            create_todo, delete_todo, find_todo_by_id, find_todo_by_user_id, update_todo,
        },
        user_repostitory::create_user,
    };

    async fn create_inmemory_todo_repo() -> Result<SqlitePool, anyhow::Error> {
        let pool = sqlx::SqlitePool::connect(":memory:").await?;
        sqlx::migrate!("./migrations").run(&pool).await?;

        create_user(
            &pool,
            "test@example.com",
            &SecretString::new("password".into()),
        )
        .await?;

        Ok(pool)
    }

    #[tokio::test]
    async fn test_create() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_todo_repo().await?;

        let todo = create_todo(&pool, 1, "Test Todo").await?;

        assert_eq!(todo.title, "Test Todo");
        assert_eq!(todo.user_id, 1);
        assert_eq!(todo.completed, 0);

        Ok(())
    }

    #[tokio::test]
    async fn test_find_by_user_id() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_todo_repo().await?;

        create_todo(&pool, 1, "Test Todo 1").await?;
        create_todo(&pool, 1, "Test Todo 2").await?;

        let todos = find_todo_by_user_id(&pool, 1, None, None, None).await?;

        assert_eq!(todos.len(), 2);

        Ok(())
    }

    #[tokio::test]
    async fn test_find_by_id() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_todo_repo().await?;

        let todo = create_todo(&pool, 1, "Test Todo").await?;

        let todo = find_todo_by_id(&pool, todo.id).await?;

        assert!(todo.is_some());

        Ok(())
    }

    #[tokio::test]
    async fn test_update() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_todo_repo().await?;

        let todo = create_todo(&pool, 1, "Test Todo").await?;

        let todo = update_todo(&pool, todo.id, Some("Test Todo Updated"), Some(true)).await?;

        assert_eq!(todo.title, "Test Todo Updated");
        assert_eq!(todo.completed, 1);

        let new_todo = update_todo(&pool, todo.id, None, None).await?;

        assert_eq!(new_todo.title, todo.title);
        assert_eq!(new_todo.completed, todo.completed);

        Ok(())
    }

    #[tokio::test]
    async fn test_delete() -> Result<(), anyhow::Error> {
        let pool = create_inmemory_todo_repo().await?;

        let todo = create_todo(&pool, 1, "Test Todo").await?;

        let todo = delete_todo(&pool, todo.id).await?;

        assert_eq!(todo.id, todo.id);

        Ok(())
    }
}
