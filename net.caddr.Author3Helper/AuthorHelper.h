//
//  AuthorHelper.h
//  Author3
//
//  Created by Tomoyuki Sahara on 2/5/16.
//  Copyright © 2016 Tomoyuki Sahara. All rights reserved.
//

#ifndef AuthorHelper_h
#define AuthorHelper_h

@protocol AuthorHelperProtocol

@required

- (void)getVersion:(void(^)(NSString * version))reply;
- (void)getVersion2:(void(^)(NSString * version))reply;
- (void)openBPF:(void(^)(int))reply;
- (void)authTest:(AuthorizationExternalForm *)form withReply:(void(^)(NSString * version))reply;

@end


@interface AuthorHelper : NSObject

- (id)init;

- (void)run;

@end
#endif /* AuthorHelper_h */
