//
//  BWFileManager.h
//
//  Created by Michael Smith on 7/31/12.
//  Copyright (c) 2014 Bad Weasel, LLC. All rights reserved.
//
// No guarantees.  No Damages.  No Licenses.  Use at your own risk.  Free as in free.
//
// If you use this please download all my games on the app store.  Search for Bad Weasel

//  My typical usage is to initialize it in the view controller or when you are initializing things.

#import "BWFileManager.h"

BWFileManager *thisFileManager = [BWFileManager sharedManager];

// That should set up the folder

// Then later when you need to write something do something like this:

BWFileManager *thisFileManager = [BWFileManager sharedManager];    
NSString *dataDirectory = [thisFileManager dataDirectory];

//NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];        
BOOL isThere = [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/cache",dataDirectory]];
        
if (!isThere) {
    [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/cache",dataDirectory] 
                              withIntermediateDirectories:YES attributes:nil error:NULL];
}

// I have it turn off the archive by default.  Feel free to modify this to not do that if you want to store crap on iCloud.