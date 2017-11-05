//
//  SOSimulateDB.h
//  SODownloader_Example
//
//  Created by 张豪 on 2017/11/5.
//  Copyright © 2017年 scfhao. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SOMusic;
/**
 为了使整个 Demo 的功能更加完善，SimulateDB 类演示保存下载任务状态的功能。
 大家在看 SOSimulateDB 类的代码的时候，可以“假装”这是一个数据库 :P
 当你在你的项目中使用 SODownloader 完成下载功能时，要用你应用中的持久化方案（CoreData、FMDB等）代替 SimulateDB 的功能。
 */
@interface SOSimulateDB : NSObject

/// 保存一个下载任务的下载状态，当一个下载任务的下载状态改变的时候就需要保存到磁盘
+ (void)save:(SOMusic *)music;
/// 获取数据库中记录的处于下载中的任务数组
+ (NSArray *)downloadingMusicArrayInDB;
/// 获取数据库中记录的处于暂停状态的任务数组
+ (NSArray *)pausedMusicArrayInDB;
/// 获取数据库中记录的已下载的任务数组
+ (NSArray *)complatedMusicArrayInDB;

@end
