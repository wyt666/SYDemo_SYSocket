//
//  SYSocket.h
//  zhangshaoyu
//
//  Created by zhangshaoyu on 15/9/22.
//  Copyright (c) 2015年 zhangshaoyu. All rights reserved.
//  socket断点上传文件

#import <Foundation/Foundation.h>

@interface SYSocket : NSObject


/// 文件路径（先设置要上传的文件路径，然后再连接服务器进行上传）
@property (nonatomic, copy) NSString *filePath;

/// 单例
+ (SYSocket *)sharedSocket;

/// socket连接（先设置要上传的文件路径，然后再连接服务器进行上传）
- (void)socketConnectWithHost:(NSString *)host port:(UInt16)port;

/// socket连接断开
- (void)socketDisconnect;

/// GCDSocket连接（先设置要上传的文件路径，然后再连接服务器进行上传）
- (void)GCDSocketConnectWithHost:(NSString *)host port:(UInt16)port;;

/// GCDSocket连接断开
- (void)GCDSocketDisconnect;

@end
