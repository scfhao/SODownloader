//
//  SOMusicListCell.h
//  SODownloadExample
//
//  Created by scfhao on 16/6/20.
//  Copyright © 2016年 http://scfhao.coding.me/blog/ All rights reserved.
//  SOMusicListCell.{h, m}: 示例如果对下载进度进行监听并更新界面

#import <UIKit/UIKit.h>
#import "SOMusic.h"

@interface SOMusicListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;


@property (weak, nonatomic) SOMusic *music;

- (void)configureMusic:(SOMusic *)music;

@end
