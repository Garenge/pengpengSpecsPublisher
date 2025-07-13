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
    for (NSString *fileName in fileList) {
        if ([fileName hasPrefix:@"."]) {
            continue;
        }
        NSString *version = fileName;
        NSString *folder = [path stringByAppendingPathComponent:fileName];
        NSString *specName = [NSString stringWithFormat:@"%@.podSpec", self.title];
        NSString *specPath = [folder stringByAppendingPathComponent:specName];
        
        PPSpecVersionModel *model = [PPSpecVersionModel new];
        model.version = version;
        model.podSpecPath = specPath;
        
        [versions addObject:model];
    }
    self.versions = versions;
}

@end
