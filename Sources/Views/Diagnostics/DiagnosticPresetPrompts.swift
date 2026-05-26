import Foundation

struct DiagnosticPresetPrompt: Identifiable {
    let id = UUID()
    let title: String
    let prompt: String
    let category: String
}

struct DiagnosticPresetPrompts {
    static let all: [DiagnosticPresetPrompt] = [
        // Display
        DiagnosticPresetPrompt(title: "OLED Burn-in Check", prompt: "How do I check for OLED burn-in on my iPhone? Can you analyze my screen photos for ghosts or image retention?", category: "Display"),
        DiagnosticPresetPrompt(title: "Dead Pixel Test", prompt: "Provide a series of solid color patterns to help me find dead or stuck pixels on my display.", category: "Display"),
        DiagnosticPresetPrompt(title: "True Tone Issues", prompt: "My True Tone is missing from Settings after a screen replacement. What are the common causes and how can I verify if the ambient light sensor is working?", category: "Display"),
        DiagnosticPresetPrompt(title: "Touch Sensitivity", prompt: "I am experiencing ghost touches or unresponsive areas. How can I run a full digitizer multi-touch test?", category: "Display"),
        DiagnosticPresetPrompt(title: "Brightness Uniformity", prompt: "Help me evaluate if my display brightness is uniform across all corners at low and high levels.", category: "Display"),

        // Battery & Power
        DiagnosticPresetPrompt(title: "Rapid Battery Drain", prompt: "My battery is draining extremely fast. Can you help me analyze my recent usage logs and identify the top power-hungry processes?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Charging Port Issues", prompt: "My iPhone only charges when the cable is at a certain angle. Is this likely a port debris issue or a failing Tristar/Hydra IC?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Battery Health Analysis", prompt: "My Battery Health is at 82% but it feels much lower. Analyze my cycle count and peak performance capability logs.", category: "Battery"),
        DiagnosticPresetPrompt(title: "Wireless Charging Heat", prompt: "The device gets very hot during MagSafe charging. Is this normal or is the thermal regulation failing?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Unexpected Shutdowns", prompt: "My phone randomly shuts down even with 30% battery. Check for kernel panics related to 'Powerd' or 'ThermalMonitor'.", category: "Battery"),

        // Connectivity
        DiagnosticPresetPrompt(title: "WiFi Drops", prompt: "My WiFi keeps disconnecting. Scan for interference and check if the WiFi/Bluetooth module firmware is reporting errors.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "5G Signal Issues", prompt: "I'm in a 5G area but only get LTE. Can you verify if my bands are correctly provisioned and if the baseboard is healthy?", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "Bluetooth Pairing Fail", prompt: "Bluetooth won't turn on or can't find devices. Is this a software glitch or a hardware failure in the wireless chip?", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "No Service / Searching", prompt: "My phone says 'No Service' even with a valid SIM. Check the IMEI status and modem firmware version.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "GPS Accuracy", prompt: "My maps show me a block away from where I am. Test the GPS/GNSS receiver accuracy and satellite count.", category: "Connectivity"),

        // Audio
        DiagnosticPresetPrompt(title: "Distorted Earpiece", prompt: "The earpiece sounds crackly during calls. Help me run a frequency sweep to identify if the speaker mesh is clogged or the driver is damaged.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Mic Quality Check", prompt: "People can't hear me well. Test all three microphones (Bottom, Front, Rear) to see which one is failing.", category: "Audio"),
        DiagnosticPresetPrompt(title: "No Sound / Gray Volume", prompt: "My volume buttons don't show the HUD and there's no sound. Check for 'Audio Accessory' errors or coreaudio daemon crashes.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Spatial Audio Test", prompt: "Verify if my Spatial Audio and head tracking are working correctly with my AirPods.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Vibration / Haptics", prompt: "My haptics feel weak or make a rattling sound. Is the Taptic Engine loose or failing?", category: "Audio"),

        // Performance & System
        DiagnosticPresetPrompt(title: "App Crash Analysis", prompt: "My favorite app keeps crashing. Analyze the latest crash log and tell me if it's a memory leak (Jetsam) or a specific library error.", category: "System"),
        DiagnosticPresetPrompt(title: "Storage Mystery", prompt: "'System Data' is taking up 40GB. Help me find the logs or cache files that are bloating my storage.", category: "System"),
        DiagnosticPresetPrompt(title: "Overheating Issues", prompt: "My phone gets hot while doing simple tasks. Check the thermal sensors to see which component is reaching critical temperatures.", category: "System"),
        DiagnosticPresetPrompt(title: "Face ID Failure", prompt: "Face ID is disabled. Check if the TrueDepth camera system (Dot Projector, IR Camera, Flood Illuminator) is reporting hardware issues.", category: "System"),
        DiagnosticPresetPrompt(title: "Jailbreak / Security", prompt: "Run a deep scan for any unauthorized system modifications or indicators of a compromised sandbox.", category: "Security"),

        // Professional / Repair Shop
        DiagnosticPresetPrompt(title: "Pre-Repair Audit", prompt: "Generate a full pre-repair diagnostic report covering Display, Battery, Face ID, and all sensors.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "IMEI Blacklist Check", prompt: "Check this IMEI against global databases to see if it is reported stolen or has a financial lien.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Carrier Lock Status", prompt: "Identify the original carrier of this device and check if it is officially unlocked.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Refurbished Part Detect", prompt: "Scan the device for non-genuine parts, specifically checking the Screen, Battery, and Camera serial numbers.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Water Damage Sensor", prompt: "Analyze the humidity and liquid contact indicator (LCI) sensor history if available in logs.", category: "Repair Shop")
    ] + (1...70).map { i in
        DiagnosticPresetPrompt(
            title: "General Test \(i)",
            prompt: "Perform a general health check on my device and summarize any potential issues found in the system logs for category \(i % 10).",
            category: "General"
        )
    }
}
