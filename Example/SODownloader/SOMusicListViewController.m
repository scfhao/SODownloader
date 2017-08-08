//
//  SOMusicListViewController.m
//  SODownloadExample
//
//  Created by scfhao on 16/6/20.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  下载列表界面示例，这里有对下载的开始、暂停、继续、取消等功能的示例。

#import "SOMusicListViewController.h"
#import "SOMusic.h"
#import "SOLog.h"
#import "SOMusicListCell.h"
#import "SODownloader+MusicDownloader.h"

static void * kDownloaderKVOContext = &kDownloaderKVOContext;

@interface SOMusicListViewController ()

@property (strong, nonatomic) NSArray<SODownloadItem> *musicArray;

@end

@implementation SOMusicListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.musicArray = (NSArray<SODownloadItem> *)[SOMusic allMusicList];
    [[SODownloader musicDownloader]addObserver:self forKeyPath:SODownloaderDownloadArrayObserveKeyPath options:NSKeyValueObservingOptionNew context:kDownloaderKVOContext];
    [[SODownloader musicDownloader]addObserver:self forKeyPath:SODownloaderCompleteArrayObserveKeyPath options:NSKeyValueObservingOptionNew context:kDownloaderKVOContext];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/// 这样可以移除tableView上可见cell对music模型的kvo观察，不可见cell的移除kvo代码见tableView:didEndDisplayingCell:forRowAtIndexPath:方法。
- (void)dealloc
{
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(configureMusic:) withObject:nil];
    [[SODownloader musicDownloader]removeObserver:self forKeyPath:SODownloaderDownloadArrayObserveKeyPath];
    [[SODownloader musicDownloader]removeObserver:self forKeyPath:SODownloaderCompleteArrayObserveKeyPath];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.musicArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusic *music = self.musicArray[indexPath.row];
    
    SOMusicListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SOMusicListCell class]) forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    [cell configureMusic:music];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusic *music = self.musicArray[indexPath.row];
    switch (music.so_downloadState) {
        case SODownloadStateError:
        {
            [[SODownloader musicDownloader]resumeItem:music];
        }
            break;
        case SODownloadStatePaused:
        {
            [[SODownloader musicDownloader]resumeItem:music];
        }
            break;
        case SODownloadStateNormal:
        {
            [[SODownloader musicDownloader]downloadItem:music];
        }
            break;
        case SODownloadStateLoading:
        {
            [[SODownloader musicDownloader]pauseItem:music];
        }
            break;
        case SODownloadStateWait:
        {
            [[SODownloader musicDownloader]pauseItem:music];
        }
            break;
        default:
            break;
    }
}

/// 实现这个代理方法是为了当一个cell在界面消失时，移除cell对music模型的kvo。
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusicListCell *musicCell = (SOMusicListCell *)cell;
    [musicCell configureMusic:nil];
}

#pragma mark - Actions
- (IBAction)showActions:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"请选择操作" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]downloadItems:self.musicArray];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部暂停" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]pauseAll];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]resumeAll];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]cancenAll];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == kDownloaderKVOContext) {
        if ([keyPath isEqualToString:SODownloaderDownloadArrayObserveKeyPath]) {
            // 下载列表发生变化
            SODebugLog(@"下载列表发生变化");
        } else {
            // 已下载列表发生变化
            SODebugLog(@"已下载列表发生变化");
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
