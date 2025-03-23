const { RtAudio, RtAudioFormat } = require("audify");
const { WebSocket, WebSocketServer } = require("ws");

const wss = new WebSocketServer({
  port: 5700,
});

console.log("Server ready...");

wss.on("connection", ws => {
  console.log("Socket connected. Sending data...");

  // Set binary type for the WebSocket connection
  ws.binaryType = "arraybuffer";

  // Send a welcome message or handle client-specific setup if needed
  ws.on("error", err => {
    console.error("WebSocket error:", err);
  });

  ws.on("close", () => {
    console.log("Client disconnected");
  });
});

// Init RtAudio instance using default sound API
const rtAudio = new RtAudio();
rtAudio.outputVolume = 0; // Mute output to prevent feedback

// Sample rate and frame size configuration
const sampleRate = 48000; // 44.1kHz
const frameSize = 1920; // 40ms at 44.1kHz is 1920

// Open the input/output stream
rtAudio.openStream(
  {
    deviceId: rtAudio.getDefaultOutputDevice(), // Output device id
    nChannels: 2, // Number of channels
    firstChannel: 0, // First channel index on device (default = 0)
  },
  {
    deviceId: rtAudio.getDefaultInputDevice(), // Input device id
    nChannels: 2, // Number of channels
    firstChannel: 0, // First channel index on device (default = 0)
  },
  RtAudioFormat.RTAUDIO_SINT16, // PCM Format - Signed 16-bit integer
  sampleRate, // Sampling rate (44.1kHz)
  frameSize, // Frame size (1920 samples = 40ms at 44.1kHz)
  "MyStream", // The name of the stream (used for JACK API)
  inputData => {
    // Only send data if there are connected clients
    if (wss.clients.size > 0) {
      // Clone the buffer to avoid issues with the data being reused
      const bufferCopy = Buffer.from(inputData);

      // Broadcast to all connected clients
      wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
          client.send(bufferCopy, { binary: true });
        }
      });
    }

    // Write input data to output (audio loopback)
    rtAudio.write(inputData);
  }
);

// Start the stream
rtAudio.start();

// Handle process termination
process.on("SIGINT", () => {
  console.log("Closing audio stream and WebSocket server...");
  rtAudio.closeStream();
  wss.close();
  process.exit(0);
});
