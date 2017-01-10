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

/*
 实现原理步骤说明
 1、第一次调用socket时
 1-1、设置服务器地址、端口号；
 1-2、获取本地缓存的文件偏移量；
 1-3、初始化socket；
 1-4、连接服务器；
 1-4-1、连接成功：开始上传文件
 1-4-1-1、构建头文件协议；
 1-4-1-2、发送头文件协议到服务器，并获取服务器返回数据；
 1-4-1-3、上传成功后，将接收到的的对应头文件协议进行解析，并获取当前文件偏移量
 1-4-2、连接失败：断开连接
 1-4-2-1、关闭文件操作；
 1-4-2-2、断开socket连接，取消代理设置；

 2、再次调用socket时，上传文件信息
 2-1、初始化NSFileHandle
 2-2、设置文件偏移量
 2-3、根据文件偏移量，读取文件信息
 2-4、发服务器发送文件信息
 3、停止发送文件信息，或发送文件信息完成
 
 注意：
 1、使用GCDSocket进行网络操作；
 2、使用NSFileHandle进行文件操作；
 3、根据实际情况修改头文件发送格式，以及解析接收的头文件信息
 
*/
