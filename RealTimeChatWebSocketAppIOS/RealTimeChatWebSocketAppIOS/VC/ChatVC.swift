//
//  ChatVC.swift
//  RealTimeChatWebSocketAppIOS
//
//  Created by Alif on 13/11/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import UIKit

class ChatVC: UIViewController {
    
    let chatService = ChatService()
    
    @IBOutlet var chatView: UITextView!
    @IBOutlet var messageView: UITextView!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageView.layer.borderColor = UIColor.orange.cgColor
        messageView.layer.borderWidth = 1
        sendButton.layer.borderColor = UIColor.orange.cgColor
        sendButton.layer.borderWidth = 1
        
        chatService.delegate = self
        chatService.connect()
        
        Notification.Name.UIKeyboardWillShow
        Notification.Name.UIKeyboardWillHide
        
        NotificationCenter.default.addObserver(self, selector: #selector(showingKeyBoard), name: NSNotification.Name(rawValue: "UIKeyboardWillShowNotification"), object: nil )
        NotificationCenter.default.addObserver(self, selector: #selector(hidingKeyboard), name: NSNotification.Name(rawValue: "UIKeyboardWillHideNotification"), object: nil )
    }
    
    @IBAction func sendButtonTouched(_ sender: UIButton) {
        guard let message = messageView.text else {
            return
        }
        
        if message.count > 0 {
            setStatus("Sending ...")
            newMessage("ME: "+message)
            chatService.sendMessage(message)
            messageView.text = ""
        }
    }
}

extension ChatVC: ChatServiceDelegate {
    func newMessage(_ message: String) {
        chatView.text = chatView.text.appending("\n \(message)")
        print("newMessage", message)
    }
    
    func setStatus(_ status: String) {
        statusLabel.text = status
    }
}


extension UIViewController {
    @objc func showingKeyBoard(notification: Notification)  {
        if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height {
            self.view.frame.origin.y = -keyboardHeight
        }
    }
    
    @objc func hidingKeyboard() {
        self.view.frame.origin.y = 0
    }
}
