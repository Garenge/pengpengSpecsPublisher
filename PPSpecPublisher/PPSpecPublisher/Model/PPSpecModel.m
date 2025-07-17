//
//  PPSpecModel.m
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/13.
//

#import "PPSpecModel.h"

@implementation PPSpecVersionModel

@end

@implementation PPSpecModel

- (void)setPath:(NSString *)path {
    _path = path;
    
    // 获取所有的版本信息
    NSMutableArray <NSString *>*fileList = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil].mutableCopy;
    [fileList sortUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableArray <PPSpecVersionModel *>*versions = [NSMutableArray array];
    NSArray *fileListT = [fileList reverseObjectEnumerator].allObjects;
    for (NSString *fileName in fileListT) {
        if ([fileName hasPrefix:@"."]) {
            continue;
        }
        NSString *version = fileName;
        NSString *folder = [path stringByAppendingPathComponent:fileName];
        NSString *specName = [NSString stringWithFormat:@"%@.podspec", self.title];
        NSString *specPath = [folder stringByAppendingPathComponent:specName];
        
        PPSpecVersionModel *model = [PPSpecVersionModel new];
        model.version = version;
        model.podspecPath = specPath;
        
        [versions addObject:model];
    }
    self.versions = versions;
}

- (NSString *)getSourceUrlFromSpecPath:(NSString *)specPath {
    NSString *content = [NSString stringWithContentsOfFile:specPath encoding:NSUTF8StringEncoding error:nil];
    
    // TODO: 这里需要实现一个功能, 用Maccatalyst去调用macOS Helper Tool
    // TODO: 然后终端执行pod ipc spec PPCatalystTool.podspec, 拿到某个spec的json数据, 再解析, 但是现在没有方法实现, 先记录
    
    return nil;
}

@end
