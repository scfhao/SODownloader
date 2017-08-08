//
//  SODownloadItem.h
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  可下载模型

#import <Foundation/Foundation.h>

/**
 将自定义的模型对象用于SODownloader时，可以通过两种途径实现（二选一即可）：
 
 - 将需要下载的model类集成SODownloadItem类。
 - 将需要下载的model类实现SODownloadItem协议。
 
 继承SODownloadItem类或实现SODownloadItem协议的类即可用于下载。不管选择哪种形式，必须实现：
 - (NSURL *)downloadURL;

 如果选择实现SODownloadItem协议而不继承SODownloadItem类时，必须同时为so_downloadProgress、so_downloadState属性合成setter、getter方法（自动或手动合成）
 
 更进一步：为了能达到最佳效果，建议可下载模型实现下面的方法，（如果没有实现这两个方法，当有多个item代表相同的资源时，这多个item都可以添加到下载列表中，实现这两个方法后可以避免出现这种情况）：
 - (NSUInteger)hash
 - (BOOL)isEqual:(id)object
 
 > 注意：通过KVO监听so_downloadProgress、so_downloadState属性属性时，需要自行保证在主线程中执行UI操作。
 */

/*!
 @enum 下载状态
 SODownloadStateProcess，这个状态与下载无关，如果下载完一个文件后需要对下载的文件进行一些处理，例如解压、解密或其他操作时，SODownloader 将处于这个操作流程中的下载项的状态定义为 SODownloadStateProcess，特殊处理操作完成后，下载状态变为 SODownloadStateComplete，否则变为 SODownloadStateError。
 */
typedef NS_ENUM(NSUInteger, SODownloadState) {
    /* 默认状态，不会下载 */
    SODownloadStateNormal,
    /* 等待下载 */
    SODownloadStateWait,
    /* 正在下载 */
    SODownloadStateLoading,
    /* 下载暂停 */
    SODownloadStatePaused,
    /* 定制处理 */
    SODownloadStateProcess,
    /* 下载完成 */
    SODownloadStateComplete,
    /* 下载失败 */
    SODownloadStateError,
};

NS_ASSUME_NONNULL_BEGIN

@protocol SODownloadItem <NSObject>

@optional
/// 下载进度，支持KVO
@property (assign, nonatomic) double so_downloadProgress;
/// 下载状态，支持KVO，该属性的值由 SODownloader 维护，调用 SODownloader 类的下载相关方法可以使该属性值改变，不要自己修改这个属性的值。
@property (assign, nonatomic) SODownloadState so_downloadState;
/// 下载速度，单位是字节/秒
@property (assign, nonatomic) NSUInteger so_downloadSpeed;
/// 当下载失败时，此属性保存失败错误对象
@property (strong, nonatomic, nullable) NSError *so_downloadError;

@required
/// 返回下载项对应的下载地址
- (NSURL *)so_downloadURL;

@end

@interface SODownloadItem : NSObject<SODownloadItem>

@end

NS_ASSUME_NONNULL_END
