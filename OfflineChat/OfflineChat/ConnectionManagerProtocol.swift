//
//  ConnectionManagerProtocol.swift
//  OfflineChat
//
//  Created by Saranya iOS on 03/09/25.
//

import Foundation

// MARK: - Connection Manager Protocol
protocol ConnectionManagerDelegate: AnyObject {
    
    /// Called when a new/edit/delete message is received
    func didReceiveMessage(_ wrapper: MessageWrapper)

    
//     Called when connected peers list changes
    func didUpdateConnectedPeers(_ peers: [String])
    
    // Called when a peer sends an invitation
    func didReceiveInvitation(from peer: String, invitationHandler: @escaping (Bool) -> Void)
    
    // Called when an error occurs
    func didFailWithError(_ error: ConnectionError)
}

// MARK: - Connection Errors
enum ConnectionError: Error, LocalizedError {
    case bluetoothUnavailable
    case wifiUnavailable
    case sendMessageFailed
    case connectionTimeout
    case peerDisconnected
    case invalidData
    case underlying(Error)   // capture real errors
    
    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth is not available"
        case .wifiUnavailable:
            return "WiFi is not available"
        case .sendMessageFailed:
            return "Failed to send message"
        case .connectionTimeout:
            return "Connection timed out"
        case .peerDisconnected:
            return "Peer disconnected unexpectedly"
        case .invalidData:
            return "Invalid data received"
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}
