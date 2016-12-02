# SYDemo_SYSocket
使用socket进行文件的断点上传

#通常使用网络进行文件的断点续传时，都是文件的断点下载，很少有文件的断点上传的例子。现在通过socket方式做了一个文件的断点上传。socket使用了AsyncSocket，或是GCDAsyncSocket。
 * AsyncSocket：http://code.google.com/p/cocoaasyncsocket/
 * GCDAsyncSocket：https://github.com/robbiehanson/CocoaAsyncSocket

# 简单的使用

~~~ javascript
// 1 导入头文件  
#import "SocketManager.h"  

~~~ 

~~~ javascript

// 2 启动socket连接  
- (void)socketStart:(UIButton *)button  
{  
    // 设置IP地址  
    NSString *host = @"192.168.54.160"; // @"192.186.100.21"; // kTestHost  
    // 设置端口  
    UInt16 port = 7876; // 10045; // 23  
    // 设置文件路径  
    NSString *filePaht = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"txt"];  
//    NSString *filePaht = [[NSBundle mainBundle] pathForResource:@"dawan" ofType:@"mp4"];  
//    NSString *filePaht = [[NSBundle mainBundle] pathForResource:@"hongri" ofType:@"mp3"];  
    // 设置socket要上传的文件路径  
    [SocketManager sharedSocket].filePath = filePaht;  
    // 启动socket连接  
//    [[SocketManager sharedSocket] socketConnectWithHost:host port:port];  
    [[SocketManager sharedSocket] GCDSocketConnectWithHost:host port:port];  
}  

~~~ 

~~~ javascript

// 3 关闭socket连接  
- (void)socketStop:(UIButton *)button  
{  
    // 关闭socket连接  
//    [[SocketManager sharedSocket] socketDisconnect];  
    [[SocketManager sharedSocket] GCDSocketDisconnect];  
}  
~~~

