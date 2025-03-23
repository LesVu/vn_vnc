mod audio;
mod websocket;

use std::{
    env,
    net::SocketAddr,
    sync::{Arc, Mutex},
};

use audio::capture_audio;
use env_logger::Env;
use log::{debug, info, trace};
use tokio::net::TcpListener;
use websocket::handle_websocket;

const FRAME_SIZE: usize = 1920;
const CHANNELS: usize = 2;
const SAMPLE_RATE: u32 = 44100;

#[tokio::main]
async fn main() {
    env_logger::Builder::from_env(Env::default().default_filter_or("info")).init();

    let (tx, _) = tokio::sync::broadcast::channel::<Vec<i16>>(10);
    let tx1 = tx.clone();

    let addr = env::args()
        .nth(1)
        .unwrap_or_else(|| "127.0.0.1:5700".to_string());
    let addr: SocketAddr = addr.parse().expect("Invalid address");

    // Create the TCP listener
    let listener = TcpListener::bind(&addr).await.expect("Failed to bind");

    info!("Listening on: {}", addr);

    let buffer: Arc<Mutex<Vec<i16>>> =
        Arc::new(Mutex::new(Vec::with_capacity(FRAME_SIZE * CHANNELS)));
    let buffer_clone = buffer.clone();
    tokio::task::spawn_blocking(|| {
        capture_audio(CHANNELS, SAMPLE_RATE, move |data| {
            debug!("Audio sending to websocket");
            let mut buffer = buffer_clone.lock().unwrap();

            // Add the new data to our buffer
            buffer.extend_from_slice(data);

            // If we have enough samples, send them
            if buffer.len() >= FRAME_SIZE * CHANNELS {
                // Take exactly FRAME_SIZE * CHANNELS samples
                let frame_data = buffer.drain(0..FRAME_SIZE * CHANNELS).collect::<Vec<i16>>();

                // Send the data
                if let Err(e) = tx.send(frame_data) {
                    trace!("Error sending to channel: {:?}", e);
                }
            }
        })
    });

    // Accept tcp socket client
    while let Ok((stream, addr)) = listener.accept().await {
        // Spawn a new task for each connection
        info!("New client connected: {}", addr);
        let tx_cloned = tx1.clone();

        tokio::spawn(handle_websocket(tx_cloned, stream));
    }
}
