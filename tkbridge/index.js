#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { getDeviceInfo } = require('./deviceInfo');
const { startServer, stopServer, getStatus } = require('./server');

const PID_FILE = path.join(__dirname, 'tkbridge.pid');

function printHelp() {
    console.log(`
TKBridge CLI

Usage: tkbridge <command>

Commands:
  start     Start host service
  stop      Stop service
  status    Show system state
  restart   Restart service
  help      Show help menu

Description: TKBridge creates a secure local connection between your computer and mobile device over LAN.
`);
}

async function start() {
    if (fs.existsSync(PID_FILE)) {
        console.log('TKBridge is already running (PID: ' + fs.readFileSync(PID_FILE, 'utf8') + ')');
        return;
    }

    console.log('Starting TKBridge...');
    const server = await startServer();
    fs.writeFileSync(PID_FILE, process.pid.toString());

    process.on('SIGINT', () => stop());
    process.on('SIGTERM', () => stop());
}

function stop(exit = true) {
    if (!fs.existsSync(PID_FILE)) {
        console.log('TKBridge is not running.');
        if (exit) process.exit(0);
        return;
    }

    const pid = fs.readFileSync(PID_FILE, 'utf8');
    if (parseInt(pid) !== process.pid) {
        try {
            process.kill(parseInt(pid), 'SIGTERM');
            console.log('Sent stop signal to process ' + pid);
        } catch (e) {
            // Process might already be gone
        }
    }

    stopServer();
    if (fs.existsSync(PID_FILE)) fs.unlinkSync(PID_FILE);
    console.log('TKBridge stopped.');
    if (exit) process.exit(0);
}

function status() {
    const active = fs.existsSync(PID_FILE);
    const info = getDeviceInfo();
    const serverStatus = getStatus();

    console.log('TKBridge Host ' + (active ? 'Active' : 'Inactive'));
    console.log('');
    console.log('Device: ' + info.device_name);
    console.log('OS: ' + info.os + ' ' + info.os_version + ' (' + info.arch + ')');
    console.log('Local IP: ' + info.ip);
    console.log('HTTP Endpoint: http://' + info.ip + ':8731');
    console.log('WS Endpoint: ws://' + info.ip + ':8732');
    console.log('Pairing Code: ' + (serverStatus.pairing_code || 'N/A'));
    console.log('Active Sessions: ' + serverStatus.sessions.length);
    console.log('Uptime: ' + serverStatus.uptime + 's');
}

async function restart() {
    stop(false);
    // Give it a moment to release ports
    setTimeout(async () => {
        await start();
    }, 1000);
}

const args = process.argv.slice(2);
const command = args[0];

switch (command) {
    case 'start':
        start();
        break;
    case 'stop':
        stop();
        break;
    case 'status':
        status();
        break;
    case 'restart':
        restart();
        break;
    case 'help':
    default:
        printHelp();
        break;
}
