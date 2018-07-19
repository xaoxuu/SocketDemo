//
//  UDPSocket.swift
//  SocketDemo
//
//  Created by xaoxuu on 2018/7/19.
//  Copyright © 2018 Titan Studio. All rights reserved.
//

import UIKit
import CocoaAsyncSocket



class UDPSocket: NSObject, GCDAsyncUdpSocketDelegate {

    public static let shared = UDPSocket()
    let didUpdate = NSNotification.Name.init("broadcast.update")
    lazy var asyncUdpSocket: GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket.init(delegate: self, delegateQueue: DispatchQueue.init(label: "com.xaoxuu.socket"))
    }()
    let broadcastData: Data = {
        let data = "sdfadsfasdfsa".data(using: .utf8)
        return data!
    }()
    var hosts = [String]()
    func broadcastHost() -> String? {
        if let ip = IPAddress.ip() {
            var arr = ip.components(separatedBy: ".")
            arr.removeLast()
            arr.append("255")
            let host = arr.joined(separator: ".")
            return host
        } else {
            return nil
        }
        
    }
//    func lastHostNumber(host: String) -> String {
//        let arr = host.components(separatedBy: ".")
//        var ret = "255"
//        if let h = arr.last {
//            ret = h
//        }
//        return ret
//    }
//    func hostWithLastNumber(num: String) -> String {
//        var arr = broadcastHost().components(separatedBy: ".")
//        arr.removeLast()
//        arr.append(num)
//        let host = arr.joined(separator: ".")
//        return host
//    }
    func safeHost(_ host: String) -> String? {
        let arr = host.components(separatedBy: ".")
        var lastNumber = "255"
        if let h = arr.last {
            lastNumber = h
        }
        
        if let h = broadcastHost() {
            var arr2 = h.components(separatedBy: ".")
            arr2.removeLast()
            arr2.append(lastNumber)
            let hh = arr2.joined(separator: ".")
            return hh
        } else {
            return nil
        }
        
    }
    // MARK: - func
    
    func enableBroadcast(){
        do {
            try asyncUdpSocket.enableBroadcast(true)
        } catch {
            debugPrint(error)
        }
        
    }
    
    func beginReceiving(){
        do {
            try asyncUdpSocket.bind(toPort: kPort)
            enableBroadcast()
            do {
                try asyncUdpSocket.beginReceiving()
            } catch {
                debugPrint(error)
            }
        } catch {
            debugPrint(error)
        }
    }
    
    var broadcasting = false
    func broadcast(_ flag: Bool?){
        if let f = flag {
            broadcasting = f
            broadcast(nil)
        } else if broadcasting == true {
            if let host = broadcastHost() {
                asyncUdpSocket.send(broadcastData, toHost: host, port: kPort, withTimeout: 1000, tag: 1)
                DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                    self.broadcast(nil)
                }
            }
        }
    }
    
    
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if data == broadcastData {
            if let host = GCDAsyncUdpSocket.host(fromAddress: address) {
                if let h = safeHost(host) {
                    if hosts.contains(h) == false {
                        hosts.append(h)
                    }
                }
            }
            NotificationCenter.default.post(name: didUpdate, object: hosts)
        }
        
    }
}
