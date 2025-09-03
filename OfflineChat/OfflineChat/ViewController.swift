//
//  ViewController.swift
//  OfflineChat
//
//  Created by Saranya iOS on 03/09/25.
//

import UIKit


class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var hostButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var messageInputBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    private var messages: [ChatMessage] = []
    private var multipeerManager = MultipeerManager()
    private let userName = UIDevice.current.name
    private var editingIndex: Int? = nil
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupKeyboardHandling()
        multipeerManager.delegate = self
        updateTableBackground()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }
    
    private func setupUI() {
        updateConnectionStatus("Not connected")
        sendButton.isEnabled = false
        sendButton.setTitle("Send", for: .normal)

        messageTextField.placeholder = "Type a message..."
        messageTextField.borderStyle = .roundedRect
        messageTextField.layer.borderColor = UIColor.gray.cgColor
        messageTextField.layer.borderWidth = 1
        messageTextField.delegate = self

        // Remove background colors initially
        hostButton.backgroundColor = .clear
        joinButton.backgroundColor = .clear

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.keyboardDismissMode = .interactive
        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.reuseIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    private func updateTableBackground() {

        let imageView = UIImageView(image: UIImage(named: "ic_chat"))
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.15 // softer background
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let containerView = UIView(frame: tableView.bounds)
        containerView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.9),
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.9)
        ])

        tableView.backgroundView = containerView
    }


    
    
    private func setupKeyboardHandling() {
        messageTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    // MARK: - Keyboard Handling
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let keyboardHeight = view.bounds.height - frame.origin.y
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        
        UIView.animate(withDuration: duration, delay: 0, options: curve) {
            self.messageInputBottomConstraint.constant = keyboardHeight - self.view.safeAreaInsets.bottom
            self.view.layoutIfNeeded()
        }
        
        scrollToBottom(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func textFieldDidChange() {
        sendButton.isEnabled = !(messageTextField.text?.isEmpty ?? true) && !multipeerManager.connectedPeers.isEmpty
    }
    
    // MARK: - IBActions
    @IBAction func hostButtonTapped(_ sender: UIButton) {
        multipeerManager.startHosting()
        updateHostingState()
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        multipeerManager.startBrowsing()
        updateBrowsingState()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        if let index = editingIndex {
            updateMessage(at: index)
        } else {
            sendMessage()
        }
    }
    
    // MARK: - Private Methods
    private func sendMessage() {
        guard let text = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        let message = ChatMessage(senderName: userName, content: text)
        messages.append(message)
        
        let wrapper = MessageWrapper(action: .new, message: message)
        multipeerManager.send(wrapper)
        
        resetInputUI()
        tableView.reloadData()
//        updateTableBackground()
        scrollToBottom(animated: true)
    }
    
    private func updateMessage(at index: Int) {
        guard let newText = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !newText.isEmpty else { return }
        
        var message = messages[index]
        message.content = newText
        message.isEdited = true
        messages[index] = message
        
        let wrapper = MessageWrapper(action: .edit, message: message)
        multipeerManager.send(wrapper)
        
        resetInputUI()
        tableView.reloadData()
//        updateTableBackground()
        scrollToBottom(animated: true)
    }
    
    private func deleteMessage(at indexPath: IndexPath) {
        var message = messages[indexPath.row]
        message.isDeleted = true
        message.content = ""
        messages[indexPath.row] = message
        
        let wrapper = MessageWrapper(action: .delete, message: message)
        multipeerManager.send(wrapper)
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
//        updateTableBackground()

    }
    
    private func resetInputUI() {
        editingIndex = nil
        messageTextField.text = ""
        sendButton.isEnabled = false
        sendButton.setTitle("Send", for: .normal)
    }
    
    private func scrollToBottom(animated: Bool = false) {
        guard !messages.isEmpty else { return }
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    private func updateConnectionStatus(_ status: String) {
        connectionStatusLabel.text = status
    }
    
    private func updateHostingState() {
        hostButton.setTitle("Hosting...", for: .normal)
        hostButton.backgroundColor = .systemOrange
        hostButton.isEnabled = false
        joinButton.isEnabled = false
        updateConnectionStatus("Hosting - waiting for connections")
    }

    private func updateBrowsingState() {
        joinButton.setTitle("Searching...", for: .normal)
        joinButton.backgroundColor = .systemOrange
        joinButton.isEnabled = false
        hostButton.isEnabled = false
        updateConnectionStatus("Searching for hosts...")
    }

    
    private func resetConnectionButtons() {
        hostButton.setTitle("Host Chat", for: .normal)
        joinButton.setTitle("Join Chat", for: .normal)
//        hostButton.backgroundColor = .systemBlue
//        joinButton.backgroundColor = .systemBlue
        hostButton.isEnabled = true
        joinButton.isEnabled = true
    }

    
    private func showInvitationAlert(from peer: String, invitationHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Chat Invitation",
            message: "\(peer) wants to chat with you",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in invitationHandler(true) })
        alert.addAction(UIAlertAction(title: "Decline", style: .cancel) { _ in invitationHandler(false) })
        present(alert, animated: true)
    }
    
    private func showErrorAlert(_ error: ConnectionError) {
        let alert = UIAlertController(
            title: "Connection Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ConnectionManagerDelegate
extension ViewController: ConnectionManagerDelegate {
    func didReceiveMessage(_ wrapper: MessageWrapper) {
        let message = wrapper.message
        
        switch wrapper.action {
        case .new:
            messages.append(message)
        case .edit:
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = message
            }
        case .delete:
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = message
            }
        }
        
        tableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    
    func didUpdateConnectedPeers(_ peers: [String]) {
        let isConnected = !peers.isEmpty
        sendButton.isEnabled = isConnected && !(messageTextField.text?.isEmpty ?? true)
        
        if isConnected {
            updateConnectionStatus("Connected to: \(peers.joined(separator: ", "))")
            hostButton.isHidden = true
            joinButton.isHidden = true
        } else {
            updateConnectionStatus("No connections")
            hostButton.isHidden = false
            joinButton.isHidden = false
            resetConnectionButtons()
        }
    }

    
    func didReceiveInvitation(from peer: String, invitationHandler: @escaping (Bool) -> Void) {
        showInvitationAlert(from: peer, invitationHandler: invitationHandler)
    }
    
    func didFailWithError(_ error: ConnectionError) {
        showErrorAlert(error)
        resetConnectionButtons()
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? ChatTableViewCell else { return UITableViewCell() }
        
        let message = messages[indexPath.row]
        let isMyMessage = message.senderName == userName
        cell.configure(with: message, isMyMessage: isMyMessage, currentUserName: userName)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 80 }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let message = messages[indexPath.row]
        let isMyMessage = message.senderName == userName
        guard isMyMessage, !message.isDeleted else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                self.startEditingMessage(at: indexPath)
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.deleteMessage(at: indexPath)
            }
            return UIMenu(title: "", children: [edit, delete])
        }
    }
}

// MARK: - Message Editing
extension ViewController {
    private func startEditingMessage(at indexPath: IndexPath) {
        let message = messages[indexPath.row]
        messageTextField.text = message.content
        sendButton.isEnabled = true
        sendButton.setTitle("Update", for: .normal)
        editingIndex = indexPath.row
    }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if sendButton.isEnabled {
            if let index = editingIndex {
                updateMessage(at: index)
            } else {
                sendMessage()
            }
        }
        return true
    }
}
