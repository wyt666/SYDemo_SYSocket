//
//  SYSocket.m
//  zhangshaoyu
//
//  Created by zhangshaoyu on 15/9/22.
//  Copyright (c) 2015年 zhangshaoyu. All rights reserved.
//

#import "SYSocket.h"
#import "AsyncSocket.h"
#import "GCDAsyncSocket.h"

/// 掉线类型（服务端掉线，或用户主动退出）
typedef NS_ENUM(NSInteger, SocketDisconnectType)
{
    /// 服务器掉线，默认为0
    SocketOfflineByServer = 0,
    
    /// 用户主动cut
    SocketOfflineByUser = 1
};

unsigned long long OffSet = 1024 * 200;

static NSInteger const timeWithout = -1;
static NSInteger const tagWriteData = 1;
static NSInteger const tagReadData = 2;

static NSString *const keyOffset = @"keyOffset";
static NSString *const keySouceId = @"keySouceId";

@interface SYSocket () <AsyncSocketDelegate, GCDAsyncSocketDelegate>

/// 掉线类型
@property (nonatomic, assign) SocketDisconnectType disconnecType;

@property (nonatomic, strong) GCDAsyncSocket *GCDSocket;
@property (nonatomic, strong) AsyncSocket *socket;  // socket
@property (nonatomic, copy) NSString *socketHost;   // socket的Host
@property (nonatomic, assign) UInt16 socketPort;    // socket的prot
@property (nonatomic, strong) NSTimer *socketTimer; // 计时器

@property (nonatomic, assign) BOOL isUploadHead;                // 文件上传头文件协议
@property (nonatomic, assign) unsigned long long filelength;    // 文件上传大小
@property (nonatomic, strong) NSString *fileName;               // 文件上传名称
@property (nonatomic, strong) NSString *fileSouceId;            // 文件上传id
@property (nonatomic, strong) NSFileHandle *fileHandle;         // 文件操作
@property (nonatomic, assign) unsigned long long currentOffset; // 当前累计读取文件大小

@end

@implementation SYSocket

/// 单例
+ (SYSocket *)sharedSocket
{
    static SYSocket *sharedInstace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstace = [[self alloc] init];
    });
    
    return sharedInstace;
}

#pragma mark - setter

- (void)setDisconnecType:(SocketDisconnectType)disconnecType
{
    _disconnecType = disconnecType;
    self.socket.userData = _disconnecType;
}

#pragma mark - asyncSocket连接掉线操作

// socket连接
- (void)socketConnectWithHost:(NSString *)host port:(UInt16)port
{
    if (!host || 0 >= host.length)
    {
        return;
    }
    
    NSAssert(host != nil, @"host must be not nil");
    NSAssert(self.filePath != nil, @"filePath must be not nil");
    
    self.socketHost = host;
    self.socketPort = port;
    
    // 在连接前先进行手动断开
    self.disconnecType = SocketOfflineByUser;
    [self socketDisconnect];
    // 确保断开后再连，如果对一个正处于连接状态的socket进行连接，会出现崩溃
    self.disconnecType = SocketOfflineByServer;
    
    [self socketConnect];
}

// 连接
- (void)socketConnect
{
    /*
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
        // 处理耗时操作的代码块...
        self.isUploadHead = YES;
        
//        NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:keyOffset];
//        self.currentOffset = number.longLongValue;
        self.currentOffset = 0;
        
        self.socket = [[AsyncSocket alloc] initWithDelegate:self];
        NSError *error = nil;
        [self.socket connectToHost:self.socketHost onPort:self.socketPort withTimeout:3 error:&error];
        
//        //通知主线程刷新
//        dispatch_async(dispatch_get_main_queue(), ^{
//            //回调或者说是通知主线程刷新， 
//        });
    });
    */
    
    self.isUploadHead = YES;
    
    // 获取已经上传完成的记录
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:keyOffset];
    self.currentOffset = number.longLongValue;
//    self.currentOffset = 0;
    
    // 实例化AsyncSocket
    self.socket = [[AsyncSocket alloc] initWithDelegate:self];
    
    // 连接服务器
    NSError *error = nil;
    [self.socket connectToHost:self.socketHost onPort:self.socketPort withTimeout:timeWithout error:&error];
}

// socket断开连接
- (void)socketDisconnect
{
    [self stopTimerWithGCDSocket:NO];
}

#pragma mark - AsyncSocketDelegate

// 连接成功回调
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"socket连接成功");
    
//    // 获取服务端返回数据
//    [self.socket readDataWithTimeout:timeWithout tag:tagReadData];
    
    // 每隔30s像服务器发送心跳包
    // 在longConnectToSocket方法中进行长连接需要向服务器发送的讯息
    [self startTimerWithGCDSocket:NO];
}

// 重连
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"sorry the connect is failure %ld",sock.userData);
    if (SocketOfflineByServer == self.socket.userData)
    {
        // 服务器掉线，重连
        [self socketConnect];
    }
    else if (SocketOfflineByUser == self.socket.userData)
    {
        // 如果由用户断开，不进行重连
        return;
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"sock read");
    
    // 对得到的data值进行解析与转换即可
    [self fileInfoWithData:data];
    
    /*
    if (tagReadData == tag)
    {
        // 对得到的data值进行解析与转换即可
        NSString *receiveStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"receiveStr %@", receiveStr);
        NSArray *receiveArray = [receiveStr componentsSeparatedByString:@";"];
        NSString *sourceid = [receiveArray firstObject];
        NSRange rangeSource = [sourceid rangeOfString:@"sourceid="];
        self.fileSouceId = [sourceid substringFromIndex:(rangeSource.location + rangeSource.length)];
        
        NSString *position = [receiveArray lastObject];
        NSRange rangePosition = [position rangeOfString:@"position="];
        self.currentOffset = [position substringFromIndex:(rangePosition.location + rangePosition.length)].integerValue;
        
        [self startTimer:NO];
    }
    */
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"sock wirte");
    
    if (tagWriteData == tag)
    {
        [self startTimerWithGCDSocket:NO];
    }
}

#pragma mark - timer

- (void)startTimerWithGCDSocket:(BOOL)isGCDSocket
{
    [self uploadFileDataWithGCDSocket:isGCDSocket];
}

- (void)stopTimerWithGCDSocket:(BOOL)isGCDSocket
{
    if (self.fileHandle)
    {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
    }
    
    if (isGCDSocket)
    {
        if (self.GCDSocket)
        {
            if ([self.GCDSocket isConnected])
            {
                [self.GCDSocket disconnect];
            }
            self.GCDSocket.delegate = nil;
            self.GCDSocket = nil;
        }
    }
    else
    {
        // 声明是由用户主动切断
        self.socket.userData = SocketOfflineByUser;
        
        if (self.socket)
        {
            if ([self.socket isConnected])
            {
                [self.socket disconnect];
            }
            self.socket.delegate = nil;
            self.socket = nil;
        }
    }
    
    self.isUploadHead = NO;
    
    // 保存上传记录
    NSNumber *number = [NSNumber numberWithLongLong:self.currentOffset];
    [[NSUserDefaults standardUserDefaults] setObject:number forKey:keyOffset];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 信息处理

// 文件长度，即大小
- (unsigned long long)filelength
{
    if (!_filelength)
    {
        NSData *fileData = [[NSData alloc] initWithContentsOfFile:self.filePath];
        _filelength = fileData.length;
        NSLog(@"fileData length %llu", _filelength);
        
        return _filelength;
    }
    
    return _filelength;
}

// 文件名称
- (NSString *)fileName
{
    if (!_fileName)
    {
        NSRange fileRange = [self.filePath rangeOfString:@"/" options:NSBackwardsSearch];
        if (fileRange.location != NSNotFound)
        {
            _fileName = [self.filePath substringFromIndex:(fileRange.location + fileRange.length)];
            NSLog(@"filename %@", _fileName);
        }
        
        return _fileName;
    }
    
    return _fileName;
}

// 对得到的data值进行解析与转换即可（根据实际情况进行修改）
- (void)fileInfoWithData:(NSData *)data
{
    // 对得到的data值进行解析与转换即可
    NSString *receiveStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"receiveStr %@", receiveStr);
    NSArray *receiveArray = [receiveStr componentsSeparatedByString:@";"];
    NSString *sourceid = [receiveArray firstObject];
    NSRange rangeSource = [sourceid rangeOfString:@"sourceid="];
    self.fileSouceId = [sourceid substringFromIndex:(rangeSource.location + rangeSource.length)];
    [[NSUserDefaults standardUserDefaults] setObject:self.fileSouceId forKey:keySouceId];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *position = [receiveArray lastObject];
    NSRange rangePosition = [position rangeOfString:@"position="];
    self.currentOffset = [position substringFromIndex:(rangePosition.location + rangePosition.length)].integerValue;
}

// 上传文件
- (void)uploadFileDataWithGCDSocket:(BOOL)isGCDSocket
{
    if (self.isUploadHead)
    {
        // 上传头文件协议（第一次调用时，且上传完成后则开始上传文件）
        self.fileSouceId = [[NSUserDefaults standardUserDefaults] objectForKey:keySouceId];
        // 构造拼接协议（根据实际情况进行修改）
        NSString *headStr = [[NSString alloc] initWithFormat:@"Content-Length=%llu;filename=%@;sourceid=%@\r\n", self.filelength, self.fileName, ((self.fileSouceId && 0 < self.fileSouceId.length) ? self.fileSouceId : @"")];
        NSData *headData = [headStr dataUsingEncoding:NSUTF8StringEncoding];
        if (isGCDSocket)
        {
            // 向服务器发送数据
            [self.GCDSocket writeData:headData withTimeout:timeWithout tag:tagWriteData];
            
            // 获取服务端返回数据
            [self.GCDSocket readDataWithTimeout:timeWithout tag:tagReadData];
        }
        else
        {
            // 向服务器发送数据
            [self.socket writeData:headData withTimeout:timeWithout tag:tagWriteData];
            
            // 获取服务端返回数据
            [self.socket readDataWithTimeout:timeWithout tag:tagReadData];
        }
        headData = nil;
        
        self.isUploadHead = NO;
    }
    else
    {
        // 上传文件信息
        if (!self.fileHandle)
        {
            self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
        }
        
        if (self.fileHandle)
        {
            // 文件当前上传记录位置，及是否继续上传
            if (self.filelength > self.currentOffset)
            {
                NSLog(@"currentOffset %llu", self.currentOffset);
                
                // 读取文件偏移量
                [self.fileHandle seekToFileOffset:self.currentOffset];
                self.currentOffset += OffSet;
                // 根据文件偏移量，读取文件信息
                NSData *bodyData = [self.fileHandle readDataOfLength:self.currentOffset];
                if (isGCDSocket)
                {
                    // 向服务器发送数据
                    [self.GCDSocket writeData:bodyData withTimeout:timeWithout tag:tagWriteData];
                }
                else
                {
                    // 向服务器发送数据
                    [self.socket writeData:bodyData withTimeout:timeWithout tag:tagWriteData];
                }

                bodyData = nil;
            }
            else
            {
                // 停止上传，即上传完成
                [self stopTimerWithGCDSocket:isGCDSocket];
            }
        }
    }
}

#pragma mark - gcdasyncSocket连接掉线操作

- (void)GCDSocketConnectWithHost:(NSString *)host port:(UInt16)port;
{
    if (!host || 0 >= host.length)
    {
        return;
    }
    
    NSAssert(host != nil, @"host must be not nil");
    NSAssert(self.filePath != nil, @"filePath must be not nil");
    
    self.socketHost = host;
    self.socketPort = port;
    
    self.isUploadHead = YES;
    
    // 获取已经上传完成的记录点
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:keyOffset];
    self.currentOffset = number.longLongValue;
//    self.currentOffset = 0;
    
    // 创建GCDSocket
    // Create our GCDAsyncSocket instance.
    // dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) dispatch_get_main_queue()
    self.GCDSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    // 连接服务器
    // Now we tell the ASYNCHRONOUS socket to connect.
    NSError *error = nil;
    if (![self.GCDSocket connectToHost:self.socketHost onPort:self.socketPort error:&error])
    {
        NSLog(@"Unable to connect to due to invalid configuration: %@", error);
    }
    else
    {
        NSLog(@"Connecting to \"%@\" on port %hu...", self.socketHost, self.socketPort);
    }
}

- (void)GCDSocketDisconnect
{
    // 结束上传
    [self stopTimerWithGCDSocket:YES];
}

#pragma mark GCDAsyncSocketDelegate

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    // Since we requested HTTP/1.0, we expect the server to close the connection as soon as it has sent the response.
    NSLog(@"6 socketDidDisconnect：%@", err);
    
    [self GCDSocketDisconnect];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"1 didConnectToHost:%@ port:%hu", host, port);

    // 开始上传
    [self startTimerWithGCDSocket:YES];
}

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    NSLog(@"2 didReceiveTrust:");
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    // This method will be called if USE_SECURE_CONNECTION is set
    NSLog(@"3 socketDidSecure:");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"4 didWriteDataWithTag:");
    
    
    if (tagWriteData == tag)
    {
        [self startTimerWithGCDSocket:YES];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"5 didReadData:");

    if (tagReadData == tag)
    {
        // 对得到的data值进行解析与转换即可
        [self fileInfoWithData:data];
    }
}

@end
