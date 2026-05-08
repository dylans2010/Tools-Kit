import Foundation

@MainActor
public struct SDKIntegrationValidator {
    public static func validateAll() async throws {
        print("🚀 Starting WorkspaceSDK Integration Validation...")

        let sdk = WorkspaceSDK.shared

        // 1. Kernel Boot
        print("Step 1: Booting Kernel...")
        await sdk.initialize()
        guard sdk.isInitialized else {
            throw SDKError.executionFailed(reason: "SDK failed to initialize")
        }
        print("✅ Kernel Booted")

        // 2. Service Injection
        print("Step 2: Validating Service Injection...")
        let registeredServices = sdk.kernel.healthCheck().registeredServices
        if registeredServices < 5 {
            throw SDKError.executionFailed(reason: "Insufficient services registered: \(registeredServices)")
        }
        print("✅ Service Injection Validated (\(registeredServices) services)")

        // 3. Permission System
        print("Step 3: Validating Permissions...")
        sdk.security.grantPermission("mail.send")
        sdk.security.grantPermission("notebooks.write")
        guard sdk.security.isScopeAuthorized("mail.send") else {
            throw SDKError.permissionDenied(scope: "mail.send")
        }
        print("✅ Permission System Validated")

        // 4. Feature Logic & Persistence (Notebooks)
        print("Step 4: Validating Notebooks Feature & Persistence...")
        let title = "Validation Notebook \(UUID().uuidString)"
        let notebook = try sdk.notebooks.createNotebook(title: title)
        let fetched = sdk.notebooks.getNotebook(id: notebook.id)
        guard fetched?.title == title else {
            throw SDKError.storageError(reason: "Notebook persistence failed")
        }
        print("✅ Notebooks Feature Validated")

        // 5. Event Bus
        print("Step 5: Validating Event Bus...")
        var eventReceived = false
        let expectation = sdk.events.subscribe(channel: "validation") { _ in
            eventReceived = true
        }
        sdk.events.publish(SDKBusEvent(channel: "validation", name: "test"))

        // Small delay for async event delivery
        try? await Task.sleep(nanoseconds: 100_000_000)

        guard eventReceived else {
            throw SDKError.executionFailed(reason: "Event Bus failed to deliver event")
        }
        expectation.cancel()
        print("✅ Event Bus Validated")

        // 6. API Router
        print("Step 6: Validating API Router...")
        let response = try await sdk.api("/sdk/health")
        guard response.status == .success else {
            throw SDKError.executionFailed(reason: "API Router failed health check")
        }
        print("✅ API Router Validated")

        print("🎉 WorkspaceSDK Integration Validation PASSED!")
    }
}
