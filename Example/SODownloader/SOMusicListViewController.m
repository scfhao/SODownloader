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
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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

    [cell configureMusic:music];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEditing]) {
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

/// 多选相关的方法
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusic *music = self.musicArray[indexPath.row];
    // 只有 normal（即没下载过的） 状态的才可以下载
    return music.so_downloadState == SODownloadStateNormal;
}

#pragma mark - Actions
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (!editing) {
        // 多选完成
        NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
        if ([selectedIndexPaths count]) {
            NSMutableArray *musicsToDownload = [NSMutableArray arrayWithCapacity:[selectedIndexPaths count]];
            for (NSIndexPath *indexPath in selectedIndexPaths) {
                SOMusic *music = self.musicArray[indexPath.row];
                [musicsToDownload addObject:music];
            }
            [[SODownloader musicDownloader]downloadItems:[musicsToDownload copy]];
        }
    }
    [super setEditing:editing animated:animated];
}

/// 下载全部
- (IBAction)downloadAll:(UIButton *)sender {
    [[SODownloader musicDownloader]downloadItems:self.musicArray];
}

/// 暂停全部
- (IBAction)pauseAll:(id)sender {
    [[SODownloader musicDownloader]pauseAll];
}

/// 继续全部
- (IBAction)resumeAll:(id)sender {
    [[SODownloader musicDownloader]resumeAll];
}

/// 取消全部
- (IBAction)cancelAll:(id)sender {
    [[SODownloader musicDownloader]cancenAll];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == kDownloaderKVOContext) {
        NSInteger kind = [change[NSKeyValueChangeKindKey] integerValue];
        NSIndexSet * __unused indexSet = change[NSKeyValueChangeIndexesKey];
        NSArray *news = change[NSKeyValueChangeNewKey];
        
        NSString *list = [keyPath isEqualToString:SODownloaderDownloadArrayObserveKeyPath] ? @"下载队列" : @"已下载队列";
        NSString *type = kind == NSKeyValueChangeInsertion ? @"插入" : @"删除";
        SODebugLog(@"%@ %@ %@", list, type, news);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
