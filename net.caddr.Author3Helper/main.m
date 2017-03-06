//
//  main.m
//  net.caddr.Author3Helper
//
//  Created by Tomoyuki Sahara on 1/26/16.
//  Copyright © 2016 Tomoyuki Sahara. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthorHelper.h"

#include <syslog.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, const char * argv[]) {
    
    syslog(LOG_NOTICE, "Hello world! uid = %d, euid = %d, pid = %d\n", (int) getuid(), (int) geteuid(), (int) getpid());

    @autoreleasepool {
        [[[AuthorHelper alloc] init] run];
    }
    return 0;
}
