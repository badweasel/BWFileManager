//
//  BWFileManager.m
//  SudokuBook
//
//  Created by Michael Smith on 7/31/12.
//  Copyright (c) 2012 Bad Weasel, LLC. All rights reserved.
//
// Due to the storage rules and the fact that you have to store things in different places on iOS 4, 5.0, and 5.0.1 and up...
// I made this file manager to basicaly handle knowing where is appropriate to store things, set the do not backup attribute when it can
// and hande the migration of data from older os locations to newer os locations.//
//
// Basic function is to create necessary folders and return paths to them
// Secondary function is move data from the old location to the new location.
//

#import "BWFileManager.h"

#include <sys/xattr.h>


@implementation BWFileManager

@synthesize iOSFileSystem, createdData, dataMigrationNeeded, dataRestoreNeeded;
//@synthesize createdSaves;

+(BWFileManager*)sharedManager
{
    static dispatch_once_t pred;
    static BWFileManager *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[BWFileManager alloc] init];
    });
    
    return shared;
}

-(id)init
{
    self = [super init];
    
    if (self) {
        //NSLog(@"init BWFileManager");
        //createdSaves = FALSE;
        createdData = FALSE;
        dataMigrationNeeded = FALSE;
        dataRestoreNeeded = FALSE;
        
        iOSFileSystem=BWFileSystemUndetermined;
        [self determineOS];
        NSString *dataPath = [self dataDirectory];
        
        // set up any folders that you need for the whole app
        BWFolderSetupStatus status = [self setupPathWithNoBackup:dataPath];
        if (status & BWFolderSetupStatusCreated) {      // single & because it's checking to see if a bit is turned on
            createdData = TRUE;
        }
        
        // you can setup subfolders here if you want...
        //status = [self setupPathWithNoBackup:[NSString stringWithFormat:@"%@/saves",dataPath]];
        //if (status & BWFolderSetupStatusCreated) {
        //    createdSaves = TRUE;
        //}
        
        // previous ios version should be in user defaults.. if not this is a new install
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *previousOS = [defaults objectForKey:@"iOSPrevious"];
        BWFileSystemVersion iOSFileSystemPrevious = BWFileSystemUndetermined;
        if (previousOS)
        {
            iOSFileSystemPrevious = [previousOS intValue];
        }
        
        // First, is a migration needed from old folder to new folder?
        if ((iOSFileSystem==BWFileSystem501 || iOSFileSystem==BWFileSystem51up) && createdData) {
            // Only need to check if iOSFileSystem is 501 or 51up otherwise there'd be nothing to migrate
            // also we'd have to have created the data folder.. or again there's nothing to copy
            if (iOSFileSystemPrevious==BWFileSystem4x || iOSFileSystemPrevious==BWFileSystem50) {
                //NSLog(@"Was 4.x or 5.0.0 and is now 5.0.1 or higher.. Need to move data from the old folder to the new");
                dataMigrationNeeded = TRUE;
                // I'm not doing the migration here automatically because it might take time
                // Later I'll do it with a message up on the screen
            }
        }
        else if (iOSFileSystemPrevious==BWFileSystem50 && iOSFileSystem==BWFileSystem50 && createdData) {
            // it was 5.0 is still is 5.0 but our data folder was missing
            NSLog(@"data got erased by the system.. ug!");
            dataRestoreNeeded = TRUE;
        }
        
        // put the current os version in user defaults
        [defaults setObject:[NSNumber numberWithInt:iOSFileSystem] forKey:@"iOSPrevious"];

    }
    return self;
}

-(void) determineOS
{
    if (iOSFileSystem==BWFileSystemUndetermined) {
        // determine what OS..  set iOSFileSystem as either pre 5.0, 5.0.0. 5.0.1, or post 5.1 and up
        NSString *sysVers = [[UIDevice currentDevice] systemVersion];
        
        if ([sysVers compare:@"5.0" options:NSNumericSearch] == NSOrderedAscending) {
            //NSLog(@"iOS is 4.x or before - store in library/caches/data");
            iOSFileSystem = BWFileSystem4x;
        }
        else if ([sysVers compare:@"5.0" options:NSNumericSearch] == NSOrderedSame) {
            //NSLog(@"iOS is 5.0 exactly - you're screwed - but store in library/caches/data");
            iOSFileSystem = BWFileSystem50;
        }
        else if ([sysVers compare:@"5.0.1" options:NSNumericSearch] == NSOrderedSame) {
            //NSLog(@"iOS is 5.0.1 or higher.. store in documents/data");
            iOSFileSystem = BWFileSystem501;
        }
        else {
            //NSLog(@"iOS is 5.1 or higher.. store in documents/data");
            iOSFileSystem = BWFileSystem51up;
        }
    }
}


// we store everything in data.. so check in the data directory to see if it's there, if not create it and set the no copy flag if you can.
-(NSString *)dataDirectory
{
    NSString *pathToData;
    
    [self determineOS];
    if (iOSFileSystem==BWFileSystem501 || iOSFileSystem==BWFileSystem51up) {
        // we are in the sweet spot.. ios 5.0.1 or higher..
        pathToData = [NSString stringWithFormat:@"%@/data",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
    }
    else {
        // it's either 4x or 50 and either way we store in caches
        pathToData = [NSString stringWithFormat:@"%@/data",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]];
    }
    
    return pathToData;
}


// in my case the app won't work until the copy is complete, so I don't really want to do it asynchronously

-(BOOL) migrateToNewDirectory
{
    NSString *pathToOldData = [NSString stringWithFormat:@"%@/data",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]];
    NSString *pathToNewData = [NSString stringWithFormat:@"%@/data",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
    
    //NSLog(@"from: %@",pathToOldData);
    //NSLog(@"  to: %@",pathToNewData);
    
    NSError* anError;
    if (![[NSFileManager defaultManager] moveItemAtPath:pathToOldData toPath:pathToNewData error:&anError]) {
        // If an error occurs, it's probably because a previous backup directory
        // already exists.  Delete the old directory and try again.
        //NSLog(@"copy attempt 1 failed - prob old data there - deleting it");
        if ([[NSFileManager defaultManager] removeItemAtPath:pathToNewData error:&anError]) {
            if (![[NSFileManager defaultManager] moveItemAtPath:pathToOldData toPath:pathToNewData error:&anError]) {
                //NSLog(@"copy failed");
                return FALSE;
            }
        }
    }

    //NSLog(@"copy succeeded");
    // dont need to with the move - [[NSFileManager defaultManager] removeItemAtPath:pathToOldData error:&anError];
    BWFolderSetupStatus status = [self setupPathWithNoBackup:pathToNewData];
    if (status & BWFolderSetupStatusSetAttributeSucceeded) {
        //NSLog(@"and reset the do not copy attribute on the new location");
    }
    return TRUE;
}


-(NSString *)cachesDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}


-(BWFolderSetupStatus) setupPathWithNoBackup: (NSString *)path
{
    BOOL isFolder = YES;
    BWFolderSetupStatus status = 0;
    NSError *error;

    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        status = status | BWFolderSetupStatusCreated;
    }
    else {
        status = status | BWFolderSetupStatusAlreadyExisted;
    }
    NSURL *pathURL= [NSURL fileURLWithPath:path];
    if (iOSFileSystem==BWFileSystem501) {
        BOOL success = [self addSkipBackupAttributeToItemAtURL501:pathURL];
        if (success)
        {
            //NSLog(@"os 5.0.1 - sucessfully set do not backup attribute for %@", pathURL);
            status = status | BWFolderSetupStatusSetAttributeSucceeded;
        }
        else
        {
            //NSLog(@"Could not set do not backup for %@", pathURL);
            status = status | BWFolderSetupStatusSetAttributeFailed;
        }
    }
    else if (iOSFileSystem==BWFileSystem51up) {
        BOOL success = [self addSkipBackupAttributeToItemAtURL51:pathURL];
        if (success)
        {
            //NSLog(@"os 5.1 - sucessfully set do not backup attribute for %@", pathURL);
            status = status | BWFolderSetupStatusSetAttributeSucceeded;
        }
        else {
            status = status | BWFolderSetupStatusSetAttributeFailed;
        }
    }
    return status;
}

- (BOOL)addSkipBackupAttributeToItemAtURL501:(NSURL *)URL
{
    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

- (BOOL)addSkipBackupAttributeToItemAtURL51:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        //NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}


@end
