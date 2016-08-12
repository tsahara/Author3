//
//  Helper.swift
//  Author3
//
//  Created by Tomoyuki Sahara on 2/6/16.
//  Copyright © 2016 Tomoyuki Sahara. All rights reserved.
//

import Foundation

@objc protocol Author3HelperProtocol {
    func getVersion(withReply: (NSString) -> Void)
}

class Helper : NSObject, NSXPCListenerDelegate, Author3HelperProtocol {
    var listener: NSXPCListener

    override init() {
        listener = NSXPCListener(machServiceName: "net.caddr.Author3HelperX")
        super.init()
        listener.delegate = self
    }
    
    func run() {
        listener.resume()
        NSRunLoop.currentRunLoop().run()
    }

    func listener(listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(withProtocol: Author3HelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    func getVersion(reply: (NSString) -> Void) {
        reply(NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! NSString)
    }
}
