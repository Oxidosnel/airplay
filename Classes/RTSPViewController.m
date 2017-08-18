//
//  RTSPViewController.m
//  AirView
//
//  Created by sanzrew on 16/1/13.
//
//

#import "RTSPViewController.h"
#import "AsyncUdpSocket.h"
#import "AsyncSocket.h"


#define SERVERADDR @"192.168.6.147"
#define KENTER @""

@interface RTSPViewController (){
    NSString *Info;
    NSInteger getport;
    AsyncSocket*socket;
    AsyncUdpSocket*socketudp;
    NSInteger isRtp;
    
    dispatch_queue_t serverQueue;
}

@end

@implementation RTSPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Info = [[NSString alloc] init];
    getport = 0;
    
    socket = [[AsyncSocket alloc] initWithDelegate:self ];
    NSError *error = nil;
    if(!([socket connectToHost:@"192.168.6.147" onPort:7000 error:&error]))
    {
        NSLog(@"error:%@",error);
    }
    else
    {
        isRtp = 0;
    }
    
    socketudp = [[AsyncUdpSocket alloc] initWithDelegate:self];
}

/*
 *建立连接，返回服务器对OPTIONS请求的响应
 */
-(NSMutableString*)getOptions
{
    NSMutableString* options = [[[NSMutableString alloc] init] autorelease];
    
    [options appendFormat:@"OPTIONS rtsp://%@/v1 RTSP/1.0%@",SERVERADDR,KENTER];
    [options appendFormat:@"CSeq: 2%@",KENTER];
    [options appendFormat:@"User-Agent: LibVLC/2.0.3 (LIVE555 Streaming Media v2011.12.23)%@%@",KENTER,KENTER];
    NSLog(@"options = %@",options);
    [socket writeData:[options dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[[NSMutableString alloc] init] autorelease];
    [socket readDataWithTimeout:3 tag:1];
    
    return readString;
}

/*
 *建立连接，返回服务器对DESCRIBE请求的响应
 */
-(NSMutableString*)getDescribe
{
    NSMutableString* describe = [[[NSMutableString alloc] init] autorelease];
    
    [describe appendFormat:@"DESCRIBE rtsp://%@/v1 RTSP/1.0%@",SERVERADDR,KENTER];
    [describe appendFormat:@"CSeq: 3%@",KENTER];
    [describe appendFormat:@"User-Agent: LibVLC/2.0.3 (LIVE555 Streaming Media v2011.12.23)%@",KENTER];
    [describe appendFormat:@"Accept: application/sdp%@%@",KENTER,KENTER];
    // [describe appendFormat:@"Authorization: Basic YWRtaW4=%@",KENTER];
    NSLog(@"describe = %@",describe);
    [socket writeData:[describe dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[[NSMutableString alloc] init] autorelease];
    [socket readDataWithTimeout:3 tag:2];
    return readString;
}
/*
 *建立连接，返回通过udp连接服务器对SETUP请求的响应
 */
-(NSMutableString*)getUdpSetup
{
    NSMutableString* udpsetup = [[[NSMutableString alloc] init] autorelease];
    
    [udpsetup appendFormat:@"SETUP rtsp://%@/v1/track0 RTSP/1.0%@",SERVERADDR,KENTER];
    [udpsetup appendFormat:@"CSeq: 4%@",KENTER];
    [udpsetup appendFormat:@"User-Agent: LibVLC/2.0.3 (LIVE555 Streaming Media v2011.12.23)%@",KENTER];
    [udpsetup appendFormat:@"Transport: RTP/AVP;unicast;client_port=49664-49665%@%@",KENTER,KENTER];
    
    NSLog(@"udpsetup = %@",udpsetup);
    [socket writeData:[udpsetup dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[[NSMutableString alloc] init] autorelease];
    [socket readDataWithTimeout:3 tag:3];
    return readString;
}
/*
 *建立连接，返回向服务器对PLAY请求的响应
 */
-(NSMutableString*)getPlay:(NSString*)session
{
    NSMutableString* play = [[[NSMutableString alloc] init] autorelease];
    
    [play appendFormat:@"PLAY rtsp://%@/v1 RTSP/1.0%@",SERVERADDR,KENTER];
    [play appendFormat:@"CSeq: 6%@",KENTER];
    [play appendFormat:@"User-Agent: LibVLC/2.0.3 (LIVE555 Streaming Media v2011.12.23)%@",KENTER];
    [play appendFormat:@"Session:%@%@",session,KENTER];
    [play appendFormat:@"Range: npt=0.000-%@%@",KENTER,KENTER];
    // [Info  release];
    NSLog(@"play = %@",play);
    [socket writeData:[play dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    NSMutableString* readString = [[[NSMutableString alloc] init] autorelease];
    [socket readDataWithTimeout:3 tag:4];
    
    return readString;
}
-(void)RecvUDPData
{
    //  severs_port = [self getPort:Info];
    //  NSLog(@"severs_port = %d",severs_port);
    NSError * error1 = nil;
    [socketudp bindToPort:49664 error:nil];
    if(error1)
    {
        NSLog(@"error1:%@",error1);
    }
    NSLog(@"start udp server");
    
    //   if ([socketudp connectToHost:SERVERADDR onPort:severs_port error:nil])
    {
        [socketudp receiveWithTimeout:-1 tag:0];//将不断接受摄像头发送的数据
    }
}
/*
 *通过主机名和端口号连接服务器
 */
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"onSocket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    if(isRtp == 0)
    {
        [self getOptions];
    }
    else
    {
        NSLog(@"start tcp server");
        AsyncSocket *rtpTcp =socket;
//        [rtpTcp readDataWithTimeout:-1 tag:5];
        [rtpTcp readDataWithTimeout:-1 tag:5];
    }
}
/*
 *向内存中写入数据
 */
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *message;
    switch (tag)
    {
            
        case 1:
        {
            NSLog(@"getOptions:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if([[message substringToIndex:15] isEqualToString:@"RTSP/1.0 200 OK"])
            {
                //  NSLog(@"message is: \n%@",message);
                [message release];
                [self getDescribe];
            }
            else
            {
                //  NSLog(@"message is: \n%@",message);
                [message release];
                return;
            }
            
        }
            break;
            
        case 2:
        {
            NSLog(@"getDescribe:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if([[message substringToIndex:15] isEqualToString:@"RTSP/1.0 200 OK"])
            {
                // NSLog(@"message is: \n%@",message);
                [message release];
                [self getUdpSetup];
            }
            else
            {
                // NSLog(@"message is: \n%@",message);
                [message release];
                return;
            }
            
        }
            break;
            
        case 3:
        {
            NSLog(@"getUdpSetup:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if([[message substringToIndex:15] isEqualToString:@"RTSP/1.0 200 OK"])
            {
                // NSLog(@"message is: \n%@",message);
                Info = message;
                //   NSLog(@"Info = %@",Info);
                NSString* session = [self getSession:Info];
                [self getPlay:session];
                
            }
            else
            {
                //  NSLog(@"message is: \n%@",message);
                [message release];
                return;
            }
            
        }
            break;
            
        case 4:
        {
            NSLog(@"getPlay:did read data");
            message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if([[message substringToIndex:15] isEqualToString:@"RTSP/1.0 200 OK"])
            {
                NSLog(@"message is: \n%@",message);
                [message release];
                [self RecvUDPData];
            }
            else
            {
                //  NSLog(@"message is: \n%@",message);
                [message release];
                return;
            }
            
        }
            break;
            
            /*
             case 5:
             {
             NSLog(@"getTeardown:did read data");
             message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(@"message is: \n%@",message);
             }
             break;
             */
            
        default:
            break;
    }
    
}
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"start rece rtp by udp");
    NSLog(@"length = %d ",[data length]);
    Byte *testByte = (Byte *)[data bytes];
    for(char i=12;i<[data length];i++)
    {
        printf("%02x",testByte[i]);
    }
    [socketudp receiveWithTimeout:-1 tag:0];
    
    return YES;
}
- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"UDP is missing");
    [socketudp release];
    
    socketudp = [[AsyncUdpSocket alloc] initWithDelegate:self];
    [socketudp bindToPort:7000 error:nil];
    [socketudp enableBroadcast:YES error:nil];//设置为广播
    [socketudp receiveWithTimeout:-1 tag:0];//将不断接受摄像头发送的数据
}

@end