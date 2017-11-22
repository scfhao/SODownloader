# SODownloader

[![CI Status](http://img.shields.io/travis/scfhao/SODownloader.svg?style=flat)](https://travis-ci.org/scfhao/SODownloader)
[![Version](https://img.shields.io/cocoapods/v/SODownloader.svg?style=flat)](http://cocoapods.org/pods/SODownloader)
[![License](https://img.shields.io/cocoapods/l/SODownloader.svg?style=flat)](http://cocoapods.org/pods/SODownloader)
[![Platform](https://img.shields.io/cocoapods/p/SODownloader.svg?style=flat)](http://cocoapods.org/pods/SODownloader)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

SODownloader base on [AFNetworking 3](https://github.com/AFNetworking/AFNetworking), if you are using AFNetworking 2.x, you should grade your AFNetworking dependency.

## Installation

SODownloader is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SODownloader"
```

## Usage

使用方法参考[Wiki](https://github.com/scfhao/SODownloader/wiki)，如果 SODownloader 对你有所帮助，别忘了点击本项目右上角的 Star！

## Help

目前 SODownloader Demo 中下载的文件托管在七牛云存储上，大家在运行 Demo 下载 Demo 中的 mp3 文件时会在七牛云存储上产生费用，所以请大家运行此 Demo 程序时，请先将 SOMusic.m 文件中的下载链接换成自己的链接进行测试。

同时征集适合用于测试下载用的云存储方案，如果有合适的，请一定要推荐给我！满足以下的条件就行：

1. 可以上传用于测试下载的文件上去。
2. 要下载的文件的下载链接是固定不变的。
3. 服务器支持 Content-Lenght 响应头。

没有注册过七牛云存储的朋友，可以通过这个[链接](https://portal.qiniu.com/signup?code=3lc4jrwodxqoh)注册七牛云存储，完成实名认证后，我就可以有更多的免费流量用于供大家测试使用。

## Author

scfhao@126.com

> 邮件联系 scfhao 询问 SODownloader 的使用问题前，请先看完 [Wiki](https://github.com/scfhao/SODownloader/wiki) 中的内容。

## License

SODownloader is available under the MIT license. See the LICENSE file for more info.
