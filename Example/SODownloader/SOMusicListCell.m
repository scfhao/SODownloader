//
//  SOMusicListCell.m
//  SODownloadExample
//
//  Created by scfhao on 16/6/20.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  SOMusicListCell.{h, m}: 示例如果对下载进度进行监听并更新界面

#import "SOMusicListCell.h"

static void * kStateContext = &kStateContext;
static void * kProgressContext = &kProgressContext;
static void * kSpeedContext = &kSpeedContext;

@implementation SOMusicListCell

- (void)configureMusic:(SOMusic *)music {
    self.titleLabel.text = [music description];
    [self updateState:music.so_downloadState];
    self.progressView.progress = music.so_downloadProgress;
    self.music = music;
//    self.backgroundColor = [UIColor whiteColor];
}

- (void)updateState:(SODownloadState)state {
    switch (state) {
        case SODownloadStateWait:
            self.stateLabel.text = @"等待中";
            break;
        case SODownloadStatePaused:
            self.stateLabel.text = @"已暂停";
            break;
        case SODownloadStateError:
            self.stateLabel.text = @"失败";
            break;
        case SODownloadStateLoading:
            self.stateLabel.text = @"下载中";
            break;
        case SODownloadStateProcess:
            self.stateLabel.text = @"处理中";
            break;
        case SODownloadStateComplete:
            self.stateLabel.text = @"已下载";
            break;
        default:
            self.stateLabel.text = @"未下载";
            break;
    }
    self.speedLabel.hidden = state != SODownloadStateLoading;
}

/**
 注意这个方法，当参数 music 为 nil 时，调用此方法可移除对之前设置的 music 的下载状态的观察。
 更多关于 UITableViewCell+KVO 需要注意的地方参考 SOMusicListViewController.m 文件。
 */
- (void)setMusic:(SOMusic *)music {
    if (_music) {
        [_music removeObserver:self forKeyPath:@__STRING(so_downloadState)];
        [_music removeObserver:self forKeyPath:@__STRING(so_downloadProgress)];
        [_music removeObserver:self forKeyPath:@__STRING(so_downloadSpeed)];
    }
    _music = music;
    if (_music) {
        [_music addObserver:self forKeyPath:@__STRING(so_downloadState) options:NSKeyValueObservingOptionNew context:kStateContext];
        [_music addObserver:self forKeyPath:@__STRING(so_downloadProgress) options:NSKeyValueObservingOptionNew context:kProgressContext];
        [_music addObserver:self forKeyPath:@__STRING(so_downloadSpeed) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:kSpeedContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == kStateContext) {
        SODownloadState newState = [change[NSKeyValueChangeNewKey]integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateState:newState];
        });
    } else if (context == kProgressContext) {
        double newProgress = [change[NSKeyValueChangeNewKey]doubleValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = newProgress;
        });
    } else if (context == kSpeedContext) {
        NSNumber *value = change[NSKeyValueChangeNewKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ((NSNull *)value == [NSNull null]) {
                self.speedLabel.text = @"0 Byte/s";
            } else {
                NSInteger speed = [value integerValue];
                if (speed < 1024) {
                    self.speedLabel.text = [NSString stringWithFormat:@"%li Byte/s", speed];
                } else if (speed < 1024 * 1024) {
                    self.speedLabel.text = [NSString stringWithFormat:@"%li kb/s", speed / 1024];
                } else {
                    self.speedLabel.text = [NSString stringWithFormat:@"%li mb/s", speed / 1024 * 1024];
                }
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
