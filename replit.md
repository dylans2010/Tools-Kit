# Tools Kit

A comprehensive iOS/macOS multi-tool application built with SwiftUI, targeting iOS 17+ and macOS 12+.

## Architecture

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Package Manager**: Swift Package Manager (Package.swift)
- **Platforms**: iOS 17+, macOS 12+

## Project Structure

```
Sources/
  AppEntry.swift              - @main entry point (ToolsKitApp)
  Views/
    ContentView.swift         - Root view with auth/mode routing
    Auth/                     - Login/signup views
    Dashboard/                - DashboardView.swift
    Tools/                    - 100+ individual tool views
    Workspace/                - Email, Notes, Tasks, Calendar, Spreadsheets, Slides, Meet
    Music/                    - Music player views
    Shared/                   - Reusable components
  Models/
    ToolRegistry.swift        - Registers all ~140 tools
    Tool.swift                - Tool protocol
    AppModel.swift            - App-level state
    PrivateModeManager.swift
    WeatherModels.swift
    Note.swift
  Backend/
    Network/                  - CertificatePinningManager, NetworkClient
    Services/                 - AIService, AppwriteClient, AuthService, etc.
    Tools/                    - Backend logic for each tool (AIChat, APITester, etc.)
  Components/                 - Reusable UI components
  Features/                   - Feature-specific modules
  Mail/                       - Email client (MailCore2/IMAP/SMTP)
  Music/                      - Music backend services
  Workspace/                  - Workspace backend services
```

## Application Modes

1. **Dashboard** - 140+ utility tools across categories: Basic, Advanced, Network, Privacy
2. **Workspace** - Productivity suite: Email, Notebooks, Tasks, Calendar, Spreadsheets, Slides, Meet
3. **Music Mode** - Music player, library, playlists, lyrics, radio, WiFi file transfer
4. **Workouts Mode** - Fitness tracker, nutrition, AI workout planning, HealthKit integration

## Key Dependencies (Package.swift)

- **Appwrite SDK** (`sdk-for-apple`, v16.1.0+) - Backend-as-a-Service: auth, database, cloud sync
- **MailCore2** - IMAP/SMTP email protocol support
- **Daily.co SDK** (`daily-client-ios`, v0.37.0+) - Real-time video/audio calls

## Tool Categories (~140 tools registered in ToolRegistry.swift)

**Basic Tools**: Calculator, Unit Converter, Currency Converter, Timezone Converter, QR Code, Password Generator, Notes Formatter, Clipboard Manager, Color Picker, Base64, File Size, Translation, Word Counter, Text Formatter, Password Strength, Metadata Remover, Document Scanner, Camera Color Picker, Live Text, Storage Analyzer, Battery Analytics, Device Info, File Type Inspector, Metadata Viewer, Audio Converter, Smart Autofill, Habit Tracker, Focus Tracker, Markdown Preview, File Management, YAML Converter, cURL Converter, HTML Entity, URL Parser, HMAC Generator, UUID Generator, CSV Converter, Placeholder Generator, Aspect Ratio, Percent Change, Math Suite, Prime Factor, Morse Code, NATO Alphabet

**Advanced Tools**: JSON Formatter, API Tester, Regex Tester, Code Formatter, Log Viewer, Text Summarizer, Translation (Extended), Notes, File Converter, PDF Tools, OCR, Image Processor, Meeting Notes, Daily Call, JWT Decoder, Hash Generator, Diff Checker, XML Formatter, SQL Formatter, Webhook Tester, Secure Notes, Encryption, IP Info, DNS Lookup, Port Checker, Website Screenshot, Link Preview, HTTP Inspector, Text Rewriter, Code Explainer, Prompt Generator, Email Generator, Idea Generator, Weather, AI Chat, Maps, Object Detection, Perspective Corrector, ID Classifier, Network Speed, Video Compressor, Context Summarizer, Reasoning, Forms, Code Debugger, Reminder Generator, Schema Generator, Projects

**Network Tools**: DoH (DNS over HTTPS), IP Intelligence, Connection Inspector, Endpoint Tester, Secure Router, Network Profiler, WebSocket Inspector, TLS Inspector, Port Scanner, Token Inspector, File Integrity, Safe Browsing

**Privacy Tools**: Encrypted Vault, Tracker Blocker, Temporary Identity, Secure File Sender, Link Sanitizer, Permission Audit, Clipboard Monitor

## AI Integration

Supports multiple AI providers via configurable backends:
- OpenRouter, OpenAI, Anthropic, Gemini, Mistral

## Backend Services

- **Appwrite**: Auth (OAuth), user database, cloud sync
- **Vision Framework**: OCR, document scanning, object detection
- **AVFoundation**: Audio playback engine
- **HealthKit**: Fitness data sync
- **Network.framework**: Low-level network tools
- **Certificate Pinning**: Secure network communications

## Environment Variables (.env.example)

- `GOOGLE_WEB_CLIENT_ID/SECRET/PROJECT_ID` - Google OAuth
- `GOOGLE_CLIENT_ID`, `GOOGLE_OAUTH_REDIRECT_URI` - App-side Google auth
- `APPWRITE_MAIL_CONFIG_URL/BEARER` - Mail OAuth config endpoint

## Important Notes

- This is a **native iOS/macOS app** — it cannot be run as a web preview in Replit.
- The Replit environment (Linux x86_64) does not have a working Swift toolchain capable of building iOS targets.
- Development, building, and testing should be done in Xcode on macOS.
- The Replit environment is used for code editing, reviewing, and version control only.
- Total codebase: ~625 Swift files, ~75,700 lines of code.
