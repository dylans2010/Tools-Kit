import os

enum LMLinkLogger {
    static let subsystem = "com.toolskit.lmlink"
    static let auth    = Logger(subsystem: subsystem, category: "auth")
    static let deeplink = Logger(subsystem: subsystem, category: "deeplink")
    static let keychain = Logger(subsystem: subsystem, category: "keychain")
    static let api     = Logger(subsystem: subsystem, category: "api")
    static let keypair = Logger(subsystem: subsystem, category: "keypair")
}
