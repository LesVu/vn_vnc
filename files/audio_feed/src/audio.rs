use std::{thread, time::Duration};

use cpal::{
    BufferSize, SampleRate, StreamConfig,
    traits::{DeviceTrait, HostTrait, StreamTrait},
};
use log::{debug, error, info};

pub fn capture_audio<F: FnMut(&[i16]) + Send + 'static>(
    channels: usize,
    sample_rate: u32,
    mut callback: F,
) {
    let host = cpal::default_host();
    info!("Using Default Host...");

    let device = host
        .input_devices()
        .unwrap()
        .find(|device| device.name().unwrap_or_default() == "pulse")
        .expect("output device pulse unavailable");

    info!("Setting Device To {}", device.name().unwrap());

    let mut config: StreamConfig = device.default_input_config().unwrap().into();
    config.channels = channels as u16;
    config.sample_rate = SampleRate(sample_rate);
    config.buffer_size = BufferSize::Fixed(1920);

    debug!("Config Sample Rate: {} Hz", config.sample_rate.0);
    debug!("Config Buffer Size: {:?}", config.buffer_size);

    info!("Building Input From Stream...");
    let stream = match device.build_input_stream(
        &config.into(),
        move |data: &[i16], _: &cpal::InputCallbackInfo| callback(data),
        |err| error!("{}", err),
        None, // None=blocking, Some(Duration)=timeout
    ) {
        Ok(stream) => stream,
        Err(e) => {
            error!("{}", e);
            return;
        }
    };

    info!("Starting Stream...");
    stream.play().unwrap();
    loop {
        thread::sleep(Duration::from_secs(1));
    }
}
