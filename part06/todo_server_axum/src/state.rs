use std::sync::Arc;

use sqlx::SqlitePool;

use crate::config::Configuration;

#[derive(Clone)]
pub struct AppState {
    pub config: Arc<Configuration>,
    pub db_pool: SqlitePool,
}

impl AppState {
    pub fn new(config: Configuration, db_pool: SqlitePool) -> Self {
        Self {
            config: Arc::new(config),
            db_pool,
        }
    }
}
