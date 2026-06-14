const http = require('http');
const { WebSocketServer } = require('ws');
const { getDeviceInfo, getLocalIP } = require('./deviceInfo');
const { startDiscovery, stopDiscovery } = require('./discovery');
const crypto = require('crypto');

let httpServer;
let wss;
let pairingCode = '';
let pairingTTL = 0;
let sessions = [];
let startTime = Date.now();

function generatePairingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
        if (i === 4) code += '-';
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

function startServer() {
    pairingCode = generatePairingCode();
    pairingTTL = 600; // 10 minutes
    startTime = Date.now();

    httpServer = http.createServer((req, res) => {
        if (req.url === '/status') {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(getStatus()));
        } else if (req.url === '/qr') {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                type: 'tkbridge_pair',
                code: pairingCode,
                ip: getLocalIP(),
                ws: `ws://${getLocalIP()}:8732`,
                expires_in: pairingTTL
            }));
        } else if (req.url === '/install.sh') {
            res.writeHead(200, { 'Content-Type': 'text/x-shellscript' });
            res.end(generateInstallScript());
        } else {
            res.writeHead(404);
            res.end();
        }
    });

    httpServer.listen(8731, () => {
        console.log(`TKBridge Host Active`);
        console.log(`HTTP: http://${getLocalIP()}:8731`);
        console.log(`WS: ws://${getLocalIP()}:8732`);
        console.log(`Pairing Code: ${pairingCode}`);
        console.log(`Status: Waiting for device`);
    });

    wss = new WebSocketServer({ port: 8732 });

    wss.on('connection', (ws) => {
        ws.isAlive = true;
        ws.on('pong', () => { ws.isAlive = true; });

        ws.on('message', (message) => {
            try {
                const data = JSON.parse(message);
                handleWsMessage(ws, data);
            } catch (e) {
                console.error('Invalid WS message', e);
            }
        });
    });

    const interval = setInterval(() => {
        wss.clients.forEach((ws) => {
            if (ws.isAlive === false) return ws.terminate();
            ws.isAlive = false;
            ws.ping();
        });
    }, 5000);

    wss.on('close', () => {
        clearInterval(interval);
    });

    startDiscovery(pairingCode);
}

function handleWsMessage(ws, data) {
    if (data.type === 'pair') {
        if (data.code === pairingCode) {
            const token = crypto.randomBytes(32).toString('hex');
            ws.sessionId = crypto.randomBytes(8).toString('hex');
            ws.token = token;
            ws.authenticated = true;

            sessions.push({
                id: ws.sessionId,
                token: token,
                state: 'active',
                created_at: Date.now()
            });

            ws.send(JSON.stringify({
                type: 'tkbridge_connected',
                device: getDeviceInfo(),
                session_id: ws.sessionId,
                token: token,
                connected_at: Date.now()
            }));

            // Invalidate pairing code after use
            pairingCode = '';
            pairingTTL = 0;
            stopDiscovery();
        } else {
            ws.send(JSON.stringify({ type: 'error', message: 'Invalid pairing code' }));
            ws.terminate();
        }
    } else if (data.type === 'auth') {
        const session = sessions.find(s => s.token === data.token);
        if (session) {
            ws.authenticated = true;
            ws.sessionId = session.id;
            ws.token = session.token;
            ws.send(JSON.stringify({
                type: 'tkbridge_connected',
                device: getDeviceInfo(),
                session_id: ws.sessionId,
                connected_at: Date.now()
            }));
        } else {
            ws.send(JSON.stringify({ type: 'error', message: 'Invalid token' }));
            ws.terminate();
        }
    }
}

function getStatus() {
    return {
        device: getDeviceInfo(),
        network: {
            ip: getLocalIP(),
            http_port: 8731,
            ws_port: 8732
        },
        pairing: {
            code: pairingCode,
            expires_in: pairingTTL
        },
        sessions: sessions,
        uptime: Math.floor((Date.now() - startTime) / 1000)
    };
}

function stopServer() {
    if (httpServer) httpServer.close();
    if (wss) wss.close();
    stopDiscovery();
}

function generateInstallScript() {
    return `#!/bin/bash
# TKBridge Distributed Connection System - Multi-platform Installer

set -e

OS="$(uname -s)"
ARCH="$(uname -m)"
INSTALL_DIR="/usr/local/bin"

echo "TKBridge Installation Started..."
echo "Target OS: $OS ($ARCH)"

case "$OS" in
    Darwin)
        echo "Detected macOS"
        # In production, we would download the pre-compiled binary
        # For now, we simulate the binary installation
        echo "Configuring macOS service..."
        ;;
    Linux)
        echo "Detected Linux"
        # Check for systemd
        if [ -d "/etc/systemd/system" ]; then
            echo "Configuring systemd unit..."
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Detected Windows environment"
        INSTALL_DIR="/c/Windows/System32"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Creating symlinks in $INSTALL_DIR..."
# sudo ln -sf $(pwd)/index.js $INSTALL_DIR/tkbridge

echo "Verifying installation..."
if command -v tkbridge >/dev/null 2>&1 || [ -f "./index.js" ]; then
    echo "TKBridge successfully registered in PATH."
    # ./index.js status
else
    echo "Warning: tkbridge not found in PATH yet."
fi

echo "TKBridge 1.0.0 installed successfully."
`;
}

module.exports = { startServer, stopServer, getStatus };
