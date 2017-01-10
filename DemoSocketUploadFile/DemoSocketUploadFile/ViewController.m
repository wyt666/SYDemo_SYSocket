//
//  ViewController.m
//  DemoSocketUploadFile
//
//  Created by zhangshaoyu on 16/2/17.
//  Copyright © 2016年 zhangshaoyu. All rights reserved.
//

#import "ViewController.h"
#import "SYSocket.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"socket上传文件";
    
    UIBarButtonItem *startBtn = [[UIBarButtonItem alloc] initWithTitle:@"start" style:UIBarButtonItemStyleDone target:self action:@selector(socketStart:)];
    UIBarButtonItem *stopBtn = [[UIBarButtonItem alloc] initWithTitle:@"stop" style:UIBarButtonItemStyleDone target:self action:@selector(socketStop:)];
    self.navigationItem.leftBarButtonItems = @[startBtn, stopBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)socketStart:(UIButton *)button
{
//    // 设置IP地址
//    NSString *host = @"192.168.54.160";
//    // 设置端口
//    UInt16 port = 7876;
    
    // 设置IP地址 http://vcloud.mytaoyuan.com:7878
    NSString *host = @"58.57.65.11";
    // 设置端口
    UInt16 port = 7878;
    
    
    // 设置文件路径
    NSString *filePaht = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"txt"];
//    NSString *filePaht = [[NSBundle mainBundle] pathForResource:@"dawan" ofType:@"mp4"];
//    NSString *filePaht = [[NSBundle mainBundle] pathForResource:@"hongri" ofType:@"mp3"];
    // 设置socket要上传的文件路径
    [SYSocket sharedSocket].filePath = filePaht;
    // 启动socket连接
//    [[SYSocket sharedSocket] socketConnectWithHost:host port:port];
    [[SYSocket sharedSocket] GCDSocketConnectWithHost:host port:port];
}

- (void)socketStop:(UIButton *)button
{
    // 关闭socket连接
//    [[SYSocket sharedSocket] socketDisconnect];
    [[SYSocket sharedSocket] GCDSocketDisconnect];
}


@end
