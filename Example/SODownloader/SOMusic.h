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

// 这个属性只是我用来区分我的音频对象的，你的模型对象中是不需要这个属性的。
@property (assign, readonly, nonatomic) NSInteger index;

+ (NSArray <SOMusic *>*)allMusicList;

/// 音乐文件下载目标位置
- (NSString *)savePath;

- (instancetype)initWithIndex:(NSInteger)index;
+ (instancetype)musicAtIndex:(NSInteger)index;

@end
