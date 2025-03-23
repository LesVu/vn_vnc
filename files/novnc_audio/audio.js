export default function WsAudio() {
  const socketURL = `ws://${window.location.hostname}:5700`;
  const channels = 2;
  const Int16ArrayMaxValue = 32767.0;
  const sampleRate = 48000;
  const frameSize = 1920;
  const expectedBufferSize = frameSize * channels; // Total samples per frame

  const ws = new WebSocket(socketURL);
  ws.binaryType = "arraybuffer";

  const audioCtx = new (window.AudioContext || window.webkitAudioContext)({
    sampleRate: sampleRate,
  });
  audioCtx.resume().then(_ => console.log("resume"));

  ws.addEventListener("message", event => {
    if (
      !event.data ||
      !(event.data instanceof ArrayBuffer) ||
      event.data.byteLength % 2 !== 0
    ) {
      console.warn("Received invalid data format or incorrect byte alignment");
      return;
    }

    const int16Array = new Int16Array(event.data);
    // Verify buffer size
    if (int16Array.length !== expectedBufferSize) {
      console.warn(
        `Unexpected buffer size: ${int16Array.length}, expected: ${expectedBufferSize}`
      );
    }

    const numFrames = int16Array.length / channels;

    const audioBuffer = audioCtx.createBuffer(channels, numFrames, sampleRate);

    // Process each channel separately
    for (let ch = 0; ch < channels; ch++) {
      const channelData = audioBuffer.getChannelData(ch);
      for (let i = 0; i < numFrames; i++) {
        // Convert Int16 to Float32 (-1.0 to 1.0)
        channelData[i] = int16Array[i * channels + ch] / Int16ArrayMaxValue;
      }
    }

    const source = audioCtx.createBufferSource();
    source.buffer = audioBuffer;

    let gainNode = audioCtx.createGain();
    gainNode.gain.value = 1;
    gainNode.connect(audioCtx.destination);
    source.connect(gainNode);
    source.start(0);
  });

  return ws;
}
