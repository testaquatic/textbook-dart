#[derive(thiserror::Error, Debug)]
pub enum ServiceError {
    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Internal server error: {0}")]
    InternalServerError(anyhow::Error),

    #[error("DatabaseError: {0}")]
    DatabaseError(#[from] sqlx::Error),
}
