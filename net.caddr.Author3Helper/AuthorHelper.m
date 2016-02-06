//
//  AuthorHelper.m
//  Author3
//
//  Created by Tomoyuki Sahara on 2/5/16.
//  Copyright © 2016 Tomoyuki Sahara. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthorHelper.h"

#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <net/bpf.h>

@interface AuthorHelper () <NSXPCListenerDelegate, AuthorHelperProtocol>

@property (atomic, strong, readwrite) NSXPCListener *listener;

@end

@implementation AuthorHelper

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:@"net.caddr.Author3Helper"];
        self->_listener.delegate = self;
    }
    return self;
}

- (void)run
{
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AuthorHelperProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

- (void)getVersion:(void(^)(NSString * version))reply
{
    reply([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
}

- (void)openBPF:(void(^)(int))reply;
{
    reply(3);
}

@end