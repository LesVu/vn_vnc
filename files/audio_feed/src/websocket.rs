use futures::SinkExt;
use log::debug;
use tokio::{net::TcpStream, sync::broadcast::Sender};
use tokio_tungstenite::{accept_async, tungstenite::Message};

pub async fn handle_websocket(tx: Sender<Vec<i16>>, stream: TcpStream) {
    let mut rx = tx.subscribe();
    let mut ws_stream = accept_async(stream).await.expect("Error");
    debug!("Accepted Websocket connection: {:?}", ws_stream);

    while let Ok(data) = rx.recv().await {
        debug!("data converting...");
        let bytes: Vec<u8> = unsafe {
            std::slice::from_raw_parts(
                data.as_ptr() as *const u8,
                data.len() * std::mem::size_of::<i16>(),
            )
            .to_vec()
        };
        debug!("data sending...");
        if ws_stream.send(Message::Binary(bytes.into())).await.is_err() {
            debug!("WebSocket client send error");
        }
    }
}
