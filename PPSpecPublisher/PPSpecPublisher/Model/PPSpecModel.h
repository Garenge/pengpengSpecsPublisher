//
//  PPSpecModel.h
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPSpecVersionModel : NSObject

@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *podspecPath;

/// github首页地址
@property (nonatomic, strong) NSString *sourceUrl;

@end

@interface PPSpecModel : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSArray <PPSpecVersionModel *>*versions;
@property (nonatomic, strong) PPSpecVersionModel *selectedVersion;

- (void)reloadVersions;

@end

NS_ASSUME_NONNULL_END
