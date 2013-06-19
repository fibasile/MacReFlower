//
//  MRFAppDelegate.h
//  MacReFlower
//
//  Created by Fiore Basile on 18/06/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MRFAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSOperationQueue* ops;
@property (strong) NSString* pdfUtilityPath;
@property (strong) NSString* inputFilename;
@property (strong) NSString* outputFilename;
@property (readonly) BOOL canConvert;
@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSButton *startButton;

@property (assign) IBOutlet NSImageView *fileWell;
@property (assign) IBOutlet NSTextField *fileLabel;


@property (strong) IBOutlet NSProgressIndicator* progressBar;
@property (strong) IBOutlet NSAlert* progressAlert;

- (IBAction)startConversion:(id)sender;
@end
