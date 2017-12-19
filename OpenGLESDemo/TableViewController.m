//
//  TableViewController.m
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/18.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "TableViewController.h"

static NSString* strControllers[] = {
    @"RGB24ImageViewController",
    @"CameraBGRAViewController",
    @"CameraNV12ViewController",
    @"Camerai420ViewController",
};

static NSString* strControllerDescs [] = {
    @"从文件file.rgb24中读取rgb数据进行渲染",
    @"对相机采集BGRA格式数据进行渲染",
    @"对相机采集NV12格式数据进行渲染(需要设置HXAVCaptureSession中数据返回格式为NV12)",
    @"对相机采集I420格式数据进行渲染(需要设置HXAVCaptureSession中数据返回格式为I420)",
};

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sizeof(strControllers) / sizeof(strControllers[0]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:@"reuseIdentifier"];
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
    }
    cell.textLabel.text = strControllers[indexPath.row];
    cell.detailTextLabel.text = strControllerDescs[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController* controller = [[NSClassFromString(strControllers[indexPath.row]) alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
