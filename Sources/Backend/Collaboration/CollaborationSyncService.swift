import Foundation
import MultipeerConnectivity
import Combine
import UIKit

/// Handles real-time peer-to-peer synchronization for collaboration spaces.
final class CollaborationSyncService: NSObject, ObservableObject {
    static let shared = CollaborationSyncService()

    @Published var connectedPeers: [MCPeerID] = []
    @Published var isAdvertising = false
    @Published var isBrowsing = false

    private let serviceType = "toolskit-collab"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self

        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
    }

    func start() {
        advertiser?.startAdvertisingPeer()
        browser?.startBrowsingForPeers()
        isAdvertising = true
        isBrowsing = true
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        isAdvertising = false
        isBrowsing = false
    }

    func syncSpace(_ space: CollaborationSpace) {
        guard let session = session, !connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(space)
            try session.send(data, toPeers: connectedPeers, with: .reliable)
        } catch {
            print("Sync error: \(error.localizedDescription)")
        }
    }
}

extension CollaborationSyncService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let space = try? JSONDecoder().decode(CollaborationSpace.self, from: data) {
            DispatchQueue.main.async {
                CollaborationManager.shared.updateReceivedSpace(space)
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension CollaborationSyncService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext data: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // In production, we would show a prompt to the user
        // For this build, we accept but log the connection for transparency
        print("Received invitation from \(peerID.displayName). Automatically accepting for local sync.")
        invitationHandler(true, session)
    }
}

extension CollaborationSyncService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
