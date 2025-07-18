//
//  PPAddNewVersionVC.h
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/13.
//

#import <UIKit/UIKit.h>
#import "PPSpecModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPAddNewVersionVC : UIViewController

@property (nonatomic, strong) PPSpecModel *selectedSpecModel;

@property (nonatomic, copy) void(^didCompleteAddNewVersion)(NSString *version);

@end

NS_ASSUME_NONNULL_END
