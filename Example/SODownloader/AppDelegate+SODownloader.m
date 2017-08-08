//
//  AppDelegate+SODownloader.m
//  SODownloadExample
//
//  Created by scfhao on 16/9/12.
//  Copyright © 2016年 http://scfhao.coding.me/blog All rights reserved.
//
/**
    使用 SODownloader 实现后台下载功能仅需如下几步：
    ===============================
    1. 实现 AppDelegate 中的`-application:handleEventsForBackgroundURLSession:completionHandler:`方法，如本文件所示，这里需要注意 identifier 参数和 SODownloader 对象的一致性。
    2. SODownloader 对象的状态恢复。
 
    从 iOS 7 开始，Apple 的网络框架中提供了 NSURLSession 及其相关的类，其中的后台 session 允许应用在后台下载数据（甚至是应用被挂起或杀死的情况下仍然继续下载）。所以 NSURLBackgroundSession 已经可以处理基本的下载及下载状态恢复功能。一些极端情况，比如手机关机，下载才会被中断，但我个人认为这种极端情况并不会对用户体验造成多大的影响，由手机关机引起的下载失败正常用户是可以体谅的。在网上看到一些人为了应对这种极端状况，而做了“每个几秒暂停一次下载以保存下载状态”的处理，个人认为这都是多此一举。
 
    SODownloader 是在 AFNetworking 之上的下载封装，而 AFNetworking(中的 AFURLSessionManager) 是 NSURLSession 的代理方法封装。应用被挂起后，如果应用中存在后台下载会话，系统会接管下载会话，当一个下载任务完成时，系统会在后台换起应用并调用其 AppDelegate 的响应方法（即步骤1中需要实现的方法），因为应用被挂起后所占内存会被系统回收，所以在后台被唤起时相当于刚启动时的状态，上次启动时创建的 SODownloader 对象已不复存在，所以这里需要创建一个和之前一摸一样的 SODownloader 对象，这就是步骤2中提到的“SODownloader 对象的状态恢复”，这里使用单例就再合适不过了，可以参考 SODownloadExample 中的 SODownloader+MusicDownloader 类实现。
 */

#import "AppDelegate+SODownloader.h"
#import "SODownloader+MusicDownloader.h"
#import "SOLog.h"

@implementation SOAppDelegate (SODownloader)

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    SODebugLog(@"%@", NSStringFromSelector(_cmd));
#warning 根据identifier找到下载管理器，如果是后台下载事件，交由下载管理器处理
    if ([identifier isEqualToString:@"music"]) {
        [[SODownloader musicDownloader] setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession * _Nonnull session) {
            completionHandler();
        }];
    } else {
        // 处理其他的后台会话事件
    }
}

@end
