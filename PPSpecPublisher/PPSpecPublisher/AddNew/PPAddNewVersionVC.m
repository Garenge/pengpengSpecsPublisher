//
//  PPAddNewVersionVC.m
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/13.
//

#import "PPAddNewVersionVC.h"
#import "CommandClient.h"

@interface PPAddNewVersionVC ()

@property (nonatomic, strong) NSString *toCreateVersion;

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) CommandClient *client;

@end

@implementation PPAddNewVersionVC

- (void)dealloc {
    NSLog(@"PPAddNewVersionVC dealloc");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (nil == self.toCreateVersion || self.toCreateVersion.length == 0) {
//        [self doShowAlertToInputVersion];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"新建版本";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(doCancelBtnClickedAction:)];
    
    UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(doConfirmToCreateVersion:)];
    self.navigationItem.rightBarButtonItems = @[
        confirmButton
    ];
    
    [self setupSubviews];
    
    self.client = [[CommandClient alloc] init];
    [self.client connectToHelper];
    
    __weak typeof(self) weakSelf = self;
    self.client.onResponse = ^(NSString *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"收到回传：%@", response);
            // 更新 UI，例如 TextView
//            5weakSelf.outputTextView.string = response;
        });
    };
    
    self.client.onDidConnect = ^{
        // 尝试发一些指令
//        NSString *command = @"ls -l";
        NSString *spec = weakSelf.selectedSpecModel.selectedVersion.podspecPath;
        [weakSelf getSourceUrlFromSpecPath:spec];
    };
}

- (void)setupSubviews {
    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont systemFontOfSize:17];
    textView.textColor = UIColor.blackColor;
    [self.view addSubview:textView];
    self.textView = textView;
    textView.borderCornerRadius = 8;
    [textView setBorderCornerRadius:8 borderColor:UIColor.lightGrayColor width:1];
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.top.equalTo(self.view.mas_topMargin).offset(20);
        make.bottom.equalTo(self.view.mas_bottomMargin).offset(-20);
    }];
}

- (void)setToCreateVersion:(NSString *)toCreateVersion {
    _toCreateVersion = toCreateVersion;
    
    // 这里可以进行一些处理, 比如更新UI等
    NSLog(@"设置新建版本号: %@", toCreateVersion);
    
    self.navigationItem.title = toCreateVersion.length > 0 ? [NSString stringWithFormat:@"新建版本 %@", toCreateVersion] : @"新建版本";
}

#pragma mark - socket

- (void)getSourceUrlFromSpecPath:(NSString *)specPath {
    NSLog(@"======== 当前仓库spec 文件地址: %@", specPath);
    NSString *command = [NSString stringWithFormat:@"/opt/homebrew/bin/pod ipc spec %@", specPath];
    [self.client sendCommand:command];
};


#pragma mark - action

- (void)doCancelBtnClickedAction:(UIBarButtonItem *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doShowAlertToInputVersion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请输入新建版本号" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"版本号";
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        [self doHandleParaseToCreateVersion:textField.text];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doHandleParaseToCreateVersion:(NSString *)toCreateVersion {
    NSArray *versions = [toCreateVersion componentsSeparatedByString:@"."];
    if (versions.count != 3) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"版本号格式不正确，请使用 x.y.z 的格式" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self doShowAlertToInputVersion];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    self.toCreateVersion = toCreateVersion;
    
    // 这里我们先去github获取仓库地址, tag对应的版本, 然后下载podspec文件, 解析
    [self doTryToRequestFromGithubWithVersion:^(BOOL requestSueccess) {
        if (requestSueccess) {
            
        } else {
            // 尝试提示, 让用户选择前面的模版
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"暂未获取到远程仓库中的podspec, 你可以继续选择过去版本作为模版进行编辑" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self doShowSelectPreVersionSheet];
            }];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)doShowSelectPreVersionSheet {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择版本" message:@"请选择一个已有的版本作为模版" preferredStyle:UIAlertControllerStyleActionSheet];
    for (PPSpecVersionModel *version in self.selectedSpecModel.versions) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:version.version style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 这里需要将选择的版本作为模版进行编辑
            NSLog(@"选择的版本: %@", version.version);
            NSString *specFilePath = version.podspecPath;
            self.textView.text = [[NSString alloc] initWithContentsOfFile:specFilePath encoding:NSUTF8StringEncoding error:nil];
        }];
        [alert addAction:action];
    }
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doTryToRequestFromGithubWithVersion:(void (^)(BOOL requestSueccess))completion {
    
    
    // TODO: 根据
    NSString *sourceUrl = self.selectedSpecModel.selectedVersion.sourceUrl;
    
    if (completion) {
        completion(NO);
    }
}

- (void)doConfirmToCreateVersion:(UIBarButtonItem *)sender {
    // TODO: 创建文件夹, 保存podspec文件, 然后打开fork软件, 准备提交
    
}

@end
