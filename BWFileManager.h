//
//  BWFileManager.h
//  SudokuBook
//
//  Created by Michael Smith on 7/31/12.
//  Copyright (c) 2012 Bad Weasel, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


#define dataDirectoryName  @"data"


typedef enum BWFileSystemVersion {
    BWFileSystemUndetermined = 0,
    BWFileSystem4x = 400,
    BWFileSystem50 = 500,
    BWFileSystem501 = 501,
    BWFileSystem51up = 510,
} BWFileSystemVersion;

typedef enum BWFolderSetupStatus {
    BWFolderSetupStatusAlreadyExisted = 1 << 0,
    BWFolderSetupStatusCreated = 1 << 1,
    BWFolderSetupStatusSetAttributeSucceeded = 1 << 2,
    BWFolderSetupStatusSetAttributeFailed = 1 << 3,
} BWFolderSetupStatus;

@interface BWFileManager : NSObject
{
    
}
@property (readwrite) BWFileSystemVersion iOSFileSystem;
@property (readwrite) BOOL createdSaves;
@property (readwrite) BOOL createdData;
@property (readwrite) BOOL dataMigrationNeeded;     // if they were on iOS4 or 5.0 but are now on 5.0.1 or higher.. the data needs to be moved
@property (readwrite) BOOL dataRestoreNeeded;       // only happens if the data got erased by the system. (not if it's a new install)


+(BWFileManager*)sharedManager;

-(void) determineOS;
-(NSString *)dataDirectory;
-(NSString *)cachesDirectory;
-(BWFolderSetupStatus) setupPathWithNoBackup: (NSString *)path;
-(BOOL) migrateToNewDirectory;

@end
