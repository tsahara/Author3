//
//  AppDelegate.swift
//  Author3
//
//  Created by Tomoyuki Sahara on 1/26/16.
//  Copyright © 2016 Tomoyuki Sahara. All rights reserved.
//

import Cocoa
import Security
import ServiceManagement

@objc protocol AuthorHelperProtocol {
    func getVersion(withReply: (NSString) -> Void)
    //func openBpf(withReply: (Int, Int) -> Void)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var authref: AuthorizationRef = nil
    
    let HelperServiceName = "net.caddr.Author3Helper"

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        try_connect()
        //return
        
        auth_and_bless()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func auth_and_bless() {
        
        var status: OSStatus
        
        let authFlags = AuthorizationFlags()
        status = AuthorizationCreate(nil, nil, authFlags, &authref)
        if (status != OSStatus(errAuthorizationSuccess)) {
            print("AuthorizationCreate failed.")
            return;
        }

        var item = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)
        let flags = AuthorizationFlags([.InteractionAllowed, .ExtendRights])

        status = AuthorizationCopyRights(authref, &rights, nil, flags, nil)
        if (status != OSStatus(errAuthorizationSuccess)) {
            print("AuthorizationCopyRights failed.")
            return;
        }

        var cfError: Unmanaged<CFError>?
        let success = SMJobBless(kSMDomainSystemLaunchd, HelperServiceName, authref, &cfError)
        if !success {
            print("SMJobBless failed: \(cfError!)")
        }

        getversion()
    }

    func try_connect() {
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .Privileged)
        xpc.remoteObjectInterface = NSXPCInterface(withProtocol: AuthorHelperProtocol.self)
        xpc.resume()
        print("xpc=\(xpc), pid=\(xpc.processIdentifier)")

        let helper = xpc.remoteObjectProxyWithErrorHandler({
            err in
            print("xpc error =>\(err)")
        }) as! AuthorHelperProtocol

        helper.getVersion({
            str in
            print("get version => \(str), pid=\(xpc.processIdentifier)")
        })

        
    }

    func getversion() {
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .Privileged)
        xpc.remoteObjectInterface = NSXPCInterface(withProtocol: AuthorHelperProtocol.self)
        xpc.invalidationHandler = { print("XPC invalidated...!") }
        xpc.resume()
        print(xpc)
        
        // getVersionAction
        let proxy = xpc.remoteObjectProxyWithErrorHandler({
            err in
            print("xpc error =>\(err)")
        }) as! AuthorHelperProtocol
        proxy.getVersion({
            str in
            print("get version => \(str), pid=\(xpc.processIdentifier)")
        })
    }
}
