//
//  MLFile+HD.m
//  MobileVLC
//
//  Created by Romain Goyet on 01/09/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLFile+HD.h"
#import <sys/sysctl.h>

@implementation MLFile (HD)
- (BOOL)isHD {
    if ([self videoTrack]) {
        /* let' see how many pixels we got */
        double numberOfPixels = [[[self videoTrack] valueForKey:@"width"] doubleValue] * [[[self videoTrack] valueForKey:@"height"] doubleValue];

        return (numberOfPixels > 600000); // This is roughly between 480p and 720p
    } else {
        return NO; // If we don't have any resolution info, let's assume the file isn't HD
    }
}

- (BOOL)isTooHugeForDevice {
    if ([self videoTrack]) {
        /* let's see on which device we are running */
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);

        char *answer = malloc(size);
        sysctlbyname("hw.machine", answer, &size, NULL, 0);

        NSString *currentMachine = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
        free(answer);

        /* let' see how many pixels we got */
        double numberOfPixels = [[[self videoTrack] valueForKey:@"width"] doubleValue] * [[[self videoTrack] valueForKey:@"height"] doubleValue];

        if ([currentMachine hasPrefix:@"iPhone2"] || [currentMachine hasPrefix:@"iPhone3"] || [currentMachine hasPrefix:@"iPad1"] || [currentMachine hasPrefix:@"iPod3"] || [currentMachine hasPrefix:@"iPod4"]) {
            // iPhone 3GS, iPhone 4, first gen. iPad, 3rd and 4th generation iPod touch
            return (numberOfPixels > 600000); // This is roughly between 480p and 720p
        }
        else
        {
            // iPhone 4S, iPad 2 and 3, iPod 4 and future devices
            return (numberOfPixels > 922000); // 720p
        }
    } else {
        return NO; // If we don't have any resolution info, let's assume the file isn't HD
    }
}
@end
