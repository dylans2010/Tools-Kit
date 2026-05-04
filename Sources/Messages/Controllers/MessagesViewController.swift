import UIKit
import Messages
import SwiftUI
import os.log

private let extensionLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.dylans2010.ToolsKit.messages", category: "MessagesExtension")

class MessagesViewController: MSMessagesAppViewController {

    private var swiftUIView: UIHostingController<MessagesRootView>?
    private var activePayload: MessagePayload?

    override func viewDidLoad() {
        super.viewDidLoad()
        let bundleID = Bundle.main.bundleIdentifier ?? "(nil)"
        os_log("MessagesViewController viewDidLoad – bundle identifier: %{public}@", log: extensionLog, type: .info, bundleID)
        setupSwiftUI()
    }

    // MARK: - Conversation Handling

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        os_log("MessagesViewController willBecomeActive", log: extensionLog, type: .info)
        // Setup/re-setup UI whenever we become active to ensure we have the latest conversation state
        presentRootView(with: conversation)
    }

    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
        os_log("MessagesViewController didResignActive", log: extensionLog, type: .info)
        // Cleanup or save state if needed when resigning active
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        presentRootView(with: conversation)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        super.didStartSending(message, conversation: conversation)
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        super.didCancelSending(message, conversation: conversation)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
    }

    // MARK: - UI Setup

    private func setupSwiftUI() {
        // Initial setup, actual view will be updated in presentRootView
        os_log("MessagesViewController SwiftUI bridge initialized", log: extensionLog, type: .info)
    }

    private func presentRootView(with conversation: MSConversation) {
        activePayload = MessageManager.shared.decodePayload(from: conversation.selectedMessage)

        let rootView = MessagesRootView(
            activePayload: activePayload,
            onSendMessage: { [weak self] message in
                self?.activeConversation?.insert(message, completionHandler: nil)
                self?.requestPresentationStyle(.compact)
            },
            onActivePayloadChanged: { [weak self] payload in
                self?.activePayload = payload
                if payload != nil {
                    self?.requestPresentationStyle(.expanded)
                }
            }
        )

        if let existing = swiftUIView {
            existing.rootView = rootView
        } else {
            let hostingController = UIHostingController(rootView: rootView)
            addChild(hostingController)
            hostingController.view.frame = view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
            swiftUIView = hostingController
        }
    }
}
