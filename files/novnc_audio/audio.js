import PCMPlayer from "./pcm-player.js";

export default function WsAudio() {
  var socketURL = "ws://" + window.location.hostname + ":5700";
  var player = new PCMPlayer({
    encoding: "16bitInt",
    channels: 2,
    sampleRate: 48000,
    flushingTime: 100,
  });

  var ws = new WebSocket(socketURL);
  ws.binaryType = "arraybuffer";
  ws.addEventListener("message", (event) => {
    var data = new Uint16Array(event.data);
    player.feed(data);
    player.volume(1);
  });
  return ws;
}
