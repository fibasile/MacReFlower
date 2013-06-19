//
//  MRFOperation.h
//  MacReFlower
//
//  Created by Fiore Basile on 18/06/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MRFOperation : NSOperation


@property (strong) NSURL* inputFileName;
@property (strong) NSURL* outputFileName;
+(NSString*) findScript:(NSString*)scriptName;
//+(void) runScript:(NSString*)scriptName;

@end
