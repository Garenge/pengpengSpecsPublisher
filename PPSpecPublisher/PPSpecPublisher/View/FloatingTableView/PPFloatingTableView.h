//
//  PPFloatingTableView.h
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPFloatingTableView : UITableView

@property (nonatomic, strong) NSArray <NSString *>*dataList;
@property (nonatomic, copy) void(^didSelectedAtIndex)(PPFloatingTableView *floatingView, NSInteger index);

@end

NS_ASSUME_NONNULL_END
