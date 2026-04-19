import Foundation

#if canImport(CallKit) && os(iOS)
import CallKit

final class CallKitProvider: NSObject {
    let provider: CXProvider

    override init() {
        let configuration = CXProviderConfiguration(localizedName: "Tools Meet")
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.includesCallsInRecents = false
        provider = CXProvider(configuration: configuration)
        super.init()
    }
}
#else
final class CallKitProvider {}
#endif
