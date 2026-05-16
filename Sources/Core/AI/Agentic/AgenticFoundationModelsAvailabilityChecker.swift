import Foundation
import os

#if canImport(FoundationModels)
import FoundationModels
#endif

final class AgenticFoundationModelsAvailabilityChecker: Sendable {
    static let shared = AgenticFoundationModelsAvailabilityChecker()

    private let logger = Logger(subsystem: "com.toolskit.agentic", category: "availability")

    private init() {}

    var isFrameworkAvailable: Bool {
        #if canImport(FoundationModels)
        return true
        #else
        return false
        #endif
    }

    func checkFullAvailability() async -> FoundationModelsStatus {
        logger.info("Checking Foundation Models availability...")

        let frameworkAvailable = isFrameworkAvailable

        guard frameworkAvailable else {
            let status = FoundationModelsStatus(
                isFrameworkAvailable: false,
                isRuntimeAvailable: false,
                isSessionReady: false,
                diagnosticMessage: "FoundationModels framework is not available on this platform. Requires iOS 26.0+ / macOS 26.0+."
            )
            logger.warning("Framework not available")
            return status
        }

        let runtimeAvailable = await checkRuntimeAvailability()

        guard runtimeAvailable else {
            let status = FoundationModelsStatus(
                isFrameworkAvailable: true,
                isRuntimeAvailable: false,
                isSessionReady: false,
                diagnosticMessage: "FoundationModels framework is available but runtime model is not accessible. Ensure the device supports on-device Foundation Models."
            )
            logger.warning("Runtime not available")
            return status
        }

        let sessionReady = await checkSessionReadiness()

        let message: String
        if sessionReady {
            message = "Foundation Models fully available. Framework loaded, runtime accessible, session ready."
        } else {
            message = "Foundation Models framework and runtime available, but session initialization encountered issues."
        }

        let status = FoundationModelsStatus(
            isFrameworkAvailable: true,
            isRuntimeAvailable: runtimeAvailable,
            isSessionReady: sessionReady,
            diagnosticMessage: message
        )

        logger.info("Availability check complete: framework=\(frameworkAvailable), runtime=\(runtimeAvailable), session=\(sessionReady)")
        return status
    }

    private func checkRuntimeAvailability() async -> Bool {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, *) else {
            return false
        }
        do {
            let session = LanguageModelSession()
            _ = session
            return true
        }
        #else
        return false
        #endif
    }

    private func checkSessionReadiness() async -> Bool {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, *) else {
            return false
        }
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: "ping")
            return !response.content.isEmpty
        } catch {
            logger.error("Session readiness check failed: \(error.localizedDescription)")
            return false
        }
        #else
        return false
        #endif
    }
}
