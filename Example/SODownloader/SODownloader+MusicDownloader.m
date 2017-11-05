//
//  SODownloader+MusicDownloader.m
//  SODownloadExample
//
//  Created by scfhao on 16/9/9.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  SODownloader+MusicDownloader.{h, m}: 示例如何创建 SODownloader 对象，如何在下载完进行自定义处理。

#import "SODownloader+MusicDownloader.h"
#import "SOLog.h"
#import "SOMusic.h"
#import "SOSimulateDB.h"

@implementation SODownloader (MusicDownloader)

/// 创建下载器单例对象及其初始化，使用单例保证程序一次运行期间会且只创建一个 SODownloader 对象，对其配置操作在这里进行即可。
+ (instancetype)musicDownloader {
    static SODownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 创建下载器对象
        downloader = [[SODownloader alloc]initWithIdentifier:@"music" timeoutInterval:20.0 completeBlock:^NSError *(SODownloader * _Nonnull downloader, id<SODownloadItem>  _Nonnull item, NSURL * _Nonnull location) {
            // 这个block每下载成功一个文件时被调用，这个block在后台线程中调用，不建议在这里做更新UI的操作
            // 你可以在这里对下载成功做特别的处理，例如：
            // 1. 把下载完成的 item 的信息存入数据库
            // 2. 把下载完成的文件从 location 位置移动到你想要保存到的文件夹
            
            // 下面这几行代码示例：将下载成功的文件移动到目标下载位置
            SOMusic *music = (SOMusic *)item;
            NSError *error;
            BOOL result = [[NSFileManager defaultManager]moveItemAtURL:location toURL:[NSURL fileURLWithPath:music.savePath] error:&error];
            if (!result) {
                NSLog(@"下载处理失败：%@", [error localizedDescription]);
            }
            return error;
        }];
        // 设置同时下载数目
        NSNumber *maximumActiveDownloads = [[NSUserDefaults standardUserDefaults]objectForKey:kMaximumActiveDownloadsKey];
        if (maximumActiveDownloads) {
            downloader.maximumActiveDownloads = [maximumActiveDownloads integerValue];
        } else {
            downloader.maximumActiveDownloads = 1;
        }
        
        NSNumber *allowsCellularAccess = [[NSUserDefaults standardUserDefaults]objectForKey:kAllowsCellularAccessKey];
        if (allowsCellularAccess) {
            downloader.allowsCellularAccess = [allowsCellularAccess boolValue];
        } else {
            // 默认情况下，AFNetworking 运行蜂窝网络访问
            downloader.allowsCellularAccess = YES;
        }
        
        //-------------------------恢复之前的下载状态----------------------------
        // SODownloader 不负责保存下载状态，因为不同应用中使用的持久化方案因人而异，所以 SODownloader 仅提供简化下载封装，持久化工作交由使用 SODownloader 的用户自由定制，你可以使用 FMDB、CoreData 等持久化方案。
        // 每次应用重新启动，包括后台下载任务完成后应用被唤起时，需要为重新创建的 SODownloader 对象恢复上次应用运行结束前的状态。
        
        // 恢复已下载项目的状态，下面的代码仅作示例
        NSArray *downloadedArray = [SOSimulateDB complatedMusicArrayInDB];
        [downloader markItemsAsComplate:(NSArray<SODownloadItem> *)downloadedArray];
        
        // 恢复等待、下载中状态的项目，后面的参数传 YES 会使下载器自动继续下载上次程序退出时正在下载的项目
        NSArray *itemsDownloadImmediately = [SOSimulateDB downloadingMusicArrayInDB];
        [downloader downloadItems:(NSArray<SODownloadItem> *)itemsDownloadImmediately autoStartDownload:YES];
        
        // 恢复程序上次运行时处于暂停状态的项目，后面的参数 NO 保证这些项目继续处于暂停状态
        NSArray *pausedItems = [SOSimulateDB pausedMusicArrayInDB];
        [downloader downloadItems:(NSArray<SODownloadItem> *)pausedItems autoStartDownload:NO];
    });
    return downloader;
}

@end
