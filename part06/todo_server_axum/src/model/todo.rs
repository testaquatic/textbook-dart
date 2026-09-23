use chrono::{DateTime, Utc};

use crate::repository::types::Sqlite3Todo;

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

#[derive(serde::Deserialize)]
pub struct CreateTodoRequest {
    pub title: String,
}

#[derive(serde::Deserialize)]
pub struct UpdateTodoRequest {
    pub title: String,
    pub completed: bool,
}
