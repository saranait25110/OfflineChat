//
//  ChatTableViewCell.swift
//  OfflineChat
//
//  Created by Saranya iOS on 03/09/25.
//
import UIKit

class ChatTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let messageLabel = UILabel()
    private let senderLabel = UILabel()
    private let timestampLabel = UILabel()
    private let messageContainer = UIView()
    
    // MARK: - Properties
    static let reuseIdentifier = "ChatTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Configure message container
        messageContainer.layer.cornerRadius = 12
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageContainer)
        
        // Configure sender label
        senderLabel.font = .systemFont(ofSize: 12, weight: .medium)
        senderLabel.textColor = .secondaryLabel
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.addSubview(senderLabel)
        
        // Configure message label
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.addSubview(messageLabel)
        
        // Configure timestamp label
        timestampLabel.font = .systemFont(ofSize: 10)
        timestampLabel.textColor = .tertiaryLabel
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.addSubview(timestampLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Message container constraints
            messageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Sender label constraints
            senderLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            senderLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 12),
            senderLabel.trailingAnchor.constraint(lessThanOrEqualTo: messageContainer.trailingAnchor, constant: -12),
            
            // Message label constraints
            messageLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -12),
            
            // Timestamp label constraints
            timestampLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            timestampLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -12),
            timestampLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Configuration
    func configure(with message: ChatMessage, isMyMessage: Bool, currentUserName: String) {
        messageLabel.text = message.content
        senderLabel.text = message.senderName
        timestampLabel.text = message.formattedTime
        
        if isMyMessage {
            // My message - right aligned, blue background
            messageContainer.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            senderLabel.textColor = .white.withAlphaComponent(0.8)
            timestampLabel.textColor = .white.withAlphaComponent(0.6)
            
            // Update constraints for right alignment
            updateConstraintsForMyMessage()
        } else {
            // Other's message - left aligned, gray background
            messageContainer.backgroundColor = .systemGray5
            messageLabel.textColor = .label
            senderLabel.textColor = .secondaryLabel
            timestampLabel.textColor = .tertiaryLabel
            
            // Update constraints for left alignment
            updateConstraintsForOtherMessage()
        }
    }
    
    private func updateConstraintsForMyMessage() {
        // Remove existing constraints
        messageContainer.constraints.forEach { messageContainer.removeConstraint($0) }
        contentView.constraints.forEach { constraint in
            if constraint.firstItem === messageContainer || constraint.secondItem === messageContainer {
                contentView.removeConstraint(constraint)
            }
        }
        
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            messageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageContainer.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])
        
        setupConstraints()
    }
    
    private func updateConstraintsForOtherMessage() {
        // Remove existing constraints
        messageContainer.constraints.forEach { messageContainer.removeConstraint($0) }
        contentView.constraints.forEach { constraint in
            if constraint.firstItem === messageContainer || constraint.secondItem === messageContainer {
                contentView.removeConstraint(constraint)
            }
        }
        
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            messageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])
        
        setupConstraints()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        senderLabel.text = nil
        timestampLabel.text = nil
    }
}
