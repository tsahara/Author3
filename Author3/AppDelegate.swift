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
    func getVersion(_ withReply: (NSString) -> Void)
    //func openBpf(withReply: (Int, Int) -> Void)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var authref: AuthorizationRef? = nil
    
    let HelperServiceName = "net.caddr.Author3Helper"
    let HelperVersion     = "1.5.3"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        connect_to_helper({
            success in
            if success {
                self.connected()
            } else {
                self.install_helper()
                self.connect_to_helper({
                    sucess in
                    if sucess {
                        self.connected()
                        print("Installed")
                    } else {
                        print("Fatal!  Could not install Helper!")
                    }
                })
            }
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    /**
     
     Connect to a helper service.
     
     @return whther connection is established or not
     */
    func connect_to_helper(_ callback: @escaping (Bool) -> Void) {
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .privileged)
        xpc.remoteObjectInterface = NSXPCInterface(with: AuthorHelperProtocol.self)
        xpc.resume()

        let helper = xpc.remoteObjectProxyWithErrorHandler({
            _ in callback(false)
        }) as! AuthorHelperProtocol
        
        helper.getVersion({
            version in
            print("get version => \(version), pid=\(xpc.processIdentifier)")
            callback(version as String == self.HelperVersion)
        })
    }
    
    func install_helper() {
        var status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authref)
        if (status != OSStatus(errAuthorizationSuccess)) {
            print("AuthorizationCreate failed.")
            return;
        }

        var item = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)
        let flags = AuthorizationFlags([.interactionAllowed, .extendRights])

        status = AuthorizationCopyRights(authref!, &rights, nil, flags, nil)
        if (status != OSStatus(errAuthorizationSuccess)) {
            print("AuthorizationCopyRights failed.")
            return;
        }

        var cfError: Unmanaged<CFError>?
        let success = SMJobBless(kSMDomainSystemLaunchd, HelperServiceName as CFString, authref, &cfError)
        if !success {
            print("SMJobBless failed: \(cfError!)")
        }

        print("SMJobBless suceeded")
        getversion()
    }

    func getversion() {
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .privileged)
        xpc.remoteObjectInterface = NSXPCInterface(with: AuthorHelperProtocol.self)
        xpc.invalidationHandler = { print("XPC invalidated...!") }
        xpc.resume()
        print(xpc)
        
        let proxy = xpc.remoteObjectProxyWithErrorHandler({
            err in
            print("xpc error =>\(err)")
        }) as! AuthorHelperProtocol
        proxy.getVersion({
            str in
            print("get version => \(str), pid=\(xpc.processIdentifier)")
        })
    }
    
    func connected() {
        print("Hello!")
    }
}
