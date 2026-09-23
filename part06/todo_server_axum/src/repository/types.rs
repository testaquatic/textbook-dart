use secrecy::SecretString;

/// DB에서 반환하는 Todo 정보
pub struct Sqlite3Todo {
    pub id: i64,
    pub title: String,
    pub completed: i64,
    pub user_id: i64,
    pub created_at: String,
    pub updated_at: Option<String>,
}

/// DB에서 반환하는 User 정보
pub struct Sqlite3User {
    pub id: i64,
    pub email: String,
    pub password_hash: SecretString,
    pub created_at: String,
}
