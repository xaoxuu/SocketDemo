//
//  SocketManager.swift
//  SocketDemo
//
//  Created by xaoxuu on 2018/7/5.
//  Copyright © 2018 Titan Studio. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import AXKit

class SocketManager: NSObject, GCDAsyncSocketDelegate {

    public static let shared = SocketManager()
    lazy var asyncSocket: GCDAsyncSocket = {
        
        return GCDAsyncSocket.init(delegate: self, delegateQueue: DispatchQueue.init(label: "com.xaoxuu.socket"))
    }()
    var clientSockets = [GCDAsyncSocket]()
    var host = ""
    var port = UInt16(5528)
    
    private var connectedHosts = [String:String]()
    
    typealias ConnectCallback = (SocketCharacter, String, Error?) -> Void
    typealias DisconnectCallback = (SocketCharacter, String?) -> Void
    typealias ReceiveMessageCallback = (String?, String?) -> Void
    
    var character = SocketCharacter.server
    
    var block_onConnect: ConnectCallback?
    var block_onDisconnect: DisconnectCallback?
    var block_onReceiveMessage: ReceiveMessageCallback?
    
    
    func onConnect(_ callback: @escaping ConnectCallback) {
        block_onConnect = callback
    }
    
    func onDisconnect(_ callback: @escaping DisconnectCallback) {
        block_onDisconnect = callback
    }
    func onReceiveMessage(_ callback: @escaping ReceiveMessageCallback) {
        block_onReceiveMessage = callback
    }
    
    
    func startServer(host: String) {
        character = SocketCharacter.server
        self.host = host
        if asyncSocket.isConnected {
            asyncSocket.disconnect()
        }
        do {
            try asyncSocket.accept(onPort: port)
            if let f = self.block_onConnect {
                f(self.character, host, nil)
            }
        } catch {
            debugPrint(error)
            if let f = self.block_onConnect {
                f(self.character, host, error)
            }
        }
        
    }
    func connectServer(host: String) {
        character = SocketCharacter.client
        self.host = host
        if asyncSocket.isConnected {
            asyncSocket.disconnect()
        }
        do {
            try asyncSocket.connect(toHost: host, onPort: port)
        } catch {
            debugPrint(error)
            if let f = self.block_onConnect {
                f(self.character, host, error)
            }
        }
    }
    func sendData(data: Data) {
        asyncSocket.write(data, withTimeout: -1, tag: 0)
    }
    
    // MARK: - delegate
    // 在读取数据之前 服务端还需要监听 客户端有没有写入数据
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        debugPrint("sock: \(sock), newSocket: \(newSocket)")
        clientSockets.append(newSocket)
        if let h = newSocket.connectedHost {
            connectedHosts[NSString.pointerDescription()(newSocket)] = h
        }
//        let key = NSString.pointerDescription()(newSocket)
//        if let ip = newSocket.connectedHost {
//            ips[key] = ip
//        }
        DispatchQueue.main.async {
            if let f = self.block_onConnect {
                if let ip = newSocket.connectedHost {
                    f(self.character, ip, nil)
                } else {
                    f(self.character, "", nil)
                }
            }
        }
        // 监听客户端是否写入数据
        // timeOut: -1 暂时不需要 超时时间  tag暂时不需要 传0
        newSocket.readData(withTimeout: -1, tag: 0)
    }
    
    // 服务器读取客户端发送数据
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let dataStr = String.init(data: data, encoding: String.Encoding.utf8)
        DispatchQueue.main.async {
            if let f = self.block_onReceiveMessage {
                f(sock.connectedHost, dataStr)
            }
        }
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        debugPrint("sock: \(sock) connect to: \(host) port: \(port)")
        DispatchQueue.main.async {
            if let f = self.block_onConnect {
                f(self.character, host, nil)
            }
        }
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        
        let host = connectedHosts[NSString.pointerDescription()(sock)]
        if let h = host {
            connectedHosts.removeValue(forKey: h)
        }
        if let idx = clientSockets.index(of: sock) {
            clientSockets.remove(at: idx)
        }
        DispatchQueue.main.async {
            if let f = self.block_onDisconnect {
                f(self.character, host)
            }
        }
        
        // 服务器关闭
        if sock == asyncSocket {
            for sock in clientSockets {
                sock.disconnect()
            }
        }
        
    }
    
}
