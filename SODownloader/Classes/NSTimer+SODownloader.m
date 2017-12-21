//
//  NSTimer+SODownloader.m
//  SODownloader
//
//  Created by mac on 2017/12/21.
//

#import "NSTimer+SODownloader.h"

@interface NSTimer (SODownloaderPrivate)
+ (void)so_executeBlockFromTimer:(NSTimer *)aTimer;
@end

@implementation NSTimer (SODownloader)
+ (id)so_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(NSTimer *timer))block repeats:(BOOL)inRepeats
{
  NSParameterAssert(block != nil);
  return [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(so_executeBlockFromTimer:) userInfo:[block copy] repeats:inRepeats];
}

+ (id)so_timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(NSTimer *timer))block repeats:(BOOL)inRepeats
{
  NSParameterAssert(block != nil);
  return [self timerWithTimeInterval:inTimeInterval target:self selector:@selector(so_executeBlockFromTimer:) userInfo:[block copy] repeats:inRepeats];
}

+ (void)so_executeBlockFromTimer:(NSTimer *)aTimer {
  void (^block)(NSTimer *) = [aTimer userInfo];
  if (block) block(aTimer);
}
@end
