//
//  SOLog.h
//  SOKit https://coding.net/u/scfhao/p/SOKit/git
//
//  Created by scfhao on 16/8/12.
//  Copyright © 2016年 scfhao. All rights reserved.
//  分级Log

#ifndef SOLog_h
#define SOLog_h

typedef NS_ENUM(NSUInteger, SOLogLevel) {
    SOLogLevelVerbose,  /* 啰嗦级，可以打印网络请求及响应内容 */
    SOLogLevelDebug,    /* 调试级，可以打印调试信息，一般的调试日志就用这个 */
    SOLogLevelInfo,     /* 如果是比较重要的日志，可以用这个级别 */
    SOLogLevelWarn,     /* 警告级别，打印警告信息 */
    SOLogLevelError,    /* 错误级别，打印错误信息 */
};

/**
 定义默认应用的日志行为
 DEBUG模式下打印所有级别的日志
 RELEASE模式只打印Info及更高级别的日志
 */
#ifdef DEBUG
#define SO_LOG_LEVEL SOLogLevelVerbose
#else 
#define SO_LOG_LEVEL SOLogLevelInfo
#endif

/**
 @brief 打印日志基础函数
 @description 建议直接使用下面定义的变种更方便哦，见SOVerboseLog, SODebugLog, SOInfoLog, SOWarnLog, SOErrorLog
 @param logLevel 本条日志所属的日志级别，根据本条日志的重要性在SOLogLevel中选择一个
 @param head 日志打印的前缀标示
 @param fmt, ... 格式化字符串及可变参数，同NSLog函数的参数
 */
#define SOLog(logLevel, head, fmt, ...) do{ if (SO_LOG_LEVEL <= logLevel) NSLog(@"%@: "fmt, head, ##__VA_ARGS__); } while(0)

// 便捷调用方法
#define SOVerboseLog(fmt, ...)              SOLog(SOLogLevelVerbose, @"[Verbose]", fmt, ##__VA_ARGS__)
#define SODebugLog(fmt, ...)                SOLog(SOLogLevelDebug, @"[Debug]", fmt, ##__VA_ARGS__)
#define SOInfoLog(fmt, ...)                 SOLog(SOLogLevelInfo, @"[Info]", fmt, ##__VA_ARGS__)
#define SOWarnLog(fmt, ...)                 SOLog(SOLogLevelWarn, @"[Warn]", fmt, ##__VA_ARGS__)
#define SOErrorLog(fmt, ...)                SOLog(SOLogLevelError, @"[Error]", fmt, ##__VA_ARGS__)
#define SOCustomDebugLog(key, fmt, ...)     SOLog(SOLogLevelDebug, key, fmt, ##__VA_ARGS__)

#endif /* SOLog_h */
