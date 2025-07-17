//
//  main.m
//  CommandHelper
//
//  Created by Garenge on 2025/7/16.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface CommandServer : NSObject <GCDAsyncSocketDelegate>

@property (strong, nonatomic) GCDAsyncSocket *serverSocket;

@property (nonatomic, strong) NSMutableDictionary *connectedClients;

@end

@implementation CommandServer

- (NSMutableDictionary *)connectedClients {
    if (nil == _connectedClients) {
        _connectedClients = [NSMutableDictionary dictionary];
    }
    return _connectedClients;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSError *error = nil;
        if (![self.serverSocket acceptOnPort:12345 error:&error]) {
            NSLog(@"❌ 启动失败: %@", error);
        } else {
            NSLog(@"✅ 启动成功，监听端口 12345");
        }
    }
    return self;
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"📥 新连接来自: %@", newSocket.connectedHost);
    [newSocket readDataWithTimeout:-1 tag:0];
    
    NSString *address = [NSString stringWithFormat:@"%p", newSocket];
    self.connectedClients[address] = newSocket;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *cmd = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"📨 收到命令：%@", cmd);
    
    [self executeCommand:cmd withCompletion:^(NSString *output) {
        NSData *responseData = [output dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:responseData withTimeout:-1 tag:0];
    }];
    
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSString *address = [NSString stringWithFormat:@"%p", sock];
    [self.connectedClients removeObjectForKey:address];
    NSLog(@"❌ 连接断开: %@, 错误: %@", sock.connectedHost, err);
}

- (void)executeCommand:(NSString *)command withCompletion:(void (^)(NSString *output))completion {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", [NSString stringWithFormat:@"export LANG=en_US.UTF-8;%@", command]];
    
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
    env[@"LANG"] = @"en_US.UTF-8";
    env[@"PATH"] = @"/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    task.environment = env;
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    
    [task setTerminationHandler:^(NSTask * _Nonnull t) {
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        completion(result ?: @"<无输出>");
    }];
    
    [task launch];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        CommandServer *server = [[CommandServer alloc] init];
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}
