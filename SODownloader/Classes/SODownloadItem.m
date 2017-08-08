//
//  SODownloadItem.m
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//

#import "SODownloadItem.h"

@implementation SODownloadItem
@synthesize so_downloadState, so_downloadProgress;

- (NSURL *)so_downloadURL {
    NSAssert(NO, @"[SODownloader]:Your download item class must implements -(NSURL *)downloadURL method declare in protocol SODownloadItem");
    return nil;
}

@end
