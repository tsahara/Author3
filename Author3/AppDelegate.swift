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
    func getVersion2(_ withReply: (NSString) -> Void)
    func authTest(_ form: AuthorizationExternalForm, withReply: (NSString) -> Void)
    //func openBpf(withReply: (Int, Int) -> Void)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var authref: AuthorizationRef? = nil
    
    let HelperServiceName = "net.caddr.Author3Helper"
    let HelperVersion     = "1.5.X"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authref)
        if (status != OSStatus(errAuthorizationSuccess)) {
            print("AuthorizationCreate failed.")
            return;
        }

        connect_to_helper({
            success in
            if success {
                self.connected()
            } else {
                self.install_helper()
                self.connect_to_helper({
                    sucess in
                    self.connected()
                    if sucess {
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
    
    func try_auth() {
        // 1. Create an empty authorization reference
        var aref: AuthorizationRef? = nil
        var status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &aref)
        if (status != errAuthorizationSuccess) {
            print("AuthorizationCreate failed.")
            return;
        }
       
        // 2. Create AuthorizationRights.
        var item = AuthorizationItem(name: "com.myOrganization.myProduct.myRight1", valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)
        let flags = AuthorizationFlags([.interactionAllowed, .extendRights, .preAuthorize])
        status = AuthorizationCopyRights(authref!, &rights, nil, flags, nil)
        if (status != errAuthorizationSuccess) {
            print("AuthorizationCopyRights failed.")
            return;
        }
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
        var item = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)
        let flags = AuthorizationFlags([.interactionAllowed, .extendRights])

        let status = AuthorizationCopyRights(authref!, &rights, nil, flags, nil)
        if (status != errAuthorizationSuccess) {
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
        
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .privileged)
        xpc.remoteObjectInterface = NSXPCInterface(with: AuthorHelperProtocol.self)
        xpc.invalidationHandler = { print("XPC invalidated...!") }
        xpc.resume()
        print(xpc)
        
        let proxy = xpc.remoteObjectProxyWithErrorHandler({
            err in
            print("xpc error =>\(err)")
        }) as! AuthorHelperProtocol

        var form = AuthorizationExternalForm()
        let status = AuthorizationMakeExternalForm(authref!, &form)
        if status != errAuthorizationSuccess {
            print("AuthorizationMakeExternalForm failed.")
            return;
        }

        proxy.getVersion2({
            msg in
            print("g-v-2 => \(msg)")
        })
        
        proxy.authTest(form, withReply: {
            msg in
            print("msg=\(msg)")
        })
    }
}
