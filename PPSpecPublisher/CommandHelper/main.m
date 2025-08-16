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

// 检查端口是否被占用
- (BOOL)isPortOccupied:(uint16_t)port {
    GCDAsyncSocket *testSocket = [[GCDAsyncSocket alloc] initWithDelegate:nil delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    BOOL success = [testSocket acceptOnPort:port error:&error];
    [testSocket disconnect];
    return !success;
}

// 杀死占用指定端口的进程
- (void)killProcessesUsingPort:(uint16_t)port {
    NSLog(@"🔍 检查端口 %d 是否被占用...", port);
    
    if (![self isPortOccupied:port]) {
        NSLog(@"✅ 端口 %d 未被占用", port);
        return;
    }
    
    NSLog(@"⚠️ 端口 %d 被占用，正在查找并杀死相关进程...", port);
    
    // 使用lsof命令查找占用端口的进程
    NSTask *lsofTask = [[NSTask alloc] init];
    lsofTask.launchPath = @"/usr/sbin/lsof";
    lsofTask.arguments = @[@"-ti", [NSString stringWithFormat:@":%d", port]];
    
    NSPipe *pipe = [NSPipe pipe];
    lsofTask.standardOutput = pipe;
    lsofTask.standardError = pipe;
    
    [lsofTask launch];
    [lsofTask waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (output.length > 0) {
        NSArray *pids = [output componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        pids = [pids filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        for (NSString *pid in pids) {
            NSLog(@"🔫 杀死进程 PID: %@", pid);
            
            NSTask *killTask = [[NSTask alloc] init];
            killTask.launchPath = @"/bin/kill";
            killTask.arguments = @[@"-9", pid];
            
            [killTask launch];
            [killTask waitUntilExit];
        }
        
        // 等待一下让进程完全退出
        [NSThread sleepForTimeInterval:0.5];
        
        // 再次检查端口是否释放
        if (![self isPortOccupied:port]) {
            NSLog(@"✅ 端口 %d 已成功释放", port);
        } else {
            NSLog(@"❌ 端口 %d 仍然被占用", port);
        }
    } else {
        NSLog(@"⚠️ 未找到占用端口 %d 的进程", port);
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 在启动前检查并杀死占用端口的进程
        [self killProcessesUsingPort:12345];
        
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
