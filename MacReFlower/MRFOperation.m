//
//  MRFOperation.m
//  MacReFlower
//
//  Created by Fiore Basile on 18/06/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "MRFOperation.h"

@implementation MRFOperation


+(NSString*) findScript:(NSString*)scriptName
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/which"];

    [task setEnvironment:[NSDictionary dictionaryWithObject:[[NSBundle mainBundle] resourcePath] forKey:@"PATH"]];
    [task setArguments:[NSArray arrayWithObjects: scriptName, nil]];

    NSPipe *pipe, *errorPipe;
    pipe = [NSPipe pipe];
    errorPipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: errorPipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    if (status == 0) {
//        NSLog(@"Task succeeded.");
        NSData *data;
        data = [file readDataToEndOfFile];
        
        
        NSString *string;
        string = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
//        NSLog (@"script returned:\n%@", string);
        return string;
    } else {
        NSLog(@"Task failed.");
        NSString* error = [[NSString alloc] initWithData:[[errorPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        NSLog(@"Error %@", error);
        
    }
    return @"";
}


////------------------------------------------------------
//+(void) runScript:(NSString*)scriptName
//{
//    NSTask *task;
//    task = [[NSTask alloc] init];
//    [task setLaunchPath: @"/bin/sh"];
//    
//    NSArray *arguments;
//    NSString* newpath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] privateFrameworksPath], scriptName];
//    NSLog(@"shell script path: %@",newpath);
//    arguments = [NSArray arrayWithObjects:newpath, nil];
//    [task setArguments: arguments];
//    
//    NSPipe *pipe;
//    pipe = [NSPipe pipe];
//    [task setStandardOutput: pipe];
//    
//    NSFileHandle *file;
//    file = [pipe fileHandleForReading];
//    
//    [task launch];
//    
//    NSData *data;
//    data = [file readDataToEndOfFile];
//    
//    NSString *string;
//    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
//    NSLog (@"script returned:\n%@", string);
//}
////------------------------------------------------------

@end
