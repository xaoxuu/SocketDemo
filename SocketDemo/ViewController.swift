//
//  ViewController.swift
//  SocketDemo
//
//  Created by xaoxuu on 2018/7/5.
//  Copyright © 2018 Titan Studio. All rights reserved.
//

import UIKit
import NoticeBoard
import AXKit

enum SocketCharacter: Int {
    case server = 10
    case client = 11
}

class ViewController: UIViewController {

    
    
    @IBOutlet weak var tf_ip: UITextField!
    
    @IBOutlet weak var tf_server: UITextField!
    
    @IBOutlet weak var tf_client: UITextField!
    
    
    @IBOutlet weak var chatView: UIView!
    
    @IBOutlet weak var lb_sendMsg: UILabel!
    
    @IBOutlet weak var tv_msg: UITextView!
    
    @IBOutlet weak var sw_server: UISwitch!
    
    @IBOutlet weak var sw_client: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.init("reload"), object: nil, queue: .main) { (note) in
            self.tf_ip.text = IPAddress.ip()
        }
        
        tf_ip.text = IPAddress.ip()
        tf_server.text = "\(SocketManager.shared.clientSockets.count)个连接"
        tf_client.text = UserDefaults.standard.object(forKey: "ip") as? String
        tf_ip.backgroundColor = UIColor.groupTableViewBackground
        tf_ip.alpha = 0.5
        tf_server.backgroundColor = UIColor.groupTableViewBackground
        tf_server.alpha = 0.5
        tf_client.backgroundColor = UIColor.clear
        
        chatView.isHidden = true
        chatView.alpha = 0
        
        let msg = Notice()
        var item = DispatchWorkItem.init {
            self.chatView.isHidden = true
        }
        
        func reset(sw: UISwitch){
            sw.isEnabled = true
            sw.setOn(false, animated: true)
        }
        func resetTF() {
            UIView.animate(withDuration: 0.5) {
                self.tf_server.backgroundColor = UIColor.groupTableViewBackground
                self.tf_client.isEnabled = true
                self.tf_client.alpha = 1
                self.tf_client.backgroundColor = UIColor.clear
            }
            
        }
        func onConnect(as character: SocketCharacter) {
            UIView.animate(withDuration: 0.5) {
                self.tf_client.isEnabled = false
                self.tf_client.alpha = 0.5
                if character == SocketCharacter.server {
                    self.tf_server.backgroundColor = UIColor.ax_green.light()
                    self.sw_client.isEnabled = false
                    self.lb_sendMsg.text = "向客户端发送消息"
                } else {
                    self.tf_client.backgroundColor = UIColor.ax_green.light()
                    self.sw_server.isEnabled = false
                    self.lb_sendMsg.text = "向服务端发送消息"
                }
            }
        }
        
        func updateState(){
            func showChatView(_ show: Bool){
                UIView.animate(withDuration: 0.5) {
                    if show {
                        self.chatView.isHidden = false
                        self.chatView.alpha = 1
                    } else {
                        self.chatView.alpha = 0
                        self.tv_msg.resignFirstResponder()
                        item.cancel()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
                    }
                }
            }
            let sock = SocketManager.shared
            if sock.character == SocketCharacter.server {
                // 服务端
                self.tf_server.text = "\(SocketManager.shared.clientSockets.count)个连接"
                if SocketManager.shared.clientSockets.count > 0 {
                    showChatView(true)
                } else {
                    showChatView(false)
                }
            } else {
                // 客户端
                if sock.asyncSocket.isConnected {
                    showChatView(true)
                } else {
                    showChatView(false)
                }
            }
        }
        
        tv_msg.ax_adjustFrame(withKeyboard: view)
        SocketManager.shared.onConnect { (character, host, error) in
            if let err = error {
                reset(sw: self.sw_server)
                reset(sw: self.sw_client)
                resetTF()
                NoticeBoard.post(.error, message: err.localizedDescription, duration: 3)
            } else {
                onConnect(as: character)
                updateState()
                NoticeBoard.post(.success, message: "\(host) connected", duration: 3)
            }
        }
        SocketManager.shared.onDisconnect { (character, host) in
            updateState()
            if character == SocketCharacter.server {
                if host == nil {
                    reset(sw: self.sw_server)
                    reset(sw: self.sw_client)
                    resetTF()
                }
                
            } else {
                reset(sw: self.sw_server)
                reset(sw: self.sw_client)
                resetTF()
                
            }
            if let i = host {
                NoticeBoard.post(.warning, message: "\(i) disconnect from server", duration: 3)
            } else if character == SocketCharacter.server {
                NoticeBoard.post(.warning, message: "server closed", duration: 3)
            } else {
                NoticeBoard.post(.error, message: "disconnect from server", duration: 3)
            }
        }
        SocketManager.shared.onReceiveMessage { (host, str) in
            var msg = "receive message"
            if let h = host {
                msg = h + ": "
            }
            if let s = str {
                msg += s
            }
            NoticeBoard.post(.normal, message: msg, duration: 2)
            self.tv_msg.text = str
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func startServer(_ sender: UISwitch) {
        if sender.isOn {
            SocketManager.shared.startServer(host: tf_ip.text!)
        } else {
            // 关闭服务
            SocketManager.shared.asyncSocket.disconnect()
        }
    }
    @IBAction func connectServer(_ sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.set(tf_client.text, forKey: "ip")
            SocketManager.shared.connectServer(host: tf_client.text!)
        } else {
            SocketManager.shared.asyncSocket.disconnect()
        }
    }
    
    @IBAction func send(_ sender: UIButton) {
        if let data = tv_msg.text?.data(using: .utf8) {
            if SocketManager.shared.asyncSocket.isConnected {
                SocketManager.shared.asyncSocket.write(data, withTimeout: -1, tag: 0)
            } else if SocketManager.shared.clientSockets.count > 0 {
                for sock in SocketManager.shared.clientSockets {
                    sock.write(data, withTimeout: -1, tag: 0)
                }
            }
        }
    }
    
    @IBAction func more(_ sender: UIButton) {
        if let url = URL.init(string: (sender.titleLabel?.text)!) {
            UIApplication.shared.openURL(url)
        }
    }
    
}

