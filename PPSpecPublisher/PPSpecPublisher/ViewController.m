//
//  ViewController.m
//  PPSpecPublisher
//
//  Created by Garenge on 2025/7/13.
//

#import "ViewController.h"
#import "PPSpecModel.h"
#import "PPFloatingTableView.h"
#import "PPAddNewVersionVC.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray <PPSpecModel *>*dataList;

@property (nonatomic, strong, nullable) PPSpecModel *selectedSpecModel;
@property (nonatomic, strong, nullable) PPSpecVersionModel *selectedVersionModel;

@property (nonatomic, strong) PPFloatingTableView *floatingTableView;

@property (nonatomic, strong) UIButton *versionBtn;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) PPAlertBaseView *floatAlertView;

@end

@implementation ViewController

- (NSMutableArray<PPSpecModel *> *)dataList {
    if (nil == _dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

- (PPAlertBaseView *)floatAlertView {
    if (nil == _floatAlertView) {
        _floatAlertView = [[PPAlertBaseView alloc] initWithFrame:CGRectZero];
        _floatAlertView.backgroundColor = rgba(0, 0, 0, 0.1);
        
        __weak typeof(self) weakSelf = self;
        _floatAlertView.touchEmptyAreaBlock = ^(PPAlertBaseView * _Nonnull alertView) {
            [weakSelf.floatAlertView dismiss];
        };
    }
    return _floatAlertView;
}

- (PPFloatingTableView *)floatingTableView {
    if (nil == _floatingTableView) {
        
        _floatingTableView = [[PPFloatingTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [self.floatAlertView addSubview:_floatingTableView];
        
        __weak typeof(self) weakSelf = self;
        self.floatingTableView.didSelectedAtIndex = ^(PPFloatingTableView * _Nonnull floatingView, NSInteger index) {
            weakSelf.selectedVersionModel = weakSelf.selectedSpecModel.versions[index];
            [weakSelf.floatAlertView dismiss];
        };
        // 阴影
        _floatingTableView.layer.shadowColor = UIColor.blackColor.CGColor;
        _floatingTableView.layer.shadowOffset = CGSizeMake(0, 2);
        _floatingTableView.layer.shadowOpacity = 0.3;
        _floatingTableView.layer.shadowRadius = 4;
    }
    return _floatingTableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupSubviews];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshData];
    });
}

- (void)setupSubviews {
    self.view.backgroundColor = rgba(249, 249, 249, 1);
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.backgroundColor = UIColor.whiteColor;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.showsHorizontalScrollIndicator = NO;
    if (@available(iOS 15.0, *)) {
        tableView.sectionHeaderTopPadding = 0;
    } else {
        // Fallback on earlier versions
    }
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(32);
        make.top.equalTo(self.view.mas_topMargin).offset(32);
        make.width.mas_equalTo(250);
        make.bottom.equalTo(self.view.mas_bottomMargin).offset(-32);
    }];
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    
    tableView.tableHeaderView = [UIView new];
    tableView.tableFooterView = [UIView new];
    
    UIView *rightContentView = [self setupRightContentView];
    [self.view addSubview:rightContentView];
    [rightContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tableView.mas_right).offset(16);
        make.top.equalTo(tableView.mas_top);
        make.right.mas_equalTo(-32);
        make.bottom.equalTo(tableView.mas_bottom);
    }];
}

- (UIView *)setupRightContentView {
    UIView *contentView = [UIView pp_view];
    UIButton *versionBtn = [UIButton pp_buttonWithTitle:@"版本号" titleColor:UIColor.blackColor titleFont:[UIFont systemFontOfSize:16]];
    [versionBtn setBorderCornerRadius:8 borderColor:UIColor.lightGrayColor width:1];
    [versionBtn addTarget:self action:@selector(doClickedSelectVersionBtn:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:versionBtn];
    self.versionBtn = versionBtn;
    [versionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(32);
        make.width.mas_equalTo(120);
        make.top.mas_equalTo(20);
        make.height.mas_equalTo(44);
    }];
    
    UIButton *confirmBtn = [UIButton pp_buttonWithTitle:@"添加新版本" titleColor:UIColor.blackColor titleFont:[UIFont systemFontOfSize:16]];
    [confirmBtn setBorderCornerRadius:8 borderColor:UIColor.lightGrayColor width:1];
    [confirmBtn addTarget:self action:@selector(doClickedAddNewVersionAction:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:confirmBtn];
    [confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-32);
        make.top.equalTo(versionBtn.mas_top);
        make.height.mas_equalTo(44);
        make.width.mas_equalTo(120);
    }];
    
    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont systemFontOfSize:17];
    textView.textColor = UIColor.blackColor;
    textView.editable = NO;
    [contentView addSubview:textView];
    self.textView = textView;
    textView.borderCornerRadius = 8;
    [textView setBorderCornerRadius:8 borderColor:UIColor.lightGrayColor width:1];
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.top.equalTo(versionBtn.mas_bottom).offset(20);
    }];
    
    UILabel *tipsLabel = [UILabel pp_labelWithText:@"* 注意, 请确认自己修改正确之后再点击确认, 确认之后, 将在本地创建版本路径" textColor:UIColor.redColor font:[UIFont systemFontOfSize:16]];
    [contentView addSubview:tipsLabel];
    [tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.top.equalTo(textView.mas_bottom).offset(20);
        make.bottom.mas_equalTo(-20);
    }];
    
    return contentView;
}

- (void)refreshData {
    NSString *path = @"/Users/garenge/Downloads/Develop/SDK/pengpengSpecs";
    NSArray <NSString *>*fileList = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil];
    NSArray *dataList = [fileList pp_filter:^BOOL(NSString * _Nonnull element) {
        if ([element hasPrefix:@"."]) {
            return NO;
        }
        return YES;
    } pp_map:^id _Nonnull(NSString * _Nonnull element) {
        PPSpecModel *model = [[PPSpecModel alloc] init];
        model.title = element;
        model.path = [path stringByAppendingPathComponent:element];
        return model;
    }];
    
    [self.dataList removeAllObjects];
    [self.dataList addObjectsFromArray:dataList];
    [self.tableView reloadData];
    
    if (self.dataList.count > 0) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    self.selectedSpecModel = dataList.firstObject;
}

- (void)setSelectedSpecModel:(PPSpecModel *)selectedSpecModel {
    _selectedSpecModel = selectedSpecModel;
    
    if (!selectedSpecModel) {
        [self.versionBtn setTitle:@"请选择" forState:UIControlStateNormal];
        self.textView.text = nil;
        return;
    }
    
    NSLog(@"Selected Spec: %@, Path: %@", selectedSpecModel.title, selectedSpecModel.path);
    
    self.selectedVersionModel = selectedSpecModel.versions.firstObject;
    NSString *version = self.selectedVersionModel.version;
    [self.versionBtn setTitle:version.length > 0 ? version : @"请选择" forState:UIControlStateNormal];
    
    NSString *specFilePath = selectedSpecModel.selectedVersion.podspecPath;
    self.textView.text = [[NSString alloc] initWithContentsOfFile:specFilePath encoding:NSUTF8StringEncoding error:nil];
}

- (void)setSelectedVersionModel:(PPSpecVersionModel *)selectedVersionModel {
    _selectedVersionModel = selectedVersionModel;
    
    self.selectedSpecModel.selectedVersion = selectedVersionModel;
    
    NSLog(@"Selected Version: %@", selectedVersionModel.version);
    
    NSString *version = self.selectedVersionModel.version;
    [self.versionBtn setTitle:version.length > 0 ? version : @"请选择" forState:UIControlStateNormal];
    
    NSString *specFilePath = self.selectedVersionModel.podspecPath;
    self.textView.text = [[NSString alloc] initWithContentsOfFile:specFilePath encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - action

- (void)doClickedSelectVersionBtn:(UIButton *)sender {
    if (nil == self.selectedSpecModel) {
        NSLog(@"请先选择一个库");
        return;
    }
    if (self.selectedSpecModel.versions.count == 0) {
        NSLog(@"没有更多版本可供选择");
        return;
    }
    
    NSArray *list = [self.selectedSpecModel.versions pp_mapWithIndex:^id _Nonnull(PPSpecVersionModel * _Nonnull element, NSInteger index) {
        return element.version;
    }];
    self.floatingTableView.dataList = list;
    
    CGRect fullFrame = [self.versionBtn convertRect:self.versionBtn.bounds toView:UIApplication.sharedApplication.keyWindow];
    self.floatingTableView.frame = CGRectMake(fullFrame.origin.x, fullFrame.origin.y + fullFrame.size.height + 4, fullFrame.size.width, MIN(40 * list.count, 200));
    [self.floatAlertView show];
}

- (void)doClickedAddNewVersionAction:(UIButton *)sender {
    PPAddNewVersionVC *vc = [[PPAddNewVersionVC alloc] init];
    vc.selectedSpecModel = self.selectedSpecModel;
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navi animated:YES completion:nil];
}

#pragma mark - tableView delegate dataSource\

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = self.dataList[indexPath.row].title;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedSpecModel = self.dataList[indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
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
