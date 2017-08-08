//
//  SOSimpleDownloadViewController.m
//  SODownloadExample
//
//  Created by scfhao on 17/1/6.
//  Copyright © 2017年 http://scfhao.coding.me/blog/ All rights reserved.
//  示例如何直接使用 AFNetworking 进行下载。

#import "SOSimpleDownloadViewController.h"
#import <AFNetworking/AFNetworking.h>

@interface SOSimpleDownloadViewController ()

@property (strong, nonatomic) AFHTTPSessionManager *downloadManager;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;

@end

@implementation SOSimpleDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.downloadManager = [AFHTTPSessionManager manager];
    self.downloadManager.responseSerializer = [AFHTTPResponseSerializer serializer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startDownload:(id)sender {
    if (!self.downloadTask) {
        NSString *url = @"http://test.daqing.net/300M.rar";
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        __weak __typeof__(self) weakSelf = self;
        NSURL *(^destinationBlock)(NSURL *targetPath, NSURLResponse *response) = ^(NSURL *targetPath, NSURLResponse *response) {
//            返回目标下载地址
            NSString *fileName = [targetPath lastPathComponent];
            NSString *destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            return [NSURL fileURLWithPath:destinationPath];
        };
        void (^progressBlock)(NSProgress *downloadProgress) = ^(NSProgress *downloadProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof__(weakSelf) strongSelf = weakSelf;
                strongSelf.progressView.progress = downloadProgress.fractionCompleted;
                strongSelf.tipLabel.text = @"下载中";
            });
        };
        self.downloadTask = [self.downloadManager downloadTaskWithRequest:request progress:progressBlock destination:destinationBlock completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error) {
                if (error.code == NSURLErrorCancelled) {
                    self.tipLabel.text = @"下载已取消";
                } else {
                    self.tipLabel.text = @"下载失败";
                }
            } else {
                self.tipLabel.text = @"下载成功";
            }
        }];
        [self.downloadTask resume];
    }
}

- (IBAction)pauseDownload:(id)sender {
    if (self.downloadTask.state == NSURLSessionTaskStateRunning) {
        [self.downloadTask suspend];
        self.tipLabel.text = @"已暂停";
    }
}

- (IBAction)resumeDownload:(id)sender {
    if (self.downloadTask.state == NSURLSessionTaskStateSuspended) {
        [self.downloadTask resume];
    }
}

- (IBAction)cancelDownload:(id)sender {
    [self.downloadTask cancel];
    self.downloadTask = nil;
    self.progressView.progress = 0;
}

@end
