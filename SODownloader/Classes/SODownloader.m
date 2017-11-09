//
//  SODownloader.m
//  SODownloadExample
//
//  Created by scfhao on 16/6/17.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//

#import "SODownloader.h"
#import "AFNetworking.h"
#import "SODownloadResponseSerializer.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const SODownloaderNoDiskSpaceNotification = @"SODownloaderNoDiskSpaceNotification";

NSString * const SODownloaderDownloadArrayObserveKeyPath = @"downloadMutableArray";
NSString * const SODownloaderCompleteArrayObserveKeyPath = @"completeMutableArray";

static NSString * SODownloadProgressUserInfoStartTimeKey = @"SODownloadProgressUserInfoStartTime";
static NSString * SODownloadProgressUserInfoStartOffsetKey = @"SODownloadProgressUserInfoStartOffsetKey";

@interface SODownloader (DownloadPath)

- (void)createPath;
- (void)saveResumeData:(NSData *)resumeData forItem:(id<SODownloadItem>)item;
- (NSData *)resumeDataForItem:(id<SODownloadItem>)item;

@end

@interface SODownloader (DownloadNotify)

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadProgress:(double)downloadProgress;
- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadState:(SODownloadState)downloadState;
- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadSpeed:(NSInteger)downloadSpeed;
- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadError:(NSError *)error;

@end

@interface SODownloader (_DownloadControl)

- (void)_pauseAll;
- (void)_cancelItem:(id<SODownloadItem>)item remove:(BOOL)remove;

@end

@interface SODownloader ()

/// downloader identifier
@property (nonatomic, copy) NSString *downloaderIdentifier;
/// current download counts
@property (nonatomic, assign) NSInteger activeRequestCount;

@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong, readonly) NSMutableArray *downloadArrayWarpper;
@property (nonatomic, strong, readonly) NSMutableArray *completeArrayWarpper;
/// 下载项数组(包含等待中、下载中、暂停状态的下载项目)
@property (nonatomic, strong) NSMutableArray *downloadMutableArray;
/// 已下载项数组
@property (nonatomic, strong) NSMutableArray *completeMutableArray;

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;

// paths
@property (nonatomic, strong) NSString *downloaderPath;
// complete block
@property (nonatomic, copy) SODownloadCompleteBlock_t completeBlock;

@end

@implementation SODownloader

- (instancetype)initWithIdentifier:(NSString *)identifier timeoutInterval:(NSTimeInterval)timeoutInterval completeBlock:(SODownloadCompleteBlock_t)completeBlock {
    self = [super init];
    if (self) {
        NSString *queueLabel = [NSString stringWithFormat:@"cn.scfhao.downloader.synchronizationQueue-%@", [NSUUID UUID].UUIDString];
        self.synchronizationQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        NSURLSessionConfiguration *sessionConfiguration;
        if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 8.0) {
            sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
            sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
#pragma clang diagnostic pop
        }
        
#ifdef DEBUG
        if (timeoutInterval < 10) {
            NSLog(@"[SODownloader]: The timeoutInterval you set looks too short!");
        }
#endif
        sessionConfiguration.timeoutIntervalForRequest = timeoutInterval > 0 ? timeoutInterval: 15;
        
        self.sessionManager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:sessionConfiguration];
        self.sessionManager.responseSerializer = [SODownloadResponseSerializer serializer];

        self.downloaderIdentifier = identifier;
        self.completeBlock = completeBlock;
        self.downloaderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.downloaderIdentifier];
        
        self.tasks = [[NSMutableDictionary alloc]init];
        self.downloadMutableArray = [[NSMutableArray alloc]init];
        self.completeMutableArray = [[NSMutableArray alloc]init];
        
        [self createPath];
        _maximumActiveDownloads = 3;
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (NSMutableArray *)downloadArrayWarpper {
    return [self mutableArrayValueForKey:SODownloaderDownloadArrayObserveKeyPath];
}

- (NSMutableArray *)completeArrayWarpper {
    return [self mutableArrayValueForKey:SODownloaderCompleteArrayObserveKeyPath];
}

- (NSArray *)downloadArray {
    return [self.downloadMutableArray copy];
}

- (NSArray *)completeArray {
    return [self.completeMutableArray copy];
}

- (void)setAllowsCellularAccess:(BOOL)allowsCellularAccess {
    self.sessionManager.requestSerializer.allowsCellularAccess = allowsCellularAccess;
}

- (BOOL)allowsCellularAccess {
    return self.sessionManager.requestSerializer.allowsCellularAccess;
}

- (void)setAcceptableContentTypes:(NSSet<NSString *> *)acceptableContentTypes {
    [self.sessionManager.responseSerializer setAcceptableContentTypes:acceptableContentTypes];
}

- (NSSet<NSString *> *)acceptableContentTypes {
    return self.sessionManager.responseSerializer.acceptableContentTypes;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self.sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

- (void)setDidFinishEventsForBackgroundURLSessionBlock:(void (^)(NSURLSession *session))block {
    [self.sessionManager setDidFinishEventsForBackgroundURLSessionBlock:block];
}

- (void)setMaximumActiveDownloads:(NSInteger)maximumActiveDownloads {
    dispatch_sync(self.synchronizationQueue, ^{
        _maximumActiveDownloads = maximumActiveDownloads;
        [self startNextTaskIfNecessary];
    });
}

- (id<SODownloadItem>)filterItemUsingFilter:(SODownloadFilter_t)filter {
    if (!filter) { return nil; }
    __block id<SODownloadItem> item = nil;
    [self.downloadArrayWarpper enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (filter(obj)) {
            item = obj;
            *stop = YES;
        }
    }];
    if (item == nil) {
        [self.completeArrayWarpper enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (filter(obj)) {
                item = obj;
                *stop = YES;
            }
        }];
    }
    return item;
}

#pragma mark - 下载处理
/// 开始下载一个item，这个方法必须在同步线程中调用，且调用前必须先判断是否可以开始新的下载
- (void)startDownloadItem:(id<SODownloadItem>)item {
    [self notifyDownloadItem:item withDownloadState:SODownloadStateLoading];
    NSString *URLIdentifier = [item.so_downloadURL absoluteString];
    
    NSURLSessionDownloadTask *existingDownloadTask = self.tasks[URLIdentifier];
    if (existingDownloadTask) {
        return ;
    }
    NSURLSessionDownloadTask *downloadTask = nil;
    NSURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"GET" URLString:URLIdentifier parameters:nil error:nil];
    if (!request) {
        NSError *URLError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
        NSLog(@"SODownload fail %@", URLError);
        [self notifyDownloadItem:item withDownloadError:URLError];
        [self notifyDownloadItem:item withDownloadState:SODownloadStateError];
        [self startNextTaskIfNecessary];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:taskId];
        taskId = UIBackgroundTaskInvalid;
    }];
    // 创建下载完成的回调
    void (^completeBlock)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        dispatch_sync(self.synchronizationQueue, ^{
            if (error) {
                [strongSelf handleError:error forItem:item];
            } else {
                if (strongSelf.completeBlock == nil) {
                    [strongSelf.downloadArrayWarpper removeObject:item];
                    [strongSelf.completeArrayWarpper addObject:item];
                    [strongSelf notifyDownloadItem:item withDownloadState:SODownloadStateComplete];
                } else {
                    [strongSelf notifyDownloadItem:item withDownloadState:SODownloadStateProcess];
                    NSError *processError = strongSelf.completeBlock(strongSelf, item, filePath);
                    if (processError) {
                        [strongSelf handleError:processError forItem:item];
                    } else {
                        [strongSelf.downloadArrayWarpper removeObject:item];
                        [strongSelf.completeArrayWarpper addObject:item];
                        [strongSelf notifyDownloadItem:item withDownloadState:SODownloadStateComplete];
                    }
                }
            }
            [strongSelf removeTaskInfoForItem:item];
            [strongSelf startNextTaskIfNecessary];
        });
    };
    NSURL *(^destinationBlock)(NSURL *targetPath, NSURLResponse *response) = ^(NSURL *targetPath, NSURLResponse *response) {
        NSString *fileName = [targetPath lastPathComponent];
        NSString *destinationPath = [weakSelf.downloaderPath stringByAppendingPathComponent:fileName];
        return [NSURL fileURLWithPath:destinationPath];
    };
    // 创建task
    void (^progressBlock)(NSProgress *downloadProgress) = ^(NSProgress *downloadProgress) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        NSDictionary *progressInfo = downloadProgress.userInfo;
        NSNumber *startTimeValue = progressInfo[SODownloadProgressUserInfoStartTimeKey];
        NSNumber *startOffsetValue = progressInfo[SODownloadProgressUserInfoStartOffsetKey];
        if (startTimeValue) {
            CFAbsoluteTime startTime = [startTimeValue doubleValue];
            int64_t startOffset = [startOffsetValue longLongValue];
            NSInteger downloadSpeed = (NSInteger)((downloadProgress.completedUnitCount - startOffset) / (CFAbsoluteTimeGetCurrent() - startTime));
            [strongSelf notifyDownloadItem:item withDownloadSpeed:downloadSpeed];
        } else {
            [downloadProgress setUserInfoObject:@(CFAbsoluteTimeGetCurrent()) forKey:SODownloadProgressUserInfoStartTimeKey];
            [downloadProgress setUserInfoObject:@(downloadProgress.completedUnitCount) forKey:SODownloadProgressUserInfoStartOffsetKey];
        }
        [strongSelf notifyDownloadItem:item withDownloadProgress:downloadProgress.fractionCompleted];
    };
    NSData *resumeData = [self resumeDataForItem:item];
    if (resumeData) {
        downloadTask = [self.sessionManager downloadTaskWithResumeData:resumeData progress:progressBlock destination:destinationBlock completionHandler:completeBlock];
    } else {
        downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:progressBlock destination:destinationBlock completionHandler:completeBlock];
    }
    [self startDownloadTask:downloadTask forItem:item];
    if (taskId != UIBackgroundTaskInvalid) {
        [application endBackgroundTask:taskId];
        taskId = UIBackgroundTaskInvalid;
    }
}

- (void)handleError:(NSError *)error forItem:(id<SODownloadItem>)item {
    // 取消的情况在task cancel方法时处理，所以这里只需处理非取消的情况。
    BOOL handledError = NO;
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        // handle URL error
        switch (error.code) {
            case NSURLErrorCancelled:
                handledError = YES;
                break;
            default:
                break;
        }
    } else if ([error.domain isEqualToString:NSPOSIXErrorDomain]) {
        switch (error.code) {
            case 28: // No space left on device
                NSLog(@"[SODownloader]: There is no space to continue download.");
                [self _pauseAll];
                [[NSNotificationCenter defaultCenter]postNotificationName:SODownloaderNoDiskSpaceNotification object:self];
                break;
            default:
                break;
        }
    }
    if (!handledError) {
        if (self.autoCancelFailedItem) {
            [self _cancelItem:item remove:NO];
        } else {
            // 如果有临时文件，保存文件
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (resumeData) {
                [self saveResumeData:resumeData forItem:item];
            }
            [self notifyDownloadItem:item withDownloadError:error];
            [self notifyDownloadItem:item withDownloadState:SODownloadStateError];
        }
    }
}

#pragma mark - 同时下载数支持
- (void)startDownloadTask:(NSURLSessionDownloadTask *)downloadTask forItem:(id<SODownloadItem>)item {
    self.tasks[[item.so_downloadURL absoluteString]] = downloadTask;
    [downloadTask resume];
    ++self.activeRequestCount;
}

- (NSURLSessionDownloadTask *)downloadTaskForItem:(id<SODownloadItem>)item {
    return self.tasks[[item.so_downloadURL absoluteString]];
}

- (void)removeTaskInfoForItem:(id<SODownloadItem>)item {
    [self.tasks removeObjectForKey:[item.so_downloadURL absoluteString]];
    --self.activeRequestCount;
}

/// 尝试开始更多下载，需要在同步队列中执行
- (void)startNextTaskIfNecessary {
    for (id<SODownloadItem>item in self.downloadArrayWarpper) {
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            if (item.so_downloadState == SODownloadStateWait) {
                [self startDownloadItem:item];
            }
        } else {
            break;
        }
    }
}

- (BOOL)isActiveRequestCountBelowMaximumLimit {
    return self.activeRequestCount < self.maximumActiveDownloads;
}

@end

@implementation SODownloader (DownloadPath)

- (void)createPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exist = [fileManager fileExistsAtPath:self.downloaderPath isDirectory:&isDir];
    if (!exist || !isDir) {
        NSError *error;
        [fileManager createDirectoryAtPath:self.downloaderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"SODownloader create downloaderPath fail!");
        }
    }
}

- (NSString *)resumePathForItem:(id<SODownloadItem>)item {
    NSString *tempFileName = [[self pathForDownloadURL:[item so_downloadURL]]stringByAppendingPathExtension:@"download"];
    return [self.downloaderPath stringByAppendingPathComponent:tempFileName];
}

- (void)saveResumeData:(NSData *)resumeData forItem:(id<SODownloadItem>)item {
    [resumeData writeToFile:[self resumePathForItem:item] atomically:YES];
}

/*
 NSURLSessionResumeInfoVersion 与 iOS 版本对应
 1 ----------- iOS 7
 2 ----------- iOS 8、iOS 9、iOS 10
 4 ----------- iOS 11
 */
- (NSData *)resumeDataForItem:(id<SODownloadItem>)item {
    NSString *resumePath = [self resumePathForItem:item];
    if ([[NSFileManager defaultManager]fileExistsAtPath:resumePath]) {
        NSDictionary *resumeInfo = [NSDictionary dictionaryWithContentsOfFile:resumePath];
        NSInteger resumeInfoVersion = [resumeInfo[@"NSURLSessionResumeInfoVersion"] integerValue];
        NSString *tempPath = nil;
        switch (resumeInfoVersion) {
            case 1:
                tempPath = resumeInfo[@"NSURLSessionResumeInfoLocalPath"];
                break;
            default:
            {
                NSString *tempFileName = resumeInfo[@"NSURLSessionResumeInfoTempFileName"];
                if (tempFileName) {
                    tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
                } else {
                    NSLog(@"不支持的 resumeInfoVersion %@, 请前往 https://github.com/scfhao/SODownloader/issues 反馈", @(resumeInfoVersion).stringValue);
                }
            }
                break;
        }
        if (tempPath && [[NSFileManager defaultManager]fileExistsAtPath:tempPath]) {
            NSData *resumeData = [NSData dataWithContentsOfFile:resumePath];
            [[NSFileManager defaultManager]removeItemAtPath:resumePath error:nil];
            return resumeData;
        } else {
#ifdef DEBUG
            NSLog(@"没有找到文件：%@", tempPath);
#endif
        }
    } else {
#ifdef DEBUG
        NSLog(@"没有找到文件：%@", resumePath);
#endif
    }
    return nil;
}

- (NSString *)pathForDownloadURL:(NSURL *)url {
    NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return [output copy];
}
 
@end

@implementation SODownloader (DownloadNotify)

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadState:(SODownloadState)downloadState {
    if ([item respondsToSelector:@selector(setSo_downloadState:)]) {
        item.so_downloadState = downloadState;
    } else {
        NSLog(@"下载模型必须实现setDownloadState:才能获取到正确的下载状态！");
    }
}

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadProgress:(double)downloadProgress {
    if ([item respondsToSelector:@selector(setSo_downloadProgress:)]) {
        item.so_downloadProgress = downloadProgress;
    } else {
        NSLog(@"下载模型必须实现setDownloadProgress:才能获取到正确的下载进度！");
    }
}

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadError:(NSError *)error {
    if ([item respondsToSelector:@selector(setSo_downloadError:)]) {
        item.so_downloadError = error;
    }
}

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadSpeed:(NSInteger)downloadSpeed {
    if ([item respondsToSelector:@selector(setSo_downloadSpeed:)]) {
        item.so_downloadSpeed = downloadSpeed;
    }
}

@end

#pragma mark - Download Control
@implementation SODownloader (DownloadControl)
/// 下载
- (void)downloadItem:(id<SODownloadItem>)item {
    [self downloadItem:item autoStartDownload:YES];
}

- (void)downloadItems:(NSArray<SODownloadItem>*)items {
    [self downloadItems:items autoStartDownload:YES];
}

- (void)downloadItem:(id<SODownloadItem>)item autoStartDownload:(BOOL)autoStartDownload {
    if ([self isControlDownloadFlowForItem:item]) {
        NSLog(@"SODownloader: %@ already in download flow!", item);
        return;
    }
    if (item.so_downloadState != SODownloadStateNormal) {
        NSLog(@"SODownloader only download item in normal state: %@", item);
        return;
    }
    if (![item respondsToSelector:@selector(so_downloadURL)] || ![item so_downloadURL]) {
        NSLog(@"SODownloader: Class<%@> must implements method so_downloadURL and return a valid URL!", NSStringFromClass([item class]));
        return;
    }
    dispatch_sync(self.synchronizationQueue, ^{
        [self.downloadArrayWarpper addObject:item];
        if (autoStartDownload) {
            [self notifyDownloadItem:item withDownloadState:SODownloadStateWait];
            if ([self isActiveRequestCountBelowMaximumLimit]) {
                [self startDownloadItem:item];
            }
        } else {
            [self notifyDownloadItem:item withDownloadState:SODownloadStatePaused];
        }
    });
}

- (void)downloadItems:(NSArray<SODownloadItem> *)items autoStartDownload:(BOOL)autoStartDownload {
    dispatch_sync(self.synchronizationQueue, ^{
        NSMutableArray *itemsCanBeDownload = [[NSMutableArray alloc]initWithCapacity:items.count];
        for (id<SODownloadItem>item in items) {
            if ([self isControlDownloadFlowForItem:item]) {
                NSLog(@"SODownloader: %@ already in download flow!", item);
                continue;
            }
            if (item.so_downloadState != SODownloadStateNormal) {
                NSLog(@"SODownloader only download item in normal state: %@", item);
                continue;
            }
            if (![item respondsToSelector:@selector(so_downloadURL)] || ![item so_downloadURL]) {
                NSLog(@"SODownloader: Class<%@> must implements method so_downloadURL and return a valid URL!", NSStringFromClass([item class]));
                continue;
            }
            [itemsCanBeDownload addObject:item];
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.downloadMutableArray.count, [itemsCanBeDownload count])];
        [self.downloadArrayWarpper insertObjects:itemsCanBeDownload atIndexes:indexSet];
        if (autoStartDownload) {
            for (id<SODownloadItem> item in itemsCanBeDownload) {
                [self notifyDownloadItem:item withDownloadState:SODownloadStateWait];
            }
            [self startNextTaskIfNecessary];
        } else {
            for (id<SODownloadItem> item in itemsCanBeDownload) {
                [self notifyDownloadItem:item withDownloadState:SODownloadStatePaused];
            }
        }
    });
}

#pragma mark - 暂停下载相关方法
/// 暂停
- (void)pauseItem:(id<SODownloadItem>)item {
    if (![self isControlDownloadFlowForItem:item]) {
        NSLog(@"SODownloader: can't pause a item not in control of SODownloader!");
        return;
    }
    dispatch_sync(self.synchronizationQueue, ^{
        [self _pauseItem:item];
    });
}

/// 暂停全部
- (void)pauseAll {
    dispatch_sync(self.synchronizationQueue, ^{
        [self _pauseAll];
    });
}

- (void)_pauseAll {
    for (id<SODownloadItem>item in self.downloadArrayWarpper) {
        [self _pauseItem:item];
    }
}

- (void)_pauseItem:(id<SODownloadItem>)item {
    if (item.so_downloadState == SODownloadStateLoading || item.so_downloadState == SODownloadStateWait) {
        [self _pauseTaskForItem:item saveResumeData:YES];
        [self notifyDownloadItem:item withDownloadState:SODownloadStatePaused];
    }
}

#pragma mark 取消下载相关方法
- (void)cancelItem:(id<SODownloadItem>)item {
    if (![self isControlDownloadFlowForItem:item]) {
        NSLog(@"SODownloader: can't cancel a item not in control of SODownloader!");
        return;
    }
    [self _cancelItemSafely:item remove:YES];
}

- (void)_cancelItemSafely:(id<SODownloadItem>)item remove:(BOOL)remove {
    dispatch_sync(self.synchronizationQueue, ^{
        [self _cancelItem:item remove:remove];
    });
}

- (void)cancelItems:(NSArray<SODownloadItem> *)items {
    dispatch_sync(self.synchronizationQueue, ^{
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        for (id<SODownloadItem>item in items) {
            if ([self.downloadMutableArray containsObject:item]) {
                [self _cancelItem:item remove:NO];
                [indexSet addIndex:[self.downloadMutableArray indexOfObject:item]];
            }
        }
        [self.downloadArrayWarpper removeObjectsAtIndexes:indexSet];
    });
}

- (void)cancenAll {
    dispatch_sync(self.synchronizationQueue, ^{
        for (id<SODownloadItem>item in self.downloadMutableArray) {
            [self _cancelItem:item remove:NO];
        }
        [self.downloadArrayWarpper removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.downloadMutableArray count])]];
    });
}

- (void)_cancelItem:(id<SODownloadItem>)item remove:(BOOL)remove {
    [self _pauseTaskForItem:item saveResumeData:NO];
    [self notifyDownloadItem:item withDownloadState:SODownloadStateNormal];
    [self notifyDownloadItem:item withDownloadProgress:0];
    if (remove && [self.downloadMutableArray count]) {
        [self.downloadArrayWarpper removeObject:item];
    }
}

/// 继续
- (void)resumeItem:(id<SODownloadItem>)item {
    if (![self isControlDownloadFlowForItem:item]) {
        NSLog(@"SODownloader: can't resume a item not in control of SODownloader!");
        return;
    }
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.so_downloadState == SODownloadStatePaused || item.so_downloadState == SODownloadStateError) {
            if ([self isActiveRequestCountBelowMaximumLimit]) {
                [self startDownloadItem:item];
            } else {
                [self notifyDownloadItem:item withDownloadState:SODownloadStateWait];
            }
        }
    });
}

- (void)resumeAll {
    for (id<SODownloadItem>item in self.downloadMutableArray) {
        [self resumeItem:item];
    }
}

- (void)removeAllCompletedItems {
    dispatch_sync(self.synchronizationQueue, ^{
        for (id<SODownloadItem>item in self.completeMutableArray) {
            [self notifyDownloadItem:item withDownloadProgress:0];
            [self notifyDownloadItem:item withDownloadState:SODownloadStateNormal];
        }
        [self.completeArrayWarpper removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.completeMutableArray count])]];
    });
}

- (void)removeCompletedItem:(id<SODownloadItem>)item {
    dispatch_sync(self.synchronizationQueue, ^{
        if ([self.completeMutableArray containsObject:item]) {
            [self.completeArrayWarpper removeObject:item];
            [self notifyDownloadItem:item withDownloadProgress:0];
            [self notifyDownloadItem:item withDownloadState:SODownloadStateNormal];
        }
    });
}

- (void)markItemsAsComplate:(NSArray<SODownloadItem> *)items {
    dispatch_sync(self.synchronizationQueue, ^{
        NSMutableArray *itemsToMarkComplete = [[NSMutableArray alloc]initWithCapacity:items.count];
        for (id<SODownloadItem>item in items) {
            if (![self isControlDownloadFlowForItem:item]) {
                [self notifyDownloadItem:item withDownloadProgress:1];
                [self notifyDownloadItem:item withDownloadState:SODownloadStateComplete];
                [itemsToMarkComplete addObject:item];
            }
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.completeMutableArray.count, itemsToMarkComplete.count)];
        [self.completeArrayWarpper insertObjects:itemsToMarkComplete atIndexes:indexSet];
    });
}

/// 判断item是否在当前的downloader的控制下，用于条件判断
- (BOOL)isControlDownloadFlowForItem:(id<SODownloadItem>)item {
    return [self.downloadMutableArray containsObject:item] || [self.completeMutableArray containsObject:item];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    dispatch_sync(self.synchronizationQueue, ^{
        for (id<SODownloadItem> item in self.downloadArray) {
            [self _pauseTaskForItem:item saveResumeData:YES];
        }
    });
}

- (void)_pauseTaskForItem:(id<SODownloadItem>)item saveResumeData:(BOOL)save {
    if (item.so_downloadState == SODownloadStateLoading) {
        NSURLSessionDownloadTask *downloadTask = [self downloadTaskForItem:item];
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (save && resumeData) {
                [self saveResumeData:resumeData forItem:item];
            }
        }];
    }
}

@end
