import PCMPlayer from "./pcm-player.js";

export default function WsAudio() {
	const socketURL = `ws://${window.location.hostname}:5700`;
	const player = new PCMPlayer({
		encoding: "16bitInt",
		channels: 2,
		sampleRate: 48000,
		flushingTime: 100,
	});

	const ws = new WebSocket(socketURL);
	ws.binaryType = "arraybuffer";
	ws.addEventListener("message", (event) => {
		const data = new Uint16Array(event.data);
		player.feed(data);
		player.volume(1);
	});
	return ws;
}
