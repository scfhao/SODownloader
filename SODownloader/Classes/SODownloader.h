//
//  SODownloader.h
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me/blog All rights reserved.
//

#import "SODownloadItem.h"
@class SODownloader;

NS_ASSUME_NONNULL_BEGIN

/**
 @brief 下载处理回调
 
 当SODownloader完成下载一个item时，将调用此block回调用户，用户通过设置此block实现来对已下载对象进行处理。例如：将已下载的文件移动到想要的位置、或对其进行解密等其他处理操作。
 这个block中快照的对象需要做weak处理，防止造成内存泄漏。
 @return 处理失败时可将错误对象返回。SODownloader 根据此返回值确定下载成功还是失败。
 @param item 下载项对象
 @param location 文件位置，这个位置位于临时目录，所以用户需从此目录将文件移动到Documents、Library、Cache等目录。此block调用完后，SODownloader会自动移除该位置的文件。
 */
typedef NSError *_Nullable(^SODownloadCompleteBlock_t)(SODownloader *downloader, id<SODownloadItem> item, NSURL *location);

/**
 用于从SODownloader的下载列表和已完成列表中筛选下载项。
 */
typedef BOOL(^SODownloadFilter_t)(id<SODownloadItem> item);

/**
 @interface SODownloader
 下载工具类，基于AFURLSessionManager。
 用于下载模型化对象（SODownloadItem），对于其他下载需求，建议直接使用AFNetworking进行下载。
 */
@interface SODownloader : NSObject

/// 每个下载器都有一个唯一标识符，不同的下载器应使用不同的标识符
@property (nonatomic, copy, readonly) NSString *downloaderIdentifier;
/// 最大下载数
@property (nonatomic, assign) NSInteger maximumActiveDownloads;

#pragma mark - 相关数组
/**
 @brief 下载项数组(包含等待中、下载中、暂停状态的下载项目)
 @description 不可变数组，外部无法对此数组进行增、删、改
 @see SODownloaderDownloadArrayObserveKeyPath 外部可通过 KVO 对此数组的内容变化进行观察
 */
@property (nonatomic, strong, readonly) NSArray *downloadArray;

/**
 @brief 已下载项数组
 @description 不可变数组，外部无法对此数组进行增、删、改
 @see SODownloaderCompleteArrayObserveKeyPath 外部可通过 KVO 对此数组的内容变化进行观察
 */
@property (nonatomic, strong, readonly) NSArray *completeArray;

#pragma mark - 创建/初始化
/**
 为该identifier创建一个downloader。
 @return identifier对应的downloader
 @param identifier 要获取的downloader的标识符，这个标识符还将被用于downloader临时文件路径名和urlSession的identifier。
 @param timeoutInterval 下载超时时间，当一个下载任务在指定时间未接收到下载数据，会超时，建议大于10s。
 @param completeBlock 完成回调，downloader每完成一个item时会调用此block，此block在非主线程中被调用，如果在block中进行UI操作，需要注意切换到主线程执行。另外也需要注意Block的循环引用问题。
 */
- (instancetype)initWithIdentifier:(NSString *)identifier timeoutInterval:(NSTimeInterval)timeoutInterval completeBlock:(SODownloadCompleteBlock_t)completeBlock;

/**
 对象置换：
 在应用中同一条数据可能会有多份对象(比如已完成列表中已有一个代表同一项目的对象，然后在某一列表界面从网络获取到一个文件列表)，这时可能会需要获取SODownloader中的那个具备正确下载状态的对象。
 */
- (id<SODownloadItem>)filterItemUsingFilter:(SODownloadFilter_t)filter;

/**
 错误处理。
 由于下载这项功能的特殊性，如果下载失败，解救的手段有限。SODownloader将下载失败的情况分为两类：
 1. 可以重新下载。对于这种情况，SODownloader会自动重新下载该下载项。
 2. 无法重新下载。例如远程资源根本不存在，重新下载也是白忙。
 3. 其他错误也可以归类到1或2中，如遇到可以继续下载的其他错误，可以在 https://github.com/scfhao/SODownloader/issues 提出。
 将autoCancelFailedItem 属性置为YES时（默认为NO），当一个下载项下载失败且SODownloader无法处理时，自动取消下载该下载项，下载项的下载状态将被置为Normal；默认情况下（此属性为NO时），下载状态被置为Error，下载项的so_downloadError属性将被赋值。
 */
@property (nonatomic, assign) BOOL autoCancelFailedItem;

@property (nonatomic, assign) BOOL allowsCellularAccess;

#pragma mark - 后台下载支持
- (void)setDidFinishEventsForBackgroundURLSessionBlock:(void (^)(NSURLSession *session))block;

#pragma mark - HTTP 定制
/**
 下载文件接受类型
 此属性默认为nil，可接收任意类型的文件。
 可以为此属性设置一个可接收类型集合，当下载文件的response中的MIME-Type不符合时，SODownloader将判定其下载失败。
 */
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

/**
 @brief 设置下载请求使用的 HTTP Header。
 @description 需要时，可以使用此方法设置 HTTP Header，比如设置 User-Agent，或其他 Header。
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;

@end

/// 下载管理相关
@interface SODownloader (DownloadControl)

#pragma mark - 下载管理
/**
 @brief 将 item 加入下载列表
 @param item 要加入下载列表的模型对象，需要实现 SODownloadItem 协议。
 @see downloadItem:autoStartDownload:
 */
- (void)downloadItem:(id<SODownloadItem>)item;

/**
 @brief 将 item 加入下载列表
 @param item 要加入下载列表的模型对象，需要实现 SODownloadItem 协议。
 @param autoStartDownload 是否自动开始下载
 @see downloadItems:autoStartDownload:
 @description 应用重启后，将上次程序运行时未下载完成的项目通过此方法告诉 SODownloader 对象，对于上次程序挂起前处于暂停状态的项目，autoStartDownload参数传入NO；对于上次程序挂起前处于等待和下载中状态的项目，autoStartDownload参数传入YES。对于上次程序挂起前已下载的项目，调用`markItemsAsComplete:`方法将其标记为已下载。
 */
- (void)downloadItem:(id<SODownloadItem>)item autoStartDownload:(BOOL)autoStartDownload;

/**
 @brief 将 items 加入下载列表
 @param items 要加入下载列表的模型对象数组，需要实现 SODownloadItem 协议。
 @see downloadItems:autoStartDownload:
 */
- (void)downloadItems:(NSArray<SODownloadItem>*)items;

/**
 @brief 将 items 数组加入下载列表
 @param items 要加入下载列表的模型对象，需要实现 SODownloadItem 协议。
 @param autoStartDownload 是否自动开始下载
 @see downloadItems:autoStartDownload:
 @description 应用重启后，将上次程序运行时未下载完成的项目通过此方法告诉 SODownloader 对象，对于上次程序挂起前处于暂停状态的项目，autoStartDownload参数传入NO；对于上次程序挂起前处于等待和下载中状态的项目，autoStartDownload参数传入YES。对于上次程序挂起前已下载的项目，调用`markItemsAsComplete:`方法将其标记为已下载。
 */
- (void)downloadItems:(NSArray<SODownloadItem> *)items autoStartDownload:(BOOL)autoStartDownload;

/// 暂停：用于等待或下载中状态的项目
- (void)pauseItem:(id<SODownloadItem>)item;
- (void)pauseAll;
/// 继续：用于已暂停或失败状态的下载项
- (void)resumeItem:(id<SODownloadItem>)item;
- (void)resumeAll;
/// 取消：用于取消下载列表中尚未下载完成的项目
- (void)cancelItem:(id<SODownloadItem>)item;
- (void)cancelItems:(NSArray<SODownloadItem>*)items;
- (void)cancenAll;

/// 将之前下载的对象通过此方法告诉 SODownloader，SODownloader 对象会将其标记为已下载
- (void)markItemsAsComplate:(NSArray<SODownloadItem>*)items;
/// 删除：删除已下载的项目
- (void)removeCompletedItem:(id<SODownloadItem>)item;
- (void)removeAllCompletedItems;

/// 判断该item是否在当前的downloader对象的下载列表或完成列表中
- (BOOL)isControlDownloadFlowForItem:(id<SODownloadItem>)item;

@end

#pragma mark - KVO
/**
 要对下载队列进行监控，最佳的方式就是使用 KVO 了，SODownloader 提供了两个对下载队列进行监控的 KeyPath，其中，观察`SODownloaderDownloadArrayObserveKeyPath`可以对 SODownloader 对象的 downloadArray 代表的数组进行监控；观察`SODownloaderCompleteArrayObserveKeyPath`可以对 SODownloader 对象的 completeArray 代表的数组进行监控。可以参考 SODownloadExample 中的已下载界面 SODownloadViewController 中对此的用法。
 */
/// SODownloader 对象的 downloadArray 属性对应的 Observe KeyPath
FOUNDATION_EXPORT NSString * const SODownloaderDownloadArrayObserveKeyPath;
/// SODownloader 对象的 completeArray 属性对应的 Observe KeyPath
FOUNDATION_EXPORT NSString * const SODownloaderCompleteArrayObserveKeyPath;

#pragma mark - Notifications
/// 当设备剩余空间不足、无法继续下载时，SODownloader 会暂停全部下载并发送此通知。
FOUNDATION_EXPORT NSString * const SODownloaderNoDiskSpaceNotification;

NS_ASSUME_NONNULL_END
