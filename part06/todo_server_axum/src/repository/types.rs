use secrecy::SecretString;

pub struct Sqlite3Todo {
    pub id: i64,
    pub title: String,
    pub completed: i64,
    pub user_id: i64,
    pub created_at: String,
    pub updated_at: Option<String>,
}

pub struct Sqlite3User {
    pub id: i64,
    pub email: String,
    pub password_hash: SecretString,
    pub created_at: String,
}
