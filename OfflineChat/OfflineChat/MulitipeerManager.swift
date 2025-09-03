//
//  MultipeerManager.swift
//  OfflineChat
//
//  Created by Saranya iOS on 03/09/25.
//

import Foundation
import MultipeerConnectivity
import Combine

// MARK: - MultipeerConnectivity Manager
class MultipeerManager: NSObject, ObservableObject {
    
   
    weak var delegate: ConnectionManagerDelegate?
    
    private let serviceType = "offline-chat"
    private let myPeerID: MCPeerID
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    
    
    @Published var connectedPeers: [String] = []
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var connectionState: ConnectionState = .disconnected
    
    // MARK: - Connection State
    enum ConnectionState {
        case disconnected
        case advertising
        case browsing
        case connecting
        case connected
    }
    
    // MARK: - Initialization
    override init() {
        
        // Peer ID = device name
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
        
        // Secure session
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        
        serviceBrowser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: serviceType
        )
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
    }
    
    // MARK: - Public Methods
    func startHosting() {
        stopBrowsing()
        serviceAdvertiser.startAdvertisingPeer()
        isAdvertising = true
        connectionState = .advertising
    }
    
    func startBrowsing() {
        stopHosting()
        serviceBrowser.startBrowsingForPeers()
        isBrowsing = true
        connectionState = .browsing
    }
    
    func stopHosting() {
        serviceAdvertiser.stopAdvertisingPeer()
        isAdvertising = false
        if connectionState == .advertising { connectionState = .disconnected }
    }
    
    func stopBrowsing() {
        serviceBrowser.stopBrowsingForPeers()
        isBrowsing = false
        if connectionState == .browsing { connectionState = .disconnected }
    }
    
    /// Send a wrapper (new/edit/delete) to all peers
    func send(_ wrapper: MessageWrapper) {
        guard !session.connectedPeers.isEmpty else {
            print("No connected peers to send")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(wrapper)
            print("Sending data to peers: \(session.connectedPeers.map { $0.displayName })")
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Send failed: \(error)")
        }
    }


    
    func disconnect() {
        session.disconnect()
        stopHosting()
        stopBrowsing()
        connectionState = .disconnected
        updateConnectedPeers()
    }
    
    // MARK: - Private Methods
    private func updateConnectedPeers() {
        let peerNames = session.connectedPeers.map { $0.displayName }
        connectedPeers = peerNames
        delegate?.didUpdateConnectedPeers(peerNames)
        
        if !peerNames.isEmpty {
            connectionState = .connected
        } else if !isAdvertising && !isBrowsing {
            connectionState = .disconnected
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            print("Peer \(peerID.displayName) changed state: \(state.rawValue)")
            self.updateConnectedPeers()
            if state == .notConnected {
                self.delegate?.didFailWithError(.peerDisconnected)
            }
        }
    }
    

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Received data from \(peerID.displayName)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let wrapper = try decoder.decode(MessageWrapper.self, from: data)
            DispatchQueue.main.async {
                self.delegate?.didReceiveMessage(wrapper)
            }
        } catch {
            print("Failed to decode wrapper: \(error)")
            DispatchQueue.main.async {
                self.delegate?.didFailWithError(.invalidData)
            }
        }
    }


    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream: \(streamName) from \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Started receiving resource: \(resourceName) from \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            print("Error receiving resource: \(error)")
        } else {
            print("Finished receiving resource: \(resourceName)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.delegate?.didReceiveInvitation(from: peerID.displayName) { [weak self] accept in
                invitationHandler(accept, accept ? self?.session : nil)
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to advertise: \(error)")
        DispatchQueue.main.async {
            self.isAdvertising = false
            self.connectionState = .disconnected
            self.delegate?.didFailWithError(.bluetoothUnavailable)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async { self.updateConnectedPeers() }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to browse: \(error)")
        DispatchQueue.main.async {
            self.isBrowsing = false
            self.connectionState = .disconnected
            self.delegate?.didFailWithError(.wifiUnavailable)
        }
    }
}
