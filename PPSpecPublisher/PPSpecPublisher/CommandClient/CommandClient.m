//
//  CommandClient.m
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/16.
//

#import "CommandClient.h"

@interface CommandClient ()
@property (nonatomic, strong) GCDAsyncSocket *socket;
@end

@implementation CommandClient

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
    }
    return self;
}

- (void)connectToHelper {
    NSError *error = nil;
    if (![self.socket connectToHost:@"127.0.0.1" onPort:12345 error:&error]) {
        NSLog(@"❌ 连接失败: %@", error);
    } else {
        NSLog(@"✅ 正在连接 Helper Tool...");
    }
}

- (void)sendCommand:(NSString *)command {
    if (!self.socket.isConnected) {
        NSLog(@"⚠️ Socket 未连接");
        return;
    }
    NSLog(@"======== command: %@", command);
    NSData *data = [command dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:-1 tag:0];
    [self.socket readDataWithTimeout:-1 tag:0]; // 等待响应
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"✅ 已连接到 Helper Tool: %@:%d", host, port);
    [self.socket readDataWithTimeout:-1 tag:0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.onDidConnect) {
            self.onDidConnect();
        }
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (response.length > 0) {
        NSLog(@"📨 收到响应：\n%@", response);
        if (self.onResponse) {
            self.onResponse(response);
        }
    }
    // 继续读取下一条
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"🔌 断开连接：%@", err.localizedDescription ?: @"无错误");
}

@end
