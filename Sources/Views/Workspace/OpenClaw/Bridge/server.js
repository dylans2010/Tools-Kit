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

    const currentNonce = Math.random().toString(36).substring(7);

    // Simulate OpenClaw Handshake
    const challenge = {
        event: 'connect.challenge',
        payload: { nonce: currentNonce }
    };
    console.log('SEND:', JSON.stringify(challenge));
    ws.send(JSON.stringify(challenge));

    ws.on('message', (message) => {
        const data = JSON.parse(message);
        console.log('RECV:', JSON.stringify(data));

        if (data.event === 'connect.response') {
            console.log('Handshake response received');
            const { nonce, signature } = data.payload;
            if (nonce === currentNonce && signature) {
                console.log('Handshake validation successful');
                const success = { event: 'auth.success', payload: { status: 'authenticated' } };
                console.log('SEND:', JSON.stringify(success));
                ws.send(JSON.stringify(success));
            } else {
                console.log('Handshake validation failed. Nonce match:', nonce === currentNonce);
                ws.terminate();
            }
        } else if (data.method === 'connect') {
            // Initial connect should return a challenge (handled on connection open above usually,
            // but we can acknowledge the connect too if the protocol requires)
            ws.send(JSON.stringify({
                jsonrpc: '2.0',
                result: { status: 'pending_challenge' },
                id: data.id
            }));
        } else if (data.method === 'pair') {
            console.log('Pairing requested by:', data.params.device_name);
            // Simulate user approval after 1s
            setTimeout(() => {
                const response = {
                    jsonrpc: '2.0',
                    result: {
                        status: 'paired',
                        token: 'simulated_pairing_token_' + Math.random().toString(36).substring(7)
                    },
                    id: data.id
                };
                console.log('SEND:', JSON.stringify(response));
                ws.send(JSON.stringify(response));
            }, 1000);
        } else if (data.method === 'authenticate') {
            if (data.params.token && data.params.token.startsWith('simulated_pairing_token_')) {
                ws.send(JSON.stringify({
                    jsonrpc: '2.0',
                    result: { status: 'authenticated' },
                    id: data.id
                }));
            } else {
                ws.send(JSON.stringify({
                    jsonrpc: '2.0',
                    error: { code: 401, message: 'Invalid token' },
                    id: data.id
                }));
            }
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
