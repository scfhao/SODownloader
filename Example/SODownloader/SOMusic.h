//
//  SOMusic.h
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  SOMusic.{h, m}: 对要下载的模型的封装，示例如何让自己的模型类支持 SODownloader 进行下载。

#import <Foundation/Foundation.h>
#import "SODownloadItem.h"

// 我用于测试的音乐文件个数
#define TestMusicCount 42

@interface SOMusic : NSObject<SODownloadItem>

@property (assign, readonly, nonatomic) NSInteger index;

+ (NSArray <SOMusic *>*)allMusicList;

/// 音乐文件下载目标位置
- (NSString *)savePath;

@end
