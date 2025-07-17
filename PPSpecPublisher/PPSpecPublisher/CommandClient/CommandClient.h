//
//  CommandClient.h
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/16.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface CommandClient : NSObject <GCDAsyncSocketDelegate>

/// 设置回调：连接成功
@property (nonatomic, copy) void (^onDidConnect)(void);
/// 设置回调：收到响应
@property (nonatomic, copy) void (^onResponse)(NSString *response);

/// 连接 Helper Tool
- (void)connectToHelper;

/// 发送 shell 命令
- (void)sendCommand:(NSString *)command;

@end

NS_ASSUME_NONNULL_END
