//
//  CommandClient.m
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/16.
//

#import "CommandClient.h"

@interface CommandClient ()
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, assign) NSInteger connectionFailCount;
@end

@implementation CommandClient

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
        self.connectionFailCount = 0;
    }
    return self;
}

- (void)connectToHelper {
    NSError *error = nil;
    if (![self.socket connectToHost:@"127.0.0.1" onPort:12345 error:&error]) {
        NSLog(@"❌ 连接失败: %@", error);
        self.connectionFailCount++;
        
        // 连接失败次数达到3次时，提示用户手动打开文件
        if (self.connectionFailCount >= 3) {
            NSLog(@"⚠️ 连接失败次数达到3次，提示用户手动启动CommandHelper");
            [self showHelperStartupInstructions];
            return;
        }
        
        NSLog(@"⚠️ 连接失败次数: %ld/3", (long)self.connectionFailCount);
    } else {
        NSLog(@"✅ 正在连接 Helper Tool...");
    }
}

// 显示CommandHelper启动说明
- (void)showHelperStartupInstructions {
    NSLog(@"📋 CommandHelper启动说明:");
    NSLog(@"1. 点击'打开文件夹'按钮");
    NSLog(@"2. 双击CommandHelper文件启动");
    NSLog(@"3. 确保CommandHelper正在监听端口12345");
    
    // 显示用户友好的提示对话框
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithOpenFolderOption];
    });
}

// 获取CommandHelper路径
- (NSString *)getHelperPath {
    // 尝试从项目目录获取
    NSString *projectPath = [[NSBundle mainBundle] bundlePath];
    NSString *projectDir = [projectPath stringByDeletingLastPathComponent];
    NSString *helperPath = [projectDir stringByAppendingPathComponent:@"CommandHelper"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:helperPath]) {
        return helperPath;
    }
    
    // 尝试从Bundle中获取
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"CommandHelper" ofType:nil];
    if (bundlePath) {
        return bundlePath;
    }
    
    // 尝试从当前工作目录获取
    NSString *currentPath = [NSString stringWithFormat:@"%@/CommandHelper", [[NSFileManager defaultManager] currentDirectoryPath]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath]) {
        return currentPath;
    }
    
    return nil;
}

// 显示带打开文件夹选项的对话框
- (void)showAlertWithOpenFolderOption {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"需要启动CommandHelper"
                                                                   message:@"连接失败3次，请先启动CommandHelper才能使用此功能\n\n1. 点击'打开文件夹'按钮\n2. 双击CommandHelper文件启动\n3. 然后重新运行此应用"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加"打开文件夹"按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"打开文件夹" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openHelperFolder];
    }]];
    
    // 添加"重试连接"按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"重试连接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.connectionFailCount = 0; // 重置失败次数
        [self connectToHelper];
    }]];
    
    // 添加"取消"按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // 获取当前显示的ViewController
    UIViewController *topViewController = [self getTopViewController];
    [topViewController presentViewController:alert animated:YES completion:nil];
}

// 打开CommandHelper所在文件夹
- (void)openHelperFolder {
    NSString *helperPath = [self getHelperPath];

    if ([[PPCatalystHandle.sharedPPCatalystHandle openFileOrDirWithPath:helperPath] integerValue] == 1) {
        NSLog(@"✅ 已打开文件夹: %@", helperPath);
        NSLog(@"💡 请双击CommandHelper文件启动");
        return;
    } else {
        NSLog(@"❌ 无法打开文件夹: %@", helperPath);
        // 显示错误提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法打开文件夹"
                                                                        message:@"请确保CommandHelper文件存在于项目目录中"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *topViewController = [self getTopViewController];
        [topViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
}

// 获取当前显示的ViewController
- (UIViewController *)getTopViewController {
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        topViewController = ((UINavigationController *)topViewController).topViewController;
    }
    
    return topViewController;
}

- (void)sendCommand:(NSString *)command {
    if (!self.socket.isConnected) {
        NSLog(@"⚠️ Socket 未连接，尝试重新连接...");
        [self connectToHelper];
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
    self.connectionFailCount = 0; // 连接成功，重置失败次数
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
    self.connectionFailCount++;
    
    // 连接失败次数达到3次时，提示用户手动打开文件
    if (self.connectionFailCount >= 3) {
        NSLog(@"⚠️ 断开连接失败次数达到3次，提示用户手动启动CommandHelper");
        [self showHelperStartupInstructions];
        return;
    }
    
    NSLog(@"⚠️ 断开连接失败次数: %ld/3", (long)self.connectionFailCount);
    
    // 如果连接断开，尝试重新连接
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self connectToHelper];
    });
}

@end
