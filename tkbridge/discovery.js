const dgram = require('dgram');
const { getLocalIP } = require('./deviceInfo');

let server;
const DISCOVERY_PORT = 8730;

function startDiscovery(pairingCode) {
    server = dgram.createSocket('udp4');

    server.on('error', (err) => {
        console.error(`Discovery server error:\n${err.stack}`);
        server.close();
    });

    server.on('message', (msg, rinfo) => {
        if (msg.toString() === 'TKBRIDGE_DISCOVER') {
            const response = JSON.stringify({
                type: 'tkbridge_host',
                ip: getLocalIP(),
                http_port: 8731,
                ws_port: 8732,
                pairing_code: pairingCode
            });
            server.send(response, rinfo.port, rinfo.address);
        }
    });

    server.on('listening', () => {
        const address = server.address();
        server.setBroadcast(true);
        // console.log(`Discovery server listening ${address.address}:${address.port}`);
    });

    server.bind(DISCOVERY_PORT);
}

function stopDiscovery() {
    if (server) {
        server.close();
        server = null;
    }
}

module.exports = { startDiscovery, stopDiscovery };
