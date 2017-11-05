//
//  SOSimulateDB.m
//  SODownloader_Example
//
//  Created by 张豪 on 2017/11/5.
//  Copyright © 2017年 scfhao. All rights reserved.
//

#import "SOSimulateDB.h"
#import "SOMusic.h"

@interface SOSimulateDB ()

@property (copy, nonatomic) NSMutableIndexSet *downloadingIndexSet;
@property (copy, nonatomic) NSMutableIndexSet *pausedIndexSet;
@property (copy, nonatomic) NSMutableIndexSet *complatedIndexSet;

@end

@implementation SOSimulateDB

+ (instancetype)sharedDB {
    static SOSimulateDB *_db = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[NSFileManager defaultManager]fileExistsAtPath:[self dbFile]]) {
            _db = [NSKeyedUnarchiver unarchiveObjectWithFile:[self dbFile]];
        } else {
            _db = [SOSimulateDB new];
        }
    });
    return _db;
}

+ (NSString *)dbFile {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [documents stringByAppendingPathComponent:@"simulate.db"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadingIndexSet = [NSMutableIndexSet indexSet];
        _pausedIndexSet = [NSMutableIndexSet indexSet];
        _complatedIndexSet = [NSMutableIndexSet indexSet];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _downloadingIndexSet = [coder decodeObjectOfClass:[NSMutableIndexSet class] forKey:NSStringFromSelector(@selector(downloadingIndexSet))];
        _pausedIndexSet = [coder decodeObjectOfClass:[NSMutableIndexSet class] forKey:NSStringFromSelector(@selector(pausedIndexSet))];
        _complatedIndexSet = [coder decodeObjectOfClass:[NSMutableIndexSet class] forKey:NSStringFromSelector(@selector(complatedIndexSet))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.downloadingIndexSet forKey:NSStringFromSelector(@selector(downloadingIndexSet))];
    [coder encodeObject:self.pausedIndexSet forKey:NSStringFromSelector(@selector(pausedIndexSet))];
    [coder encodeObject:self.complatedIndexSet forKey:NSStringFromSelector(@selector(complatedIndexSet))];
}

// 这个方法用于保存
+ (void)save:(SOMusic *)music {
    [[SOSimulateDB sharedDB]save:music];
    [NSKeyedArchiver archiveRootObject:[SOSimulateDB sharedDB] toFile:[self dbFile]];
}

- (void)save:(SOMusic *)music {
    switch (music.so_downloadState) {
        case SODownloadStateWait:
        case SODownloadStateLoading:
            [self.downloadingIndexSet addIndex:music.index];
            [self.pausedIndexSet removeIndex:music.index];
            [self.complatedIndexSet removeIndex:music.index];
            break;
        case SODownloadStatePaused:
            [self.downloadingIndexSet removeIndex:music.index];
            [self.pausedIndexSet addIndex:music.index];
            [self.complatedIndexSet removeIndex:music.index];
            break;
        case SODownloadStateComplete:
            [self.downloadingIndexSet removeIndex:music.index];
            [self.pausedIndexSet removeIndex:music.index];
            [self.complatedIndexSet addIndex:music.index];
            break;
        case SODownloadStateNormal:
            [self.downloadingIndexSet removeIndex:music.index];
            [self.pausedIndexSet removeIndex:music.index];
            [self.complatedIndexSet removeIndex:music.index];
        default:
            break;
    }
}

/// 获取出于下载中状态的音乐
+ (NSArray *)downloadingMusicArrayInDB {
    SOSimulateDB *db = [self sharedDB];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:db.downloadingIndexSet.count];
    [db.downloadingIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:[[SOMusic alloc]initWithIndex:idx]];
    }];
    return [array copy];
}

+ (NSArray *)pausedMusicArrayInDB {
    SOSimulateDB *db = [self sharedDB];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:db.pausedIndexSet.count];
    [db.pausedIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:[[SOMusic alloc]initWithIndex:idx]];
    }];
    return [array copy];
}

+ (NSArray *)complatedMusicArrayInDB {
    SOSimulateDB *db = [self sharedDB];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:db.complatedIndexSet.count];
    [db.complatedIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:[[SOMusic alloc]initWithIndex:idx]];
    }];
    return [array copy];
}

@end
