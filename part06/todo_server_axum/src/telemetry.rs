use tracing_subscriber::{
    EnvFilter,
    fmt::{self},
    layer::SubscriberExt,
    util::SubscriberInitExt,
};

pub fn init_telemetry() {
    let env_filter = if cfg!(debug_assertions) {
        EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| "debugn,todo_server_axum=debug,tower_http=debug".into())
    } else {
        EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| "info,todo_server_axum=info,tower_http=info".into())
    };

    let debug_fmt_subscriber = if cfg!(debug_assertions) {
        Some(fmt::Layer::default().pretty())
    } else {
        None
    };

    let release_fmt_subscriber = if !cfg!(debug_assertions) {
        Some(fmt::Layer::default().json())
    } else {
        None
    };

    tracing_subscriber::Registry::default()
        .with(env_filter)
        .with(debug_fmt_subscriber)
        .with(release_fmt_subscriber)
        .init();
}
