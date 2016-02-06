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

@objc protocol Author3HelperProtocol {
    func getVersion(withReply: (NSString) -> Void)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var authref = AuthorizationRef()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        var status: OSStatus
 
        let helper = "net.caddr.Author3Helper"

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
        let success = SMJobBless(kSMDomainSystemLaunchd, helper, authref, &cfError)
        if !success {
            print(cfError!)
        }
        
        getversion()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


    func getversion() {
        let helper = "net.caddr.Author3Helper"

        let xpc = NSXPCConnection(machServiceName: helper, options: .Privileged)
        xpc.remoteObjectInterface = NSXPCInterface(withProtocol: Author3HelperProtocol.self)
        xpc.invalidationHandler = { print("XPC invalidated...!") }
        xpc.resume()
        print(xpc)
        
        // getVersionAction
        var proxy = xpc.remoteObjectProxyWithErrorHandler({
            err in
            print("xpc error =>\(err)")
        }) as! Author3HelperProtocol
        proxy.getVersion({
            str in
            print("get version => \(str)")
        })
    }
}

