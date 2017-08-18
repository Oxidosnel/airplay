//
//  DeviceInfo.m
//  AirView
//
//  Created by Clément Vasseur on 12/22/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import "DeviceInfo.h"
#import "DDLog.h"

#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>

#include <net/if.h>
#include <net/if_dl.h>

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#if !defined(IFT_ETHER)
# define IFT_ETHER 0x6 /* Ethernet CSMACD */
#endif

@implementation DeviceInfo

+ (NSString *)getSysInfoByName:(char *)typeSpecifier
{
	size_t size;
	sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
	char *answer = malloc(size);
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	NSString *results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	return results;
}

+ (NSString *)platform
{
	return [self getSysInfoByName:"hw.machine"];
}

+ (NSString *)deviceId
{
	NSMutableString *res;
	struct ifaddrs *addrs;
	const struct ifaddrs *cursor;
	const struct sockaddr_dl *dlAddr;
	const uint8_t *base;
	int i;

	if (getifaddrs(&addrs) != 0) {
		DDLogError(@"getifaddrs failed");
		return nil;
	}

	res = nil;
	cursor = addrs;
	while (cursor != NULL) {
		if ((cursor->ifa_addr->sa_family == AF_LINK) &&
			(((const struct sockaddr_dl *) cursor->ifa_addr)->sdl_type == IFT_ETHER)) {
			dlAddr = (const struct sockaddr_dl *) cursor->ifa_addr;
			base = (const uint8_t *) &dlAddr->sdl_data[dlAddr->sdl_nlen];
			res = [NSMutableString stringWithCapacity:32];
			for (i = 0; i < dlAddr->sdl_alen; i++) {
				if (i != 0)
					[res appendString:@":"];
				[res appendFormat:@"%02X", base[i]];
			}
			goto out;
		}
		cursor = cursor->ifa_next;
	}

out:
	freeifaddrs(addrs);
	return res;
}

+(NSString *)getMacAddress_zxz
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    NSString            *errorFlag = NULL;
    size_t              length;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    // Get the size of the data available (store in len)
    else if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
        errorFlag = @"sysctl mgmtInfoBase failure";
    // Alloc memory based on above call
    else if ((msgBuffer = malloc(length)) == NULL)
        errorFlag = @"buffer allocation failure";
    // Get system information, store in buffer
    else if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
    {
        free(msgBuffer);
        errorFlag = @"sysctl msgBuffer failure";
    }
    else
    {
        // Map msgbuffer to interface message structure
        struct if_msghdr *interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
        
        // Map to link-level socket structure
        struct sockaddr_dl *socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
        
        // Copy link layer address data in socket structure to an array
        unsigned char macAddress[6];
        memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
        
        // Read from char array into a string object, into traditional Mac address format
        NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                      macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]];
        //if(IsDEBUG) NSLog(@"Mac Address: %@", macAddressString);
        
        // Release the buffer memory
        free(msgBuffer);
        
        return macAddressString;
    }
    
    // Error...
    //if(IsDEBUG) NSLog(@"Error: %@", errorFlag);
    
    return errorFlag;
}

@end
