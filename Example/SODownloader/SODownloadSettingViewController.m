//
//  SODownloadSettingViewController.m
//  SODownloadExample
//
//  Created by xueyi on 2017/6/1.
//  Copyright © 2017年 http://scfhao.coding.me. All rights reserved.
//  SODownloadSettingViewController.{h, m}: 设置界面示例，示例下载设置操作。

#import "SODownloadSettingViewController.h"
#import "SODownloader+MusicDownloader.m"

@interface SODownloadSettingViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UISwitch *switcher;

@end

@implementation SODownloadSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.switcher.on = [SODownloader musicDownloader].allowsCellularAccess;
    self.segmentedControl.selectedSegmentIndex = [SODownloader musicDownloader].maximumActiveDownloads - 1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)segmentedControlAction:(UISegmentedControl *)sender {
    [SODownloader musicDownloader].maximumActiveDownloads = sender.selectedSegmentIndex + 1;
    [[NSUserDefaults standardUserDefaults]setObject:@(sender.selectedSegmentIndex + 1) forKey:kMaximumActiveDownloadsKey];
}

- (IBAction)switchAction:(UISwitch *)sender {
    [SODownloader musicDownloader].allowsCellularAccess = sender.on;
    [[NSUserDefaults standardUserDefaults]setObject:@(sender.on) forKey:kAllowsCellularAccessKey];
}

@end
