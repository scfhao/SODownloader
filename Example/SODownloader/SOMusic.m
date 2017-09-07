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

@interface SOMusic ()

@property (assign, nonatomic) NSInteger index;

@end

@implementation SOMusic
@synthesize so_downloadProgress, so_downloadState = _so_downloadState, so_downloadError, so_downloadSpeed = _so_downloadSpeed;

+ (NSArray <SOMusic *>*)allMusicList {
    static NSArray *array = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *musicList = [[NSMutableArray alloc]initWithCapacity:TestMusicCount];
        for (NSInteger index = 0; index < TestMusicCount; index++) {
            [musicList addObject:[self musicAtIndex:index]];
        }
        array = [musicList copy];
    });
    return array;
}

+ (instancetype)musicAtIndex:(NSInteger)index {
    return [[self alloc]initWithIndex:index];
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
        case SODownloadStateLoading:
            SODebugLog(@"开始下载：%@", [self description]);
            break;
        case SODownloadStateComplete:
            SODebugLog(@"下载完成：%@", [self description]);
            break;
        case SODownloadStateError:
            SODebugLog(@"下载失败：%@ | %@", [self description], self.so_downloadError);
            break;
        case SODownloadStateNormal:
            if ([[NSFileManager defaultManager]fileExistsAtPath:[self savePath]]) {
                // 清理下载的文件
                [[NSFileManager defaultManager]removeItemAtPath:[self savePath] error:nil];
            }
            break;
        default:
            break;
    }
}

#pragma mark - SODownloadItem必须实现的方法
/**
 我测试用的下载文件放在本地的Apache服务器上，Mac 上自带Apache，很方便当测试用的 HTTP 文件服务器。
 本地环境：macOS Sierra 10.12.3，启用 Apache 作为文件服务器的的步骤如下（以我测试下载的情况为例）：
 1. 将要下载的文件放在 Apache 的 Documents 路径（/Library/WebServer/Documents/）下。这个默认的 Documents 路径可以改成别的，但如果你是初次使用 Apache，建议直接用这个默认的路径好了。如果把要下载的文件（比如file.ex）直接放到这个 Documents 目录中，下载地址就是（http://localhost/file.ex）。
 2. 打开终端，执行`sudo apachectl start`启动 Apache 服务器。
 3. 没有第三步了，很简单的。
- (NSURL *)so_downloadURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://192.168.2.1/Music/xuan/%@.mp3", @(self.index).stringValue]];
}
 */
- (NSURL *)so_downloadURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://omy5nu09z.bkt.clouddn.com/%@.mp3", @(self.index).stringValue]];
}

#pragma mark - SODownloadItem建议实现的方法
/**
 实现下面这两个方法用于判断两个对象相等。这两个方法一般不会被直接调用，而是间接的调用，比如在集合（NSArray、NSSet等）中的相关方法（比如indexOfObject、containsObject等）中被间接调用。
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

@end
