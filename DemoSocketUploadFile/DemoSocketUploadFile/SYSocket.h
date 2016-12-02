//
//  SYSocket.h
//  zhangshaoyu
//
//  Created by zhangshaoyu on 15/9/22.
//  Copyright (c) 2015年 zhangshaoyu. All rights reserved.
//  socket断点上传文件

#import <Foundation/Foundation.h>

/// 掉线类型（服务端掉线，或用户主动退出）
typedef NS_ENUM(NSInteger, SocketDisconnectType)
{
    /// 服务器掉线，默认为0
    SocketOfflineByServer = 0,
    
    /// 用户主动cut
    SocketOfflineByUser = 1
};

@interface SYSocket : NSObject

/// 掉线类型
@property (nonatomic, assign) SocketDisconnectType disconnecType;

/// 文件路径
@property (nonatomic, copy) NSString *filePath;

/// 单例
+ (SYSocket *)sharedSocket;

/// socket连接
- (void)socketConnectWithHost:(NSString *)host port:(UInt16)port;

/// socket连接断开
- (void)socketDisconnect;

/// GCDSocket连接
- (void)GCDSocketConnectWithHost:(NSString *)host port:(UInt16)port;;

/// GCDSocket连接断开
- (void)GCDSocketDisconnect;

@end
