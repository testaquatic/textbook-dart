#[derive(serde::Deserialize)]
pub struct CreateTodoRequest {
    pub title: String,
}

#[derive(serde::Deserialize)]
pub struct UpdateTodoRequest {
    pub title: String,
    pub completed: bool,
}
