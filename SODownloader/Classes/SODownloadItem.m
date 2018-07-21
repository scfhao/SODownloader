//
//  SODownloadItem.m
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//

#import "SODownloadItem.h"

NSString * const SODownloadItemProgressObserveKeyPath = @"so_downloadProgress.fractionCompleted";
NSString * const SODownloadItemStateObserveKeyPath = @"so_downloadState";
NSString * const SODownloadItemSpeedObserveKeyPath = @"so_downloadSpeed";

@implementation SODownloadItem
@synthesize so_downloadState, so_downloadProgress, so_downloadSpeed, so_downloadError;

- (NSURL *)so_downloadURL {
    NSAssert(NO, @"[SODownloader]:Your download item class must implements -(NSURL *)downloadURL method declare in protocol SODownloadItem");
    return nil;
}

@end
