const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const bonjour = require('bonjour')();
const os = require('os');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;

// Unique service name construction (Feature E.2)
const serviceName = `OpenClaw-${os.hostname()}-${process.pid}`;

// Deregister any existing before register
bonjour.unpublishAll(() => {
    console.log('Unpublished existing services');
    // Bonjour Advertisement
    bonjour.publish({ name: serviceName, type: 'openclaw-gw', port: PORT });
});

process.on('SIGTERM', () => {
    bonjour.unpublishAll(() => {
        process.exit();
    });
});

process.on('SIGINT', () => {
    bonjour.unpublishAll(() => {
        process.exit();
    });
});

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
            // Initial connect should return a challenge (handled on connection open above usually,
            // but we can acknowledge the connect too if the protocol requires)
            ws.send(JSON.stringify({
                jsonrpc: '2.0',
                result: { status: 'pending_challenge' },
                id: data.id
            }));
        } else if (data.method === 'authenticate') {
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
