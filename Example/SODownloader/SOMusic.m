//
//  SOMusic.m
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  SOMusic.{h, m}: 对要下载的模型的封装，示例如何让自己的模型类支持 SODownloader 进行下载。

#import "SOMusic.h"
#import "SOLog.h"
#import "SODownloader.h"
#import "SOSimulateDB.h"
#import "SODownloader+MusicDownloader.h"

@interface SOMusic ()

@property (assign, nonatomic) NSInteger index;

@end

@implementation SOMusic
@synthesize so_downloadProgress, so_downloadState = _so_downloadState, so_downloadError, so_downloadSpeed = _so_downloadSpeed;

// 这个数组模拟应用从网络中获取到一个可下载文件列表
+ (NSArray <SOMusic *>*)allMusicList {
    NSMutableArray *musicList = [[NSMutableArray alloc]initWithCapacity:TestMusicCount];
    for (NSInteger index = 0; index < TestMusicCount; index++) {
        [musicList addObject:[self musicAtIndex:index]];
    }
    return [musicList copy];
}

+ (instancetype)musicAtIndex:(NSInteger)index {
    // 这样可以获取到之前已经添加到 SODownloader 中的一个下载模型
    SOMusic *musicAlreadyInDownloader = (SOMusic *)[[SODownloader musicDownloader]filterItemUsingFilter:^BOOL(id<SODownloadItem>  _Nonnull item) {
        SOMusic *music = (SOMusic *)item;
        return music.index == index;
    }];
    // 判断一下 SODownloader 里是否已经存在一个同样的模型，如果存在就返回那个已有的，不存在就可以重新创建一个
    if (musicAlreadyInDownloader) {
        return musicAlreadyInDownloader;
    } else {
        return [[self alloc]initWithIndex:index];
    }
}

- (instancetype)initWithIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        self.index = index;
    }
    return self;
}

- (NSString *)savePath {
    return [[[[self class]musicDownloadFolder]stringByAppendingPathComponent:@(self.index).stringValue]stringByAppendingPathExtension:@"mp3"];
}

+ (NSString *)musicDownloadFolder {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSString *downloadFolder = [documents stringByAppendingPathComponent:@"musics"];
    [self handleDownloadFolder:downloadFolder];
    return downloadFolder;
}

/// 处理下载文件夹：1.保证文件夹存在。 2.为此文件夹设置备份属性，避免占用过多用户iCloud容量。
+ (void)handleDownloadFolder:(NSString *)folder {
    BOOL isDir = NO;
    BOOL folderExist = [[NSFileManager defaultManager]fileExistsAtPath:folder isDirectory:&isDir];
    if (!folderExist || !isDir) {
        [[NSFileManager defaultManager]createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
        NSURL *fileURL = [NSURL fileURLWithPath:folder];
        [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
}

- (void)setSo_downloadState:(SODownloadState)so_downloadState {
    _so_downloadState = so_downloadState;
    switch (so_downloadState) {
        case SODownloadStateNormal:
            if ([[NSFileManager defaultManager]fileExistsAtPath:[self savePath]]) {
                // 清理下载的文件
                [[NSFileManager defaultManager]removeItemAtPath:[self savePath] error:nil];
            }
            break;
        default:
            break;
    }
    SOCustomDebugLog(@"<Progress>", @"%@", @(self.so_downloadProgress.fractionCompleted).stringValue);
    [SOSimulateDB save:self];
}

#pragma mark - SODownloadItem必须实现的方法
/// 这个方法返回该模型对应的文件的下载地址
- (NSURL *)so_downloadURL {
    switch (self.index) {
        case 0:     return [NSURL URLWithString:@"https://userfilecenter.oss-cn-hangzhou.aliyuncs.com/5c2dacce9bd1160017fb1dc9/ca018999ebed44f19482d74691da8118.mp4"];
        case 1:     return [NSURL URLWithString:@"https://userfilecenter.oss-cn-hangzhou.aliyuncs.com/5c2e135419b90933783e4127/dc405321267046c1b1d2d6e9d187d0d7.mp4"];
        case 2:     return [NSURL URLWithString:@"https://userfilecentertest.oss-cn-hangzhou.aliyuncs.com/5caeea8324aa9a000e937be7/8e6ee1b4c0db4f19b4dac4a585c6c35d.mp4"];
        default:    return nil;
    }
}

#pragma mark - SODownloadItem建议实现的方法
/**
 实现下面这两个方法用于判断两个对象相等。这两个方法一般不会被直接调用，而是间接的调用，比如在集合（NSArray、NSSet等）中的相关方法（比如indexOfObject、containsObject等）中被间接调用。
 了解更多关于这两个方法的内容可以看我写的这个 [WiKi](https://github.com/scfhao/SODownloader/wiki/%E4%BF%9D%E8%AF%81%E4%B8%8B%E8%BD%BD%E5%AF%B9%E8%B1%A1%E7%9A%84%E5%94%AF%E4%B8%80%E6%80%A7)
 */
- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[SOMusic class]]) {
        return [super isEqual:object];
    }
    // 如果self和object代表同一个对象，比如这两个对象内存地址不同，但是所有的属性值都相等，对于 SODownloader 来说，就是下载地址相同时返回 YES，否则返回 NO。
    SOMusic *music = (SOMusic *)object;
    return self.index == music.index;
}

/**
 为相等的对象返回相同的hash值，为不相等的对象返回不同的hash值。
 */
- (NSUInteger)hash {
    return [@(self.index) hash];
}

/**
 这个方法和下载没关系，当你在打印一个对象的时候，打印出来的是一个对象的类名和内存地址，没有可读性。实现了这个方法后，当用%@形式打印一个对象，或者用 po 调试命令打印对象时，打印出来的就不再是指针，而是你的 description 方法返回的字符串，这样你就可以知道你的对象的内容。
 */
- (NSString *)description {
    return [NSString stringWithFormat:@"[Music:%@]", @(self.index).stringValue];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.index = [coder decodeIntegerForKey:NSStringFromSelector(@selector(index))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.index forKey:NSStringFromSelector(@selector(index))];
}

@end
