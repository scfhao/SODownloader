//
//  SOAppDelegate.h
//  SODownloader
//
//  Created by scfhao on 08/08/2017.
//  Copyright (c) 2017 scfhao. All rights reserved.
//

//  **************************** 说明 *****************************
//  SODownloader 托管在 GitHub:( https://github.com/scfhao/SODownloader/ ) 和 Coding:( https://coding.net/u/scfhao/p/SODownloader/git )
//  在使用 SODownloader 的过程中发现问题或遇到 SODownloader 没有实现的下载通用功能可以在 GitHub 或 Coding 中的 Issue 中提出，也欢迎提交 pull request。
//  **************************************************************
/**
 本 Demo 用于展示 SODownloader 的使用方法，这里对 Demo 中的文件结构做个介绍，当你尝试阅读这个项目的时候，可能会对你有所帮助。
 
 ExampleClasses: 示例工程用到的类文件，仅作示例使用，当你要在自己的项目中使用 SODownloader 时，无需将这这个文件夹中的类添加到自己的项目中。
 ViewController:
 SOSimpleDownloadViewController.{h, m}: 示例如何直接使用 AFNetworking 进行下载。
 SOMusicListViewController.{h, m}: 下载列表界面示例，这里有对下载的开始、暂停、继续、取消等功能的示例。
 SODownloadViewController.{h, m}: 已下载列表界面示例，对已下载列表进行监听并刷新界面。
 SODownloadSettingViewController.{h, m}: 设置界面示例，示例下载设置操作。
 Model:
 SOMusic.{h, m}: 对要下载的模型的封装，示例如何让自己的模型类支持 SODownloader 进行下载。
 SODownloader+MusicDownloader.{h, m}: 示例如何创建 SODownloader 对象，如何在下载完进行自定义处理。
 View:
 SOMusicListCell.{h, m}: 示例如果对下载进度进行监听并更新界面
 
 SODownloader: SODownloader 对下载的封装，使用 SODownloader 时，需要将此文件中的类加入自己的项目，基本不需要修改里面的代码。
 SODownloader.{h, m}: SODownloader 下载功能的主要逻辑。
 SODownloadItem.{h, m}: 对下载项的封装。
 AppDelegate+SODownloader.{h, m}: 如果需要处理后台下载时，需要实现这里面的方法。
 SODownloaderResponseSerializer.{h, m}: 对 AFNetworking 的下载扩展，不需要修改。
 */

@import UIKit;

@interface SOAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
