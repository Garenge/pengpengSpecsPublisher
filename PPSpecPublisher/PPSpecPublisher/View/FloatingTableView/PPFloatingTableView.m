//
//  PPFloatingTableView.m
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/13.
//

#import "PPFloatingTableView.h"

@interface PPFloatingTableView() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation PPFloatingTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    if (self = [super initWithFrame:frame style:style]) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.delegate = self;
        self.dataSource = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.backgroundColor = rgba(249, 249, 249, 1);
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 15.0, *)) {
            self.sectionHeaderTopPadding = 0;
        } else {
            // Fallback on earlier versions
        }
        
        [self registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        
        self.tableHeaderView = [UIView new];
        self.tableFooterView = [UIView new];
    }
    return self;
}

@synthesize dataList = _dataList;

- (NSArray<NSString *> *)dataList {
    if (nil == _dataList) {
        _dataList = [NSArray array];
    }
    return _dataList;
}

- (void)setDataList:(NSArray<NSString *> *)dataList {
    _dataList = dataList;
    
    [self reloadData];
}

#pragma mark - tableView delegate dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    UILabel *titleLabel = [cell.contentView viewWithTag:1001];
    if (nil == titleLabel) {
        titleLabel = [UILabel pp_labelWithText:@"" textColor:UIColor.darkTextColor font:[UIFont systemFontOfSize:16] alignment:NSTextAlignmentCenter];
        titleLabel.tag = 1001;
        [cell.contentView addSubview:titleLabel];
        
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
    }
    titleLabel.text = self.dataList[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.didSelectedAtIndex) {
        self.didSelectedAtIndex(self, indexPath.row);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return UIView.new;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return UIView.new;
}

@end
