//
//  SODownloadViewController.m
//  SODownloadExample
//
//  Created by scfhao on 16/7/1.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  SODownloadViewController.{h, m}: 已下载列表界面示例，对已下载列表进行监听并刷新界面。

#import "SODownloadViewController.h"
#import "SODownloader+MusicDownloader.h"
#import "SOLog.h"
#import "SOMusic.h"

static void * kDownloaderCompleteArrayKVOContext = &kDownloaderCompleteArrayKVOContext;

@interface SODownloadViewController ()

@property (copy, nonatomic) NSArray *dataArray;

@end

@implementation SODownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 注册对“已下载”列表的观察，当“已下载”列表发生变化时（新增、删除、替换）时，本类中的 -observeValueForKeyPath:ofObject:change:context:方法将被执行。
    // 可以用相同的方式对 “下载队列” 进行监听
    [[SODownloader musicDownloader]addObserver:self forKeyPath:SODownloaderCompleteArrayObserveKeyPath options:NSKeyValueObservingOptionNew context:kDownloaderCompleteArrayKVOContext];
    
    self.tableView.allowsSelection = NO;
    self.dataArray = [SODownloader musicDownloader].completeArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    // 移除对"已下载"列表的观察
    [[SODownloader musicDownloader]removeObserver:self forKeyPath:SODownloaderCompleteArrayObserveKeyPath];
}

- (IBAction)clear:(id)sender {
    [[SODownloader musicDownloader]removeAllCompletedItems];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    SOMusic *music = self.dataArray[indexPath.row];
    cell.textLabel.text = [music description];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SOMusic *music = self.dataArray[indexPath.row];
        // 删除单个已下载的项目
        [[SODownloader musicDownloader]removeCompletedItem:music];
    }
}

#pragma mark - KVO
/**
 *  当“已下载”列表发生变化时，这个方法会执行，这里用于通知界面进行刷新
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == kDownloaderCompleteArrayKVOContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger kind = [change[NSKeyValueChangeKindKey] integerValue];
            NSIndexSet *indexSet = change[NSKeyValueChangeIndexesKey];
            NSArray *news = change[NSKeyValueChangeNewKey];
            
            switch (kind) {
                case NSKeyValueChangeInsertion:     // 插入，代表新的下载完成任务
                {
                    NSInteger index = [indexSet firstIndex];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    NSMutableArray *temp = [self.dataArray mutableCopy];
                    [temp insertObject:[news lastObject] atIndex:index];
                    self.dataArray = temp;
                    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                    break;
                case NSKeyValueChangeRemoval:       // 移除，代表一个已经下载任务被删除
                {
                    NSMutableArray *temp = [self.dataArray mutableCopy];
                    [temp removeObjectsAtIndexes:indexSet];
                    self.dataArray = temp;
                    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:indexSet.count];
                    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                    }];
                    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                    break;
                default:
                    // 其实这里可以不做任何判断，直接调用[tableView reloadData]会更简单些，上面的分支用于展示对已下载列表的变化进行更精细的处理
                    [self.tableView reloadData];
                    break;
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
