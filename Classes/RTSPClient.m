//
//  RTSPClient.m
//  AirView
//
//  Created by sanzrew on 16/1/13.
//
//

//
//  ViewController.m
//  RTSPClient
//
//  Created by Fox on 12-3-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTSPClient.h"
#import "AsyncSocket.h"
#import "AsyncUdpSocket.h"



#define KENTER @"\r\n"
#define KBLACK @" "
#define MAX_BUF 10240


static    NSString* SERVERADDR  = @"192.168.6.147";
static  const  int  SERVERPORT = 7000;


@interface RTSPClient ()
{
    AsyncSocket *socket;
    AsyncUdpSocket *socketudp;
}
@end

@implementation RTSPClient

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    socket = [[AsyncSocket alloc] initWithDelegate:self];
    
    NSError *err;
    if (![socket connectToHost:SERVERADDR onPort:SERVERPORT error:&err]) {
        NSLog(@"%@",err);
    }
    [self getOptions];
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}






#pragma mark RTSP Session
/*
 *建立连接，返回服务器对OPTIONS请求的响应
 */
-(NSMutableString*)getOptions
{
    
    NSMutableString* options = [[NSMutableString alloc] init];
    
    [options appendFormat:@"OPTIONS rtsp://%@:%d/2699324803567405959 RTSP/1.0%@",SERVERADDR,SERVERPORT,KENTER];
    [options appendFormat:@"CSeq: 16%@",KENTER];
//    [options appendFormat:@"User-Agent: LibVLC/1.1.11 (LIVE555 Streaming Media v2011.05.25)%@%@",KENTER,KENTER];
    [options appendFormat:@"DACP-ID: 14413BE4996FEA4D%@",KENTER];
    [options appendFormat:@"Active-Remote: 2543110914%@",KENTER];
    [options appendFormat:@"Content-Type: application/sdp%@",KENTER];
    [options appendFormat:@"Content-Length: 331%@%@",KENTER,KENTER];
    
    [options appendFormat:@"v=0%@",KENTER];
    [options appendFormat:@"o=AirTunes 2699324803567405959 0 IN IP4 192.168.1.5%@",KENTER];
    [options appendFormat:@"s=AirTunes%@",KENTER];
    [options appendFormat:@"c=IN IP4 192.168.1.5%@",KENTER];
    [options appendFormat:@"t=0 0%@",KENTER];
    [options appendFormat:@"m=audio 0 RTP/AVP 96%@",KENTER];
    [options appendFormat:@"a=rtpmap:96 mpeg4-generic/44100/2%@",KENTER];
    [options appendFormat:@"a=fmtp:96%@",KENTER];
    [options appendFormat:@"a=fpaeskey:RlBMWQECAQAAAAA8AAAAAOG6c4aMdLkXAX+lbjp7EhgAAAAQeX5uqGyYkBmJX+gd5ANEr+amI8urqFmvcNo87pR0BXGJ4eLf%@",KENTER];
    [options appendFormat:@"a=aesiv:VZTaHn4wSJ84Jjzlb94m0Q==%@",KENTER];
    [options appendFormat:@"a=min-latency:11025%@",KENTER];
    
    
    
    
    [socket writeData:[options dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[NSMutableString alloc] init];
    [socket readDataWithTimeout:3 tag:1];
    
    return readString;
}

/*
 *建立连接，返回服务器对DESCRIBE请求的响应
 */
-(NSMutableString*)getDescribe
{
    
    NSMutableString* describe = [[NSMutableString alloc] init];
    
    [describe appendFormat:@"DESCRIBE rtsp://%@:%d/H264 RTSP/1.0%@",SERVERADDR,SERVERPORT,KENTER];
    [describe appendFormat:@"CSeq: 3%@",KENTER];
    [describe appendFormat:@"Authorization: Basic YWRtaW4=%@",KENTER];
    [describe appendFormat:@"User-Agent: LibVLC/1.1.11 (LIVE555 Streaming Media v2011.05.25)%@",KENTER];
    [describe appendFormat:@"Accept: application/sdp%@%@",KENTER,KENTER];
    
    
    
    [socket writeData:[describe dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[NSMutableString alloc] init];
    [socket readDataWithTimeout:3 tag:2];
    
    
    return readString;
}

/*
 *建立连接，返回通过tcp连接服务器对SETUP请求的响应
 */
-(NSMutableString*)getTcpSetup
{
    
    
    NSMutableString* tcpsetup = [[NSMutableString alloc] init];
    
    [tcpsetup appendFormat:@"SETUP rtsp://%@:%d/H264/track1 RTSP/1.0%@",SERVERADDR,SERVERPORT,KENTER];
    [tcpsetup appendFormat:@"CSeq: 4%@",KENTER];
    
    [tcpsetup appendFormat:@"Authorization: Basic YWRtaW4=%@",KENTER];
    [tcpsetup appendFormat:@"User-Agent: LibVLC/1.1.11 (LIVE555 Streaming Media v2011.05.25)%@",KENTER];
    [tcpsetup appendFormat:@"Transport: RTP/AVP/TCP;unicast;interleaved=0-1%@%@",KENTER,KENTER];
    
    
    
    [socket writeData:[tcpsetup dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[NSMutableString alloc] init];
    [socket readDataWithTimeout:3 tag:3];
    
    
    return readString;
    
}

/*
 *建立连接，返回通过udp连接服务器对SETUP请求的响应
 */
-(NSMutableString*)getUdpSetup
{
    
    NSMutableString* udpsetup = [[NSMutableString alloc] init];
    
    [udpsetup appendFormat:@"SETUP rtsp://%@/H264/track1 RTSP/1.0%@",SERVERADDR,KENTER];
    [udpsetup appendFormat:@"CSeq: 4%@",KENTER];
    [udpsetup appendFormat:@"Authorization: Basic YWRtaW4=%@",KENTER];
    [udpsetup appendFormat:@"User-Agent: LibVLC/1.1.11 (LIVE555 Streaming Media v2011.05.25)%@",KENTER];
    [udpsetup appendFormat:@"Transport: RTP/AVP;unicast;client_port=7777-7778%@%@",KENTER,KENTER];
    
    
    
    [socket writeData:[udpsetup dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[NSMutableString alloc] init];
    [socket readDataWithTimeout:3 tag:3];
    
    
    return readString;
    
}

/*
 *建立连接，返回向服务器对PLAY请求的响应
 */
-(NSMutableString*)getPlay:(NSString*)session
{
    
    NSMutableString* play = [[NSMutableString alloc] init];
    
    [play appendFormat:@"PLAY rtsp://%@/H264 RTSP/1.0%@",SERVERADDR,KENTER];
    [play appendFormat:@"CSeq: 5%@",KENTER];
    [play appendFormat:@"Range: npt=0.000-%@",KENTER];
    [play appendFormat:@"Session:%@%@",session,KENTER];
    [play appendFormat:@"User-Agent: LibVLC/1.1.11 (LIVE555 Streaming Media v2011.05.25)%@%@",KENTER,KENTER];
    
    
    
    [socket writeData:[play dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[NSMutableString alloc] init];
    [socket readDataWithTimeout:3 tag:4];
    
    
    return readString;
    
}



/*
 *建立连接，返回向服务器对TEARDOWN请求的响应
 */
-(NSMutableString*)getTeardown:(NSString*)session
{
    
    NSMutableString* teardown = [[NSMutableString alloc] init];
    
    [teardown appendFormat:@"TEARDOWN rtsp://%@:%d/H264 RTSP/1.0%@",SERVERADDR,SERVERPORT,KENTER];
    [teardown appendFormat:@"CSeq: 5%@",KENTER];
    [teardown appendFormat:@"Session:%@%@",session,KENTER];
    [teardown appendFormat:@"User-Agent: LibVLC/1.1.11 (LIVE555 Streaming Media v2011.05.25)%@%@",KENTER,KENTER];
    
    
    [socket writeData:[teardown dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[NSMutableString alloc] init];
    [socket readDataWithTimeout:3 tag:5];
    return readString;
    
}

/*
 *返回服务器地址
 */
-(NSString*)getServeraddr
{
    return SERVERADDR;
}

/*
 *返回RTSP回话标识,info为客户端向服务器发送setup请求时的响应信息
 */
-(NSString*)getSession:(NSString*)info
{
    
    //从文件中再一行一行读取数据，将包含session的一行保留出来
    NSString *tmp;
    NSArray *lines; /*将文件转化为一行一行的*/
    lines = [info componentsSeparatedByString:@"\r\n"];
    
    NSEnumerator *nse = [lines objectEnumerator];
    NSString* session = [[NSString alloc] init];
    while(tmp = [nse nextObject]) {
        if ([tmp hasPrefix:@"Session:"]) {
            //tmp为包含session那一行的
            NSInteger len = @"Session:".length;
            session = [[tmp substringFromIndex:len] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSLog(@"Session:%@\n",session);
            break;
        }
    }
    
    return  session;
    
}

/*
 *返回RTSP回话的Content-Base
 */
-(NSString*)getContentBase:(NSString*)info
{
    //info为Describe请求所响应的信息
    NSString *tmp;
    NSArray *lines; /*将文件转化为一行一行的*/
    lines = [info componentsSeparatedByString:@"\r\n"];
    
    NSEnumerator *nse = [lines objectEnumerator];
    NSString* contentbase = [[NSString alloc] init];
    while(tmp = [nse nextObject]) {
        if ([tmp hasPrefix:@"Content-Base:"]) {
            //tmp为包含session那一行的
            NSInteger len = @"Content-Base:".length;
            contentbase = [[info substringFromIndex:len] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSLog(@"Content-Base:%@\n",contentbase);
            break;
        }
    }
    
    return  contentbase;
    
}


/*
 *返回RTSP回话的Content-Type
 */
-(NSString*)getContentType:(NSString*)info
{
    
    //info为Describe请求所响应的信息
    NSString *tmp;
    NSArray *lines; /*将文件转化为一行一行的*/
    lines = [info componentsSeparatedByString:@"\r\n"];
    
    NSEnumerator *nse = [lines objectEnumerator];
    NSString* contenttype = [[NSString alloc] init];
    while(tmp = [nse nextObject]) {
        if ([tmp hasPrefix:@"Content-Type:"]) {
            //tmp为包含session那一行的
            NSInteger len = @"Content-Type:".length;
            contenttype = [[info substringFromIndex:len] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSLog(@"CContent-Type:%@\n",contenttype);
            break;
        }
    }
    
    return  contenttype;
    
}



/*
 *返回RTSP回话的contentlength
 */
-(NSString*)getContentLength:(NSString*)info
{
    
    //info为Describe请求所响应的信息
    NSString *tmp;
    NSArray *lines; /*将文件转化为一行一行的*/
    lines = [info componentsSeparatedByString:@"\r\n"];
    
    NSEnumerator *nse = [lines objectEnumerator];
    NSString* contentlength = [[NSString alloc] init];
    while(tmp = [nse nextObject]) {
        if ([tmp hasPrefix:@"Content-Type:"]) {
            //tmp为包含session那一行的
            NSInteger len = @"Content-Type:".length;
            contentlength = [[info substringFromIndex:len] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSLog(@"CContent-Type:%@\n",contentlength);
            break;
        }
    }
    return  contentlength;
}

/*
 *本机作为客户端连接接受服务器发送的消息
 */
-(void)RecvUDPData{
    
    socketudp = [[AsyncUdpSocket alloc] initWithDelegate:self];
    
    [socketudp bindToPort:7777 error:nil];
    [socketudp enableBroadcast:YES error:nil];//设置为广播
    
    if ([socketudp connectToHost:@"172.16.108.200" onPort:6970 error:nil]) {
        [socketudp receiveWithTimeout:-1 tag:1];//将不断接受摄像头发送的数据
    }
    
}

#pragma mark AsyncSocketDelegate
/*
 *通过主机名和端口号连接服务器
 */
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSLog(@"did connect to host");
}
/*
 *向内存中写入数据
 */
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *message;
    NSString* info = [[NSString alloc] init];
    switch (tag) {
        case 1:
            NSLog(@"getOptions:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"message is: \n%@",message);
            [self getDescribe];
            break;
        case 2:
            NSLog(@"getDescribe:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"message is: \n%@",message);
            info = [self getUdpSetup];
            break;
        case 3:
            NSLog(@"getUdpSetup:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"message is: \n%@",message);
            NSString* session = [self getSession:info];
            [self getPlay:session];
            break;
        case 4:
            NSLog(@"getPlay:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"message is: \n%@",message);
            [self RecvUDPData];
            break;
        case 5:
            NSLog(@"getTeardown:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"message is: \n%@",message);
            break;
        default:
            break;
    }
    
    
    
}




#pragma mark AsyncUdpSocketDelegate
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"333333333");
    NSString *theLine=[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]; //Convert the UDP data to an NSString
    
    NSLog(@"%@", theLine);
    
    [theLine release];
    
    [socketudp receiveWithTimeout:-1 tag:1];
    
    
    return YES;
    
}


@end
