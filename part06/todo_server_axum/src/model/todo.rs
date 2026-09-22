use chrono::{DateTime, Utc};
use sqlx::{FromRow, Row, sqlite::SqliteRow};

#[derive(serde::Serialize)]
pub struct Todo {
    pub id: i64,
    pub title: String,
    pub completed: bool,
    pub user_id: i64,
    pub created_at: DateTime<Utc>,
    pub updated_at: Option<DateTime<Utc>>,
}

impl TryFrom<Sqlite3Todo> for Todo {
    type Error = chrono::ParseError;
    fn try_from(value: Sqlite3Todo) -> Result<Self, Self::Error> {
        Ok(Todo {
            id: value.id,
            title: value.title,
            completed: value.completed != 0,
            user_id: value.user_id,
            created_at: DateTime::parse_from_rfc3339(&value.created_at)?.into(),
            updated_at: value
                .updated_at
                .map(|s| DateTime::parse_from_rfc3339(&s))
                .transpose()?
                .map(Into::into),
        })
    }
}

impl<'r> FromRow<'r, SqliteRow> for Todo {
    fn from_row(row: &'r SqliteRow) -> Result<Self, sqlx::Error> {
        let id = row.try_get("id")?;
        let title = row.try_get("title")?;
        let completed = row.try_get("completed")?;
        let user_id = row.try_get("user_id")?;
        let created_at = DateTime::parse_from_rfc3339(row.try_get("created_at")?)
            .map_err(|e| sqlx::Error::Decode(e.into()))?
            .into();
        let updated_at = row
            .try_get::<Option<String>, _>("updated_at")?
            .map(|s| DateTime::parse_from_rfc3339(&s))
            .transpose()
            .map_err(|e| sqlx::Error::Decode(e.into()))?
            .map(Into::into);

        Ok(Self {
            id,
            title,
            completed,
            user_id,
            created_at,
            updated_at,
        })
    }
}

pub struct Sqlite3Todo {
    pub id: i64,
    pub title: String,
    pub completed: i64,
    pub user_id: i64,
    pub created_at: String,
    pub updated_at: Option<String>,
}

#[derive(serde::Deserialize)]
pub struct CreateTodoRequest {
    pub title: String,
}

#[derive(serde::Deserialize)]
pub struct UpdateTodoRequest {
    pub title: String,
    pub completed: bool,
}
