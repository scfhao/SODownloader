//
//  SODownloader+MusicDownloader.h
//  SODownloadExample
//
//  Created by scfhao on 16/9/9.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  SODownloader+MusicDownloader.{h, m}: 示例如何创建 SODownloader 对象，如何在下载完进行自定义处理。

#define kMaximumActiveDownloadsKey @"MusicDownloaderMaximumActiveDownloadsUserDefaultsKey"
#define kAllowsCellularAccessKey @"MusicDownloaderAllowsCellularAccessUserDefaultsKey"

#import "SODownloader.h"

@interface SODownloader (MusicDownloader)

+ (instancetype)musicDownloader;

@end
