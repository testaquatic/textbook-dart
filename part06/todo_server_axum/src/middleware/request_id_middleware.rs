use axum::{extract::Request, middleware::Next, response::Response};
use tracing::Instrument;

pub async fn request_id_middleware(mut request: Request, next: Next) -> Response {
    let request_id = uuid::Uuid::now_v7();
    request.extensions_mut().insert(request_id);

    next.run(request)
        .instrument(tracing::info_span!("request_id", uuid = %request_id))
        .await
}
