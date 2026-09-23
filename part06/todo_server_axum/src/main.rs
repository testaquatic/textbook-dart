use todo_server_axum::telemetry::init_telemetry;

#[tokio::main]
async fn main() {
    init_telemetry();
}
