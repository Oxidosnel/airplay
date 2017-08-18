#import "HTTPServer.h"
#import "GCDAsyncSocket.h"
#import "HTTPConnection.h"
#import "WebSocket.h"
#import "HTTPLogging.h"

#import "DeviceInfo.h"
// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_INFO; // | HTTP_LOG_FLAG_TRACE;

@interface HTTPServer (PrivateAPI)

- (void)unpublishBonjour;
- (void)publishBonjour;

+ (void)startBonjourThreadIfNeeded;
+ (void)performBonjourBlock:(dispatch_block_t)block waitUntilDone:(BOOL)waitUntilDone;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation HTTPServer

/**
 * Standard Constructor.
 * Instantiates an HTTP server, but does not start it.
**/
- (id)init
{
	if ((self = [super init]))
	{
		HTTPLogTrace();
		
		// Initialize underlying dispatch queue and GCD based tcp socket
		serverQueue = dispatch_queue_create("HTTPServer", NULL);
		asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:serverQueue];
		
		// Use default connection class of HTTPConnection
		connectionQueue = dispatch_queue_create("HTTPConnection", NULL);
		connectionClass = [HTTPConnection self];
		
		// By default bind on all available interfaces, en1, wifi etc
		interface = nil;
		
		// Use a default port of 0
		// This will allow the kernel to automatically pick an open port for us
		port = 0;
		
		// Configure default values for bonjour service
		
		// Bonjour domain. Use the local domain by default
		domain = @"local.";
		
		// If using an empty string ("") for the service name when registering,
		// the system will automatically use the "Computer Name".
		// Passing in an empty string will also handle name conflicts
		// by automatically appending a digit to the end of the name.
		name = @"";
		
		// Initialize arrays to hold all the HTTP and webSocket connections
		connections = [[NSMutableArray alloc] init];
		webSockets  = [[NSMutableArray alloc] init];
		
		connectionsLock = [[NSLock alloc] init];
		webSocketsLock  = [[NSLock alloc] init];
		
		// Register for notifications of closed connections
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(connectionDidDie:)
		                                             name:HTTPConnectionDidDieNotification
		                                           object:nil];
		
		// Register for notifications of closed websocket connections
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(webSocketDidDie:)
		                                             name:WebSocketDidDieNotification
		                                           object:nil];
		
		isRunning = NO;
	}
	return self;
}

/**
 * Standard Deconstructor.
 * Stops the server, and clients, and releases any resources connected with this instance.
**/
- (void)dealloc
{
	HTTPLogTrace();
	
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Stop the server if it's running
	[self stop];
	
	// Release all instance variables
	
	dispatch_release(serverQueue);
	dispatch_release(connectionQueue);
	
	[asyncSocket setDelegate:nil delegateQueue:NULL];
	[asyncSocket release];
	
	[documentRoot release];
	[interface release];
	
	[netService release];
	[domain release];
	[name release];
	[type release];
	[txtRecordDictionary release];
	
	[connections release];
	[webSockets release];
	[connectionsLock release];
	[webSocketsLock release];
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The document root is filesystem root for the webserver.
 * Thus requests for /index.html will be referencing the index.html file within the document root directory.
 * All file requests are relative to this document root.
**/
- (NSString *)documentRoot
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = [documentRoot retain];
	});
	
	return [result autorelease];
}

- (void)setDocumentRoot:(NSString *)value
{
	HTTPLogTrace();
	
	// Document root used to be of type NSURL.
	// Add type checking for early warning to developers upgrading from older versions.
	
	if (value && ![value isKindOfClass:[NSString class]])
	{
		HTTPLogWarn(@"%@: %@ - Expecting NSString parameter, received %@ parameter",
					THIS_FILE, THIS_METHOD, NSStringFromClass([value class]));
		return;
	}
	
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		[documentRoot release];
		documentRoot = [valueCopy retain];
	});
	
	[valueCopy release];
}

/**
 * The connection class is the class that will be used to handle connections.
 * That is, when a new connection is created, an instance of this class will be intialized.
 * The default connection class is HTTPConnection.
 * If you use a different connection class, it is assumed that the class extends HTTPConnection
**/
- (Class)connectionClass
{
	__block Class result;
	
	dispatch_sync(serverQueue, ^{
		result = connectionClass;
	});
	
	return result;
}

- (void)setConnectionClass:(Class)value
{
	HTTPLogTrace();
	
	dispatch_async(serverQueue, ^{
		connectionClass = value;
	});
}

/**
 * What interface to bind the listening socket to.
**/
- (NSString *)interface
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = [interface retain];
	});
	
	return [result autorelease];
}

- (void)setInterface:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		[interface release];
		interface = [valueCopy retain];
	});
	
	[valueCopy release];
}

/**
 * The port to listen for connections on.
 * By default this port is initially set to zero, which allows the kernel to pick an available port for us.
 * After the HTTP server has started, the port being used may be obtained by this method.
**/
- (UInt16)port
{
	__block UInt16 result;
	
	dispatch_sync(serverQueue, ^{
		result = port;
	});
	
    return result;
}

- (UInt16)listeningPort
{
	__block UInt16 result;
	
	dispatch_sync(serverQueue, ^{
		if (isRunning)
			result = [asyncSocket localPort];
		else
			result = 0;
	});
	
	return result;
}

- (void)setPort:(UInt16)value
{
	HTTPLogTrace();
	
	dispatch_async(serverQueue, ^{
		port = value;
	});
}

/**
 * Domain on which to broadcast this service via Bonjour.
 * The default domain is @"local".
**/
- (NSString *)domain
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = [domain retain];
	});
	
    return [domain autorelease];
}

- (void)setDomain:(NSString *)value
{
	HTTPLogTrace();
	
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		[domain release];
		domain = [valueCopy retain];
	});
	
	[valueCopy release];
}

/**
 * The name to use for this service via Bonjour.
 * The default name is an empty string,
 * which should result in the published name being the host name of the computer.
**/
- (NSString *)name
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = [name retain];
	});
	
	return [name autorelease];
}

- (NSString *)publishedName
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		
		if (netService == nil)
		{
			result = nil;
		}
		else
		{
			
			dispatch_block_t bonjourBlock = ^{
				result = [[netService name] copy];
			};
			
			[[self class] performBonjourBlock:bonjourBlock waitUntilDone:YES];
		}
	});
	
	return [result autorelease];
}

- (void)setName:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		[name release];
		name = [valueCopy retain];
	});
	
	[valueCopy release];
}

/**
 * The type of service to publish via Bonjour.
 * No type is set by default, and one must be set in order for the service to be published.
**/
- (NSString *)type
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = [type retain];
	});
	
	return [result autorelease];
}

- (void)setType:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		[type release];
		type = [valueCopy retain];
	});
	
	[valueCopy release];
}

/**
 * The extra data to use for this service via Bonjour.
**/
- (NSDictionary *)TXTRecordDictionary
{
	__block NSDictionary *result;
	
	dispatch_sync(serverQueue, ^{
		result = [txtRecordDictionary retain];
	});
	
	return [result autorelease];
}
- (void)setTXTRecordDictionary:(NSDictionary *)value
{
	HTTPLogTrace();
	
	NSDictionary *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
	
		[txtRecordDictionary release];
		txtRecordDictionary = [valueCopy retain];
		
		// Update the txtRecord of the netService if it has already been published
		if (netService)
		{
			NSNetService *theNetService = netService;
            NSData *txtRecordData = nil;
			if (txtRecordDictionary)
				txtRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecordDictionary];
			
			dispatch_block_t bonjourBlock = ^{
				[theNetService setTXTRecordData:txtRecordData];
			};
			
			[[self class] performBonjourBlock:bonjourBlock waitUntilDone:NO];
		}
	});
	
	[valueCopy release];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Control
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)start:(NSError **)errPtr
{
	HTTPLogTrace();
	
	__block BOOL success = YES;
	__block NSError *err = nil;
	
	dispatch_sync(serverQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
		NSLog(@"port[%d]success%d",port,success);
		success = [asyncSocket acceptOnInterface:interface port:7000 error:&err];
        NSLog(@"port[%d]success%d",port,success);
		if (success)
		{
			HTTPLogInfo(@"%@: Started HTTP server on port %hu", THIS_FILE, [asyncSocket localPort]);
			
			isRunning = YES;
			//[self publishBonjour];
            //zxz
            [self publishBonjour_zxz];
		}
		else
		{
			HTTPLogError(@"%@: Failed to start HTTP Server: %@", err);
			[err retain];
		}
		
		[pool release];
	});
	
	if (errPtr)
		*errPtr = [err autorelease];
	else
		[err release];
	
	return success;
}

- (BOOL)stop
{
	HTTPLogTrace();
	
	dispatch_sync(serverQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		// First stop publishing the service via bonjour
		[self unpublishBonjour];
		
		// Stop listening / accepting incoming connections
		[asyncSocket disconnect];
		isRunning = NO;
		
		// Now stop all HTTP connections the server owns
		[connectionsLock lock];
		for (HTTPConnection *connection in connections)
		{
			[connection stop];
		}
		[connections removeAllObjects];
		[connectionsLock unlock];
		
		// Now stop all WebSocket connections the server owns
		[webSocketsLock lock];
		for (WebSocket *webSocket in webSockets)
		{
			[webSocket stop];
		}
		[webSockets removeAllObjects];
		[webSocketsLock unlock];
		
		[pool release];
	});
	
	return YES;
}

- (BOOL)isRunning
{
	__block BOOL result;
	
	dispatch_sync(serverQueue, ^{
		result = isRunning;
	});
	
	return result;
}

- (void)addWebSocket:(WebSocket *)ws
{
	[webSocketsLock lock];
	
	HTTPLogTrace();
	[webSockets addObject:ws];
	
	[webSocketsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Status
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the number of http client connections that are currently connected to the server.
**/
- (NSUInteger)numberOfHTTPConnections
{
	NSUInteger result = 0;
	
	[connectionsLock lock];
	result = [connections count];
	[connectionsLock unlock];
	
	return result;
}

/**
 * Returns the number of websocket client connections that are currently connected to the server.
**/
- (NSUInteger)numberOfWebSocketConnections
{
	NSUInteger result = 0;
	
	[webSocketsLock lock];
	result = [webSockets count];
	[webSocketsLock unlock];
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Incoming Connections
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (HTTPConfig *)config
{
	// Override me if you want to provide a custom config to the new connection.
	// 
	// Generally this involves overriding the HTTPConfig class to include any custom settings,
	// and then having this method return an instance of 'MyHTTPConfig'.
	
	// Note: Think you can make the server faster by putting each connection on its own queue?
	// Then benchmark it before and after and discover for yourself the shocking truth!
	// 
	// Try the apache benchmark tool (already installed on your Mac):
	// $  ab -n 1000 -c 1 http://localhost:<port>/some_path.html
	
	return [[[HTTPConfig alloc] initWithServer:self documentRoot:documentRoot queue:connectionQueue] autorelease];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *datestr=[dateFormatter stringFromDate:[NSDate date]];
    NSLog(@"开始时间 %@",datestr);
	HTTPConnection *newConnection = (HTTPConnection *)[[connectionClass alloc] initWithAsyncSocket:newSocket
	                                                                                 configuration:[self config]];
	[connectionsLock lock];
	[connections addObject:newConnection];
	[connectionsLock unlock];
	
	[newConnection start];
	[newConnection release];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Bonjour
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)publishBonjour_zxz{
    
    NSNetService * netService2 = [[NSNetService alloc] initWithDomain:@"local."
                                                                 type:@"_airserver._tcp."
                                                                 name: [[UIDevice currentDevice] name]
                                                                 port:7000];

	[netService2 setDelegate:self];
	//[netService2 publish];
	NSDictionary *txtDict2 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"0x4A7FFFF7,0xE", @"ft",
                              
                              [DeviceInfo deviceId], @"deviceid",
                              //@"1.9.4", @"rhd",///
                              @"5d613bb7-9547-4310-a653-c4eab941a2b2",@"pi",
                              @"2e76de17f4e86f7e413deb5ac79a22e3cf76b020137b7a33af5574e07392e807",@"pk",
                              @"0x4",@"sf",//
                               @"iMac14,1",@"am",//
                               @"10.11.2",@"os",//
                               @"macosx",@"pf",//
                               @"0",@"pt",//
                               @"6.0.3",@"vs",//

                              nil];
	NSData *txtData2 = [NSNetService dataFromTXTRecordDictionary:txtDict2];
	[netService2 setTXTRecordData:txtData2];

    
    
    NSNetService * netService1 = [[NSNetService alloc] initWithDomain:@"local."
                                                                 type:@"_airplay._tcp."
                                                                 name: [[UIDevice currentDevice] name]
                                                                 port:7000];
	[netService1 setDelegate:self];
	[netService1 publish];
    
    
	NSDictionary *txtDict1 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"0x4A7FFFF7,0xE", @"features",
                              @"AppleTV5,3", @"model",
                              [DeviceInfo deviceId], @"deviceid",
                              @"0x4",@"flags",//
                              //@"1.9.4", @"rhd",///
                              @"220.68", @"srcvers",
                              @"2",@"vv",
                              @"5d613bb7-9547-4310-a653-c4eab941a2b2",@"pi",
                              @"2e76de17f4e86f7e413deb5ac79a22e3cf76b020137b7a33af5574e07392e807",@"pk",

                              nil];

	NSData *txtData1 = [NSNetService dataFromTXTRecordDictionary:txtDict1];
	[netService1 setTXTRecordData:txtData1];

    
	UInt16 portzxz = [asyncSocket localPort];
    
    NSLog(@"portzxz %d ",portzxz);
	NSLog(@"%d",__IPHONE_OS_VERSION_MIN_REQUIRED);
    //	NSString *name = [[DeviceInfo deviceIdWithSep:@""]
    //					  stringByAppendingFormat:@"@%@",
    //					  [[UIDevice currentDevice] name]];
//    NSString *namezxz = [[DeviceInfo deviceId]
//                         				  stringByAppendingFormat:@"@%@",
//                         					  [[UIDevice currentDevice] name]];
    //这个name很关键，更换后真机上无效
    NSString *namezxz = [[DeviceInfo deviceId] stringByAppendingFormat:@"@%@",[[UIDevice currentDevice] name]];
    
    
    
	netService = [[NSNetService alloc] initWithDomain:@"local."
												 type:@"_raop._tcp."
												 name:namezxz
												 port:7000];
	[netService setDelegate:self];
	[netService publish];
    
    NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             
                             // txt record version
                             @"AppleTV5,3", @"am",
                             
                             // airtunes server version
                             @"0,1,2,3", @"cn",
                             
                             
                             // 2 channels, 44100 Hz, 16-bit audio
                             @"true", @"da",
                             @"0,3,5", @"et",
                             @"0x4A7FFFF7,0xE", @"ft",
                             
                             // no password
                             @"0,1,2", @"md",
                             
                             // encryption types
                             //  0: no encryption
                             //  1: airport express (RSA+AES)
                             //  3: apple tv (FairPlay+AES)
                             //							 @"0,1,3,5", @"et",
                             @"2e76de17f4e86f7e413deb5ac79a22e3cf76b020137b7a33af5574e07392e807", @"pk",//
                             @"0x4", @"sf",//
                             @"TCP", @"tp",
                             
                             // transport protocols
                             //							 @"TCP", @"tp",
                             @"65537", @"vn",//
                             
                             @"220.68", @"vs",//cn=1
                             @"2", @"vv",
                            
                             nil];
//		NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
//							 
//							 // txt record version
//							 @"1", @"txtvers",
//							 
//							 // airtunes server version
//							 @"150.33", @"vs",
//                             
//							 
//							 // 2 channels, 44100 Hz, 16-bit audio
//							 @"2", @"ch",
//							 @"44100", @"sr",
//							 @"16", @"ss",
//							 
//							 // no password
//							 @"false", @"sm",
//							 
//							 // encryption types
//							 //  0: no encryption
//							 //  1: airport express (RSA+AES)
//							 //  3: apple tv (FairPlay+AES)
////							 @"0,1,3,5", @"et",
//                            @"0,3,5", @"et",//
//                            @"0x100029ff", @"ft",//
//							 @"1", @"ek",
//							 
//							 // transport protocols
////							 @"TCP", @"tp",
//                            @"UDP", @"tp",//
//							 
//							 @"1,2,3", @"cn",//cn=1
//							 @"false", @"sv",
//							 @"true", @"da",
//							 @"65537", @"vn",
//							 @"0,1,2", @"md",
//							 @"0x4", @"sf",
//							 
//                             @"1",@"vv",
////                             @"1.0", @"rhd",
//                             @"4.1.3", @"rhd",
//                             //[DeviceInfo platform], @"am",
////							 @"AppleTV3,1", @"am",
//                            @"AppleTV3,1", @"am",//
//                            
//                                 
//                            @"false",@"pw",
//							 nil];
    
	NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
	[netService setTXTRecordData:txtData];
//    [netService publish];
    //
    
    //
    
  
}
- (void)publishBonjour
{
	HTTPLogTrace();
	
	NSAssert(dispatch_get_current_queue() == serverQueue, @"Invalid queue");
	
	if (type)
	{ 
//        NSString *name1 = [@"haha"
//                          stringByAppendingFormat:@"@%@",
//                          [[UIDevice currentDevice] name]];
//        
//        NSNetService *netService2 = [[NSNetService alloc] initWithDomain:@"local."
//                                                                   type:@"_raop._tcp."
//                                                                   name:name1
//                                                                   port:[asyncSocket localPort]];
//        [netService2 setDelegate:self];
//        [netService2 publish];
//        //[netService2 resolveWithTimeout:1.0];
//        NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 
//                                 // txt record version
//                                 @"1", @"txtvers",
//                                 
//                                 // airtunes server version
//                                 @"104.29", @"vs",
//                                 
//                                 // 2 channels, 44100 Hz, 16-bit audio
//                                 @"2", @"ch",
//                                 @"44100", @"sr",
//                                 @"16", @"ss",
//                                 
//                                 // no password
//                                 @"false", @"sm",
//                                 
//                                 // encryption types
//                                 //  0: no encryption
//                                 //  1: airport express (RSA+AES)
//                                 //  3: apple tv (FairPlay+AES)
//                                 @"0,1", @"et",
//                                 @"1", @"ek",
//                                 
//                                 // transport protocols
//                                 @"TCP,UDP", @"tp",
//                                 
//                                 @"1", @"cn",
//                                 @"false", @"sv",
//                                 @"true", @"da",
//                                 @"65537", @"vn",
//                                 @"0,1,2", @"md",
//                                 @"0x4", @"sf",
//                                 
//                                 //[DeviceInfo platform], @"am",
//                                 //@"AppleTV2,1", @"am",
//                                 nil];
//        
//        NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
//        [netService2 setTXTRecordData:txtData];
//        
//        NSNetService *theNetService2 = netService2;
        
         NSLog(@"哈哈哈哈哈");
        //netService = [[NSNetService alloc] initWithDomain:domain type:type name:name port:7000];
		netService = [[NSNetService alloc] initWithDomain:domain type:type name:name port:[asyncSocket localPort]];
       
		[netService setDelegate:self];
		
		NSNetService *theNetService = netService;
		NSData *txtRecordData = nil;
		if (txtRecordDictionary)
			txtRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecordDictionary];
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService publish];
            //zxz
            //[theNetService resolveWithTimeout:0];
//            [theNetService2 removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//			[theNetService2 scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			//[theNetService2 publish];
			//[theNetService2 setTXTRecordData:txtData];
			// Do not set the txtRecordDictionary prior to publishing!!!
			// This will cause the OS to crash!!!
			if (txtRecordData)
			{
				[theNetService setTXTRecordData:txtRecordData];
			}
		};
		
		[[self class] startBonjourThreadIfNeeded];
		[[self class] performBonjourBlock:bonjourBlock waitUntilDone:NO];
	}
}

- (void)unpublishBonjour
{
	HTTPLogTrace();
	
	NSAssert(dispatch_get_current_queue() == serverQueue, @"Invalid queue");
	
	if (netService)
	{
		NSNetService *theNetService = netService;
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetService stop];
			[theNetService release];
		};
		
		[[self class] performBonjourBlock:bonjourBlock waitUntilDone:NO];
		
		netService = nil;
	}
}

/**
 * Republishes the service via bonjour if the server is running.
 * If the service was not previously published, this method will publish it (if the server is running).
**/
- (void)republishBonjour
{
	HTTPLogTrace();
	
	dispatch_async(serverQueue, ^{
		
		[self unpublishBonjour];
		[self publishBonjour];
	});
}

/**
 * Called when our bonjour service has been successfully published.
 * This method does nothing but output a log message telling us about the published service.
**/
- (void)netServiceDidPublish:(NSNetService *)ns
{
	// Override me to do something here...
	// 
	// Note: This method is invoked on our bonjour thread.
	
	HTTPLogInfo(@"Bonjour Service Published: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);
}

/**
 * Called if our bonjour service failed to publish itself.
 * This method does nothing but output a log message telling us about the published service.
**/
- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	// 
	// Note: This method in invoked on our bonjour thread.
	
	HTTPLogWarn(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
	                                         [ns domain], [ns type], [ns name], errorDict);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is automatically called when a notification of type HTTPConnectionDidDieNotification is posted.
 * It allows us to remove the connection from our array.
**/
- (void)connectionDidDie:(NSNotification *)notification
{
	// Note: This method is called on the connection queue that posted the notification
	
	[connectionsLock lock];
	
	HTTPLogTrace();
	[connections removeObject:[notification object]];
	
	[connectionsLock unlock];
}

/**
 * This method is automatically called when a notification of type WebSocketDidDieNotification is posted.
 * It allows us to remove the websocket from our array.
**/
- (void)webSocketDidDie:(NSNotification *)notification
{
	// Note: This method is called on the connection queue that posted the notification
	
	[webSocketsLock lock];
	
	HTTPLogTrace();
	[webSockets removeObject:[notification object]];
	
	[webSocketsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Bonjour Thread
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * NSNetService is runloop based, so it requires a thread with a runloop.
 * This gives us two options:
 * 
 * - Use the main thread
 * - Setup our own dedicated thread
 * 
 * Since we have various blocks of code that need to synchronously access the netservice objects,
 * using the main thread becomes troublesome and a potential for deadlock.
**/

static NSThread *bonjourThread;

+ (void)startBonjourThreadIfNeeded
{
	HTTPLogTrace();
	
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		
		HTTPLogVerbose(@"%@: Starting bonjour thread...", THIS_FILE);
		
		bonjourThread = [[NSThread alloc] initWithTarget:self
		                                        selector:@selector(bonjourThread)
		                                          object:nil];
		[bonjourThread start];
	});
}

+ (void)bonjourThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	HTTPLogVerbose(@"%@: BonjourThread: Started", THIS_FILE);
	
	// We can't run the run loop unless it has an associated input source or a timer.
	// So we'll just create a timer that will never fire - unless the server runs for 10,000 years.
	
	[NSTimer scheduledTimerWithTimeInterval:DBL_MAX target:self selector:@selector(ignore:) userInfo:nil repeats:YES];
	
	[[NSRunLoop currentRunLoop] run];
	
	HTTPLogVerbose(@"%@: BonjourThread: Aborted", THIS_FILE);
	
	[pool release];
}

+ (void)performBonjourBlock:(dispatch_block_t)block
{
	HTTPLogTrace();
	
	NSAssert([NSThread currentThread] == bonjourThread, @"Executed on incorrect thread");
	
	block();
}

+ (void)performBonjourBlock:(dispatch_block_t)block waitUntilDone:(BOOL)waitUntilDone
{
	HTTPLogTrace();
	
	dispatch_block_t bonjourBlock = Block_copy(block);
	
	[self performSelector:@selector(performBonjourBlock:)
	             onThread:bonjourThread
	           withObject:bonjourBlock
	        waitUntilDone:waitUntilDone];
	
	Block_release(bonjourBlock);
}

@end
