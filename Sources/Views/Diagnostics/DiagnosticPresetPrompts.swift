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
        DiagnosticPresetPrompt(title: "HDR Content Peak", prompt: "My HDR content looks dim. How can I verify if the peak brightness is reaching the factory specifications?", category: "Display"),
        DiagnosticPresetPrompt(title: "Refresh Rate Jitter", prompt: "I notice stuttering in animations. Is there a way to log frame drops and check the ProMotion 120Hz consistency?", category: "Display"),
        DiagnosticPresetPrompt(title: "Color Shift Audit", prompt: "My screen looks yellow at certain angles. Is this within the expected OLED color shift range?", category: "Display"),
        DiagnosticPresetPrompt(title: "Digitizer Grid Test", prompt: "Draw a grid on my screen to help me trace and identify dead touch zones across the display.", category: "Display"),
        DiagnosticPresetPrompt(title: "Backlight Bleed", prompt: "On my LCD model, I see light leaking from the edges. How can I quantify this backlight bleed?", category: "Display"),
        DiagnosticPresetPrompt(title: "Polarizer Integrity", prompt: "My screen looks strange with sunglasses. How can I check if the polarizing layer is damaged or missing?", category: "Display"),
        DiagnosticPresetPrompt(title: "Screen Flickering", prompt: "I see subtle flickering at low brightness. Is this PWM (Pulse Width Modulation) or a failing display driver?", category: "Display"),

        // Battery & Power
        DiagnosticPresetPrompt(title: "Rapid Battery Drain", prompt: "My battery is draining extremely fast. Can you help me analyze my recent usage logs and identify the top power-hungry processes?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Charging Port Issues", prompt: "My iPhone only charges when the cable is at a certain angle. Is this likely a port debris issue or a failing Tristar/Hydra IC?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Battery Health Analysis", prompt: "My Battery Health is at 82% but it feels much lower. Analyze my cycle count and peak performance capability logs.", category: "Battery"),
        DiagnosticPresetPrompt(title: "Wireless Charging Heat", prompt: "The device gets very hot during MagSafe charging. Is this normal or is the thermal regulation failing?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Unexpected Shutdowns", prompt: "My phone randomly shuts down even with 30% battery. Check for kernel panics related to 'Powerd' or 'ThermalMonitor'.", category: "Battery"),
        DiagnosticPresetPrompt(title: "Peak Power Throttling", prompt: "Is my CPU being throttled due to battery degradation? Show me the current peak power capability status.", category: "Battery"),
        DiagnosticPresetPrompt(title: "Charge Cycle Count", prompt: "What is the exact number of charge cycles on my battery? How does this compare to the 500-cycle health estimate?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Slow Charging Log", prompt: "It takes 4 hours to charge to 100%. Analyze the handshake between the charger and the Power Management Unit.", category: "Battery"),
        DiagnosticPresetPrompt(title: "Internal Resistance", prompt: "Can we estimate the internal resistance of the battery cells based on voltage drop under load?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Standby Drain Check", prompt: "My phone loses 15% overnight. Which background daemons are preventing the device from entering deep sleep?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Voltage Sag Audit", prompt: "Monitor my battery voltage under a heavy 3D benchmark. Is the voltage sagging below the 3.4V threshold?", category: "Battery"),
        DiagnosticPresetPrompt(title: "Coulomb Counter Drift", prompt: "My battery percentage jumps from 20% to 10%. Do I need to recalibrate the coulomb counter?", category: "Battery"),

        // Connectivity
        DiagnosticPresetPrompt(title: "WiFi Drops", prompt: "My WiFi keeps disconnecting. Scan for interference and check if the WiFi/Bluetooth module firmware is reporting errors.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "5G Signal Issues", prompt: "I'm in a 5G area but only get LTE. Can you verify if my bands are correctly provisioned and if the baseboard is healthy?", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "Bluetooth Pairing Fail", prompt: "Bluetooth won't turn on or can't find devices. Is this a software glitch or a hardware failure in the wireless chip?", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "No Service / Searching", prompt: "My phone says 'No Service' even with a valid SIM. Check the IMEI status and modem firmware version.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "GPS Accuracy", prompt: "My maps show me a block away from where I am. Test the GPS/GNSS receiver accuracy and satellite count.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "Antenna Diversity", prompt: "How can I check which internal antenna (Top/Bottom) is active and if there's an impedance mismatch?", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "SIM Reader Fault", prompt: "I get 'No SIM Card Installed' randomly. Is the physical reader pin-bent or is the SIM controller failing?", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "Hotspot Disconnect", prompt: "Personal Hotspot keeps turning off. Analyze the network stack for DHCP conflicts or carrier-enforced timeouts.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "AirDrop Visibility", prompt: "I can't be found via AirDrop. Test the AWDL (Apple Wireless Direct Link) interface for configuration errors.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "NFC Field Test", prompt: "Apple Pay fails at terminals. How do I test the NFC coil and the Secure Element response?", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "WiFi 6E Availability", prompt: "Am I connected to a 6GHz band? Verify if the WiFi 6E features are enabled on this network.", category: "Connectivity"),
        DiagnosticPresetPrompt(title: "UWB Precision Check", prompt: "My Precision Finding for AirTags isn't working. Is the U1/U2 Ultra Wideband chip reporting errors?", category: "Connectivity"),

        // Audio
        DiagnosticPresetPrompt(title: "Distorted Earpiece", prompt: "The earpiece sounds crackly during calls. Help me run a frequency sweep to identify if the speaker mesh is clogged or the driver is damaged.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Mic Quality Check", prompt: "People can't hear me well. Test all three microphones (Bottom, Front, Rear) to see which one is failing.", category: "Audio"),
        DiagnosticPresetPrompt(title: "No Sound / Gray Volume", prompt: "My volume buttons don't show the HUD and there's no sound. Check for 'Audio Accessory' errors or coreaudio daemon crashes.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Spatial Audio Test", prompt: "Verify if my Spatial Audio and head tracking are working correctly with my AirPods.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Vibration / Haptics", prompt: "My haptics feel weak or make a rattling sound. Is the Taptic Engine loose or failing?", category: "Audio"),
        DiagnosticPresetPrompt(title: "Speaker Phase Test", prompt: "One speaker sounds 'thinner' than the other. Can we check the phase alignment of the stereo speakers?", category: "Audio"),
        DiagnosticPresetPrompt(title: "Voice Isolation Fault", prompt: "My voice is muffled when using 'Voice Isolation'. Analyze the noise cancellation algorithm logs.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Headphone Jack Detect", prompt: "My phone thinks headphones are plugged in but they aren't. Check the Lightning/USB-C port for shorted pins.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Ultrasonic Test", prompt: "Test the speakers at high frequencies to detect any ultrasonic artifacts or hardware clipping.", category: "Audio"),
        DiagnosticPresetPrompt(title: "Latency Benchmark", prompt: "Measure the round-trip audio latency for professional music apps. Is the buffer size optimized?", category: "Audio"),
        DiagnosticPresetPrompt(title: "A2DP Codec Audit", prompt: "Which Bluetooth audio codec is currently active (AAC, SBC)? Check for packet drops in the A2DP stream.", category: "Audio"),
        DiagnosticPresetPrompt(title: "ANC Feedback Loop", prompt: "My AirPods have a whistling sound. Is the feedback microphone experiencing a hardware loop?", category: "Audio"),

        // Performance & System
        DiagnosticPresetPrompt(title: "App Crash Analysis", prompt: "My favorite app keeps crashing. Analyze the latest crash log and tell me if it's a memory leak (Jetsam) or a specific library error.", category: "System"),
        DiagnosticPresetPrompt(title: "Storage Mystery", prompt: "'System Data' is taking up 40GB. Help me find the logs or cache files that are bloating my storage.", category: "System"),
        DiagnosticPresetPrompt(title: "Overheating Issues", prompt: "My phone gets hot while doing simple tasks. Check the thermal sensors to see which component is reaching critical temperatures.", category: "System"),
        DiagnosticPresetPrompt(title: "Face ID Failure", prompt: "Face ID is disabled. Check if the TrueDepth camera system (Dot Projector, IR Camera, Flood Illuminator) is reporting hardware issues.", category: "System"),
        DiagnosticPresetPrompt(title: "Jailbreak / Security", prompt: "Run a deep scan for any unauthorized system modifications or indicators of a compromised sandbox.", category: "Security"),
        DiagnosticPresetPrompt(title: "Thermal Throttling", prompt: "Is my CPU speed being capped? Show me the current thermal state and 'T-Hot' sensor readings.", category: "System"),
        DiagnosticPresetPrompt(title: "Kernel Panic Log", prompt: "My phone restarted. Help me decode the 'panic-full' log to find the driver or kext that caused the crash.", category: "System"),
        DiagnosticPresetPrompt(title: "RAM Pressure Test", prompt: "Check if the system is frequently killing apps due to low memory. What is the current 'compressor' swap usage?", category: "System"),
        DiagnosticPresetPrompt(title: "Disk I/O Latency", prompt: "The interface feels laggy. Measure the SSD read/write speeds and check for NAND wear leveling errors.", category: "System"),
        DiagnosticPresetPrompt(title: "GPU Shader Load", prompt: "Check the GPU utilization during gaming. Is the frame rate drop caused by thermal throttling or driver overhead?", category: "System"),
        DiagnosticPresetPrompt(title: "Launchd Daemon Hang", prompt: "My phone is stuck on the Apple logo for minutes. Which launch daemon is timing out during the boot sequence?", category: "System"),
        DiagnosticPresetPrompt(title: "Sandbox Violation", prompt: "An app is requesting unusual entitlements. Audit the TCC (Transparency, Consent, and Control) database for anomalies.", category: "Security"),

        // Professional / Repair Shop
        DiagnosticPresetPrompt(title: "Pre-Repair Audit", prompt: "Generate a full pre-repair diagnostic report covering Display, Battery, Face ID, and all sensors.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "IMEI Blacklist Check", prompt: "Check this IMEI against global databases to see if it is reported stolen or has a financial lien.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Carrier Lock Status", prompt: "Identify the original carrier of this device and check if it is officially unlocked.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Refurbished Part Detect", prompt: "Scan the device for non-genuine parts, specifically checking the Screen, Battery, and Camera serial numbers.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Water Damage Sensor", prompt: "Analyze the humidity and liquid contact indicator (LCI) sensor history if available in logs.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "GSX History Audit", prompt: "Can we find any previous repair history for this serial number in the global service exchange records?", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Panic Log 'Prereq'", prompt: "Search for specific hardware strings like 'SMC' or 'I2C' in the panic logs to identify faulty internal cables.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Depth Sensor Calibration", prompt: "After a screen swap, the proximity sensor is acting up. How do I recalibrate the IR depth map?", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Wireless IC Reball", prompt: "WiFi is grayed out. Is this consistent with a cracked solder joint on the motherboard wireless IC?", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "Device Grading", prompt: "Based on the internal health and external condition photos, provide an estimated resale grade (A/B/C).", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "LiDAR Point Cloud", prompt: "The 3D scanning is distorted. Help me visualize the raw LiDAR point cloud to check for sensor alignment issues.", category: "Repair Shop"),
        DiagnosticPresetPrompt(title: "TrueDepth IR Matrix", prompt: "Face ID 'Move Higher' error. Inspect the IR camera feed for missing dot projector points.", category: "Repair Shop"),
    ] + (1...350).map { i in
        let categories = ["Display", "Battery", "Connectivity", "Audio", "System", "Security", "Camera", "Sensors", "Storage", "Network", "Diagnostics", "Repair", "Performance", "Optimization"]
        let category = categories[i % categories.count]

        let technicalPrompts = [
            "Analyze the I/O metrics for the \(category) subsystem and identify any abnormal latency spikes.",
            "Compare the current \(category) performance against the baseline specifications for this iPhone model.",
            "Scan the system logs for any 'SIGABRT' or 'SIGSEGV' errors related to \(category) services.",
            "Verify the firmware integrity of the \(category) controller and check for pending security patches.",
            "Run a stress test on the \(category) hardware and monitor the thermal response curve.",
            "Check for any resource leaks in the \(category) background daemons.",
            "Audit the permission stack for all third-party apps accessing \(category) data.",
            "Evaluate the power consumption of the \(category) module in idle vs. active states.",
            "Identify any hardware interrupts that are causing excessive wake-ups in the \(category) stack.",
            "Provide a comprehensive health score for the \(category) component based on recent diagnostic runs.",
            "Trace the IPC (Inter-Process Communication) calls for the \(category) manager to find deadlocks.",
            "Benchmark the throughput of the \(category) bus and compare it to theoretical maximums.",
            "Examine the \(category) register states for any bit-flips or hardware registers stuck high.",
            "Map the thermal dissipation patterns when the \(category) unit is under 100% load.",
            "Analyze the entropy of the \(category) subsystem to detect potential cryptographic weaknesses."
        ]

        return DiagnosticPresetPrompt(
            title: "\(category) Technical Analysis \(i)",
            prompt: technicalPrompts[i % technicalPrompts.count],
            category: category
        )
    }
}
