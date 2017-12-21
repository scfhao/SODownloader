//
//  NSTimer+SODownloader.h
//  SODownloader
//
//  Created by mac on 2017/12/21.
//

#import <Foundation/Foundation.h>

@interface NSTimer (SODownloader)

/// 参考scheduledTimerWithTimeInterval, 使用 weak 防止循环引用
+ (NSTimer *)so_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(NSTimer *timer))inBlock repeats:(BOOL)inRepeats;
/// 参考timerWithTimeInterval, 使用 weak 方式循环引用
+ (NSTimer *)so_timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(NSTimer *timer))inBlock repeats:(BOOL)inRepeats;

@end
