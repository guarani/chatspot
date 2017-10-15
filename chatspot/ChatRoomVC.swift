//
//  ChatRoomVC.swift
//  chatspot
//
//  Created by Eden on 10/10/17.
//  Copyright © 2017 g7. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Firebase

class ChatRoomVC: UIViewController {
	@IBOutlet weak var containerView: UIView!

	@IBOutlet weak var tableView: UITableView!
	
	@IBOutlet weak var addPhotoButton: UIButton!
	
	@IBOutlet weak var addEmojiButton: UIButton!
	
	@IBOutlet weak var messageTextField: UITextField!
	
	@IBOutlet weak var sendMessageButton: UIButton!
	
    @IBOutlet weak var chatRoomNameLabel: UILabel!
    
    @IBOutlet weak var chatRoomMemberCountLabel: UILabel!
    
    @IBOutlet weak var containerTopMarginConstraint: NSLayoutConstraint!
	
	var messages: [Message1] = [Message1]()
    var chatRoom: ChatRoom1!
	var initialY: CGFloat!
    
    var observer: UInt!

    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.delegate = self
		tableView.dataSource = self
		tableView.estimatedRowHeight = 50
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.separatorStyle = .none

		setUpKeyboardNotifications()
        
        chatRoomNameLabel.text = chatRoom.name
//        chatRoomMemberCountLabel.text = chatRoom.userCount
		
		setUpUI()
        self.startObservingMessages()
    }
    
    private func startObservingMessages() {
        
        observer = ChatSpotClient.observeNewMessages(roomId: chatRoom.guid, success: { (message: Message1) in
            print(message)
            
            self.messages.append(message)
            self.reloadTable()
            
        }, failure: {
            print("Error")
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        ChatSpotClient.removeObserver(handle: observer)
    }
    
    
	
	func setUpUI(){
		addPhotoButton.changeImageViewTo(color: .lightGray)
		addEmojiButton.changeImageViewTo(color: .lightGray)
		messageTextField.autoresizingMask = .flexibleWidth
		
	}
	
	func setUpKeyboardNotifications(){
        
        initialY = containerTopMarginConstraint.constant
        
		NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillShow, object: nil, queue: OperationQueue.main) { (notification: Notification) in
			let frame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
			let keyboardHeight = frame.size.height
            
            self.containerTopMarginConstraint.constant = self.initialY - keyboardHeight
            
            let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
            let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
            
            UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: [UIViewAnimationOptions(rawValue: UInt(curve))], animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            
		}
        
		NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            
            self.containerTopMarginConstraint.constant = self.initialY
            
            let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
            let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
            
            UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: [UIViewAnimationOptions(rawValue: UInt(curve))], animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
		}
	}
	
	
	@IBAction func didTapAwayFromKeyboard(_ sender: UITapGestureRecognizer) {
        
		view.endEditing(true)
	}
    
    @IBAction func onSendMessage(_ sender: UIButton) {
        if !(messageTextField.text?.isEmpty)! {
            let tm = Message1(roomId: chatRoom.guid, message: messageTextField.text!,
                              name: Auth.auth().currentUser!.displayName!)
            
            ChatSpotClient.sendMessage(message: tm, roomId: chatRoom.guid, success: {
                messageTextField.text = ""
                print("message sent!")
                
            }, failure: {
                print("message sending failed")
            })
        }
        
    }
}


// TableView Methods

extension ChatRoomVC: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell") as! ChatMessageCell
		//set properties of cell
		cell.message = messages[indexPath.row]
		cell.selectionStyle = UITableViewCellSelectionStyle.none
		//TODO: set cell delegate

		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count
	}
    
    func reloadTable(){
        self.tableView.reloadData()
        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
	
}

extension ChatRoomVC: UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBAction func didTapAddPhoto(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion:nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        
        // if it's a photo from the library, not an image from the camera
        //        if let referenceURL = info[UIImagePickerControllerReferenceURL] as? URL {
        
        //        } else {
        //let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        //        }
        
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
    
}

extension ChatRoomVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        self.messageTextField.resignFirstResponder()

    }
    
}

extension UIImageView {
	func changeToColor(color: UIColor){
		self.image = self.image!.withRenderingMode(.alwaysTemplate)
		self.tintColor = color
	}
}

extension UIButton {
	func changeImageViewTo(color: UIColor){
		let orginalImage = self.imageView?.image
		let newColorImage = orginalImage?.withRenderingMode(.alwaysTemplate)
		self.setImage(newColorImage, for: .normal)
		self.tintColor = color
	}
}
