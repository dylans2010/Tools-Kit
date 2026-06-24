const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const bonjour = require('bonjour')();

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;

// Bonjour Advertisement
bonjour.publish({ name: 'OpenClaw Bridge', type: 'openclaw-gw', port: PORT });

wss.on('connection', (ws) => {
    console.log('Client connected to bridge');

    // Simulate OpenClaw Handshake
    ws.send(JSON.stringify({
        event: 'connect.challenge',
        payload: { nonce: Math.random().toString(36).substring(7) }
    }));

    ws.on('message', (message) => {
        const data = JSON.parse(message);
        console.log('Received:', data);

        if (data.method === 'connect') {
            ws.send(JSON.stringify({
                jsonrpc: '2.0',
                result: { status: 'authenticated' },
                id: data.id
            }));
        } else if (data.method === 'ping') {
            ws.send(JSON.stringify({
                jsonrpc: '2.0',
                result: 'pong',
                id: data.id
            }));
        }
    });
});

server.listen(PORT, () => {
    console.log(`OpenClaw Bridge running on port ${PORT}`);
});
