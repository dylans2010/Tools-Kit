const os = require('os');
const { execSync } = require('child_process');

function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return '127.0.0.1';
}

function getOS() {
    const platform = os.platform();
    if (platform === 'darwin') return 'macOS';
    if (platform === 'win32') return 'Windows';
    if (platform === 'linux') return 'Linux';
    return platform;
}

function getOSVersion() {
    try {
        if (os.platform() === 'darwin') {
            return execSync('sw_vers -productVersion').toString().trim();
        } else if (os.platform() === 'win32') {
            return os.release();
        } else if (os.platform() === 'linux') {
            return execSync('lsb_release -ds').toString().trim() || os.release();
        }
    } catch (e) {
        return os.release();
    }
    return os.release();
}

function getDeviceInfo() {
    return {
        device_name: os.hostname(),
        hostname: os.hostname(),
        ip: getLocalIP(),
        os: getOS(),
        os_version: getOSVersion(),
        arch: os.arch(),
        tkbridge_version: '1.0.0',
        uptime: Math.floor(os.uptime())
    };
}

module.exports = { getDeviceInfo, getLocalIP };
