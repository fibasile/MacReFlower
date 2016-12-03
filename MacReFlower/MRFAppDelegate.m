//
//  MRFAppDelegate.m
//  MacReFlower
//
//  Created by Fiore Basile on 18/06/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "MRFAppDelegate.h"
#import "MRFOperation.h"

@implementation MRFAppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.ops = [[NSOperationQueue alloc] init];
    //register for drag and drop
    [self.window registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    if (![self checkDependencies]){
        [self failDependencies];
        return;
    }
    self.inputFilename=nil;
    self.progressBar =nil;
    
    [self.fileWell unregisterDraggedTypes];
    
}

- (BOOL) canConvert {
    return self.inputFilename!=nil;
}

-(void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    
    [self application:sender openFile:[filenames objectAtIndex:0]];
    
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString* )filename {

    NSLog(@"Open file %@", filename);
    [self willChangeValueForKey:@"canConvert"];
    self.inputFilename = filename;
    [self didChangeValueForKey:@"canConvert"];

    // update the gui
    [self.fileLabel setStringValue:[[filename pathComponents] lastObject]];
    NSImage *iconImage = [[NSWorkspace sharedWorkspace] iconForFile: self.inputFilename];
    self.fileWell.image = iconImage;
    
    return YES;
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
    
    if (filenames.count > 0)
        return [self application:NSApp openFile:[filenames objectAtIndex:0]];
    
    return NO;
}


- (void) failDependencies {
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setInformativeText:@"This application requires the free k2pdfopt program to be installed and available in the path.\nPlease download it from:\nhttp://www.willus.com/k2pdfopt"];
    [alert setMessageText:@"Warning"];
    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];

}

- (BOOL) checkDependencies {
    NSString* ret = [MRFOperation findScript:@"k2pdfopt"];
     if (ret.length > 8) {
        self.pdfUtilityPath = [ret stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        return YES;
    }
    return NO;
}


-(void)startConversion:(id)sender {
    if (![self checkDependencies]){
        [self failDependencies];
        return;
    }

    // get output filename
    
    [self askForOutputFilename:sender block:^(NSString* fn){
        if (fn != nil){
            self.outputFilename = fn;
            [self showConversionProgress:self];
            [self runConversionTask:self];
        }
    }];
    
}

- (void)askForOutputFilename:(id)sender block:(void (^)(NSString*))block {
    
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    // Restrict the file type to whatever you like
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"pdf"]];
    // Set the starting directory to be the ssame as the input file
    [savePanel setDirectoryURL:[[NSURL fileURLWithPath:self.inputFilename] URLByDeletingLastPathComponent]];
    // Perform other setup
    // Use a completion handler -- this is a block which takes one argument
    // which corresponds to the button that was clicked
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        [savePanel orderOut:self];
        if (result == NSFileHandlingPanelOKButton) {
            // Close panel before handling errors
            
            block(savePanel.URL.path);
            //NSLog(@"Got URL: %@", [savePanel URL]);
            // Do what you need to do with the selected path
        } else {
            block(nil);
        }
    }];
}

- (void) showConversionProgress:(id)sender {

    if (self.progressBar==nil)
        self.progressBar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 200, 100)];
    [self.progressBar setMinValue:0];
    [self.progressBar setMaxValue:100];
    [self.progressBar setIndeterminate:YES];
    [self.progressBar setUsesThreadedAnimation:YES];
    
    NSAlert* alert = [NSAlert alertWithMessageText:@"Starting conversion..." defaultButton:@"Cancel" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert setAccessoryView:self.progressBar];
    [alert setAlertStyle:NSInformationalAlertStyle];
    
    self.progressAlert = alert;
    
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(conversionCanceled:returnCode:contextInfo:) contextInfo:nil];
    
//    [alert runModal];
}


- (void)conversionCanceled:(NSAlert *)alert
                         returnCode:(NSInteger)returnCode
               contextInfo:(void *)contextInfo {
    [self.ops cancelAllOperations];
}


- (void) updateConversionProgress:(NSData*)data {
    NSString* ds = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"should process:%@",ds);
    [self.progressAlert setMessageText:@"Conversion in progress..."];
    [self.progressBar setIndeterminate:NO];

    NSString* progressPattern = @"PAGE\\s(\\d{1,4})\\sof\\s(\\d{1,4})";
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:progressPattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:ds options:0 range:NSMakeRange(0, ds.length)];
    // 6: Iterate through the matches and highlight them
    NSLog(@"Parsing line");
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        NSString* match = [ds substringWithRange:matchRange];
        NSLog(@"Matched %@", match);
        [self.progressAlert setInformativeText:match];
        
        NSString* numbers = [match stringByReplacingOccurrencesOfString:@"PAGE " withString:@""];
        NSArray* comps = [numbers componentsSeparatedByString:@" of "];
        if (comps.count == 2) {
            @try {
                NSString* curr = [comps objectAtIndex:0];
                NSString* total = [comps objectAtIndex:1];
                double currVal =  (curr.doubleValue / total.doubleValue ) * 100;
                [self.progressBar setDoubleValue: currVal];
            }
            @catch (NSException *exception) {
            }
        }
    }
}

- (void) hideConversionProgress:(id)sender {
    NSWindow* alertSheet = self.window.attachedSheet;
    [NSApp endSheet:alertSheet];
    [alertSheet orderOut:self];
}


- (void)runConversionTask:(id)sender {
    //k2pdfopt -o k_technical_blogging.pdf technical_blogging.pdf -dev kpw -mode fw -wrap -pi- -hy -ws 0.375 -ls- -p 1-10 -ui-
    NSArray* defaultOptions = [NSArray arrayWithObjects:
                               @"-dev",
                               @"kpw",
                               @"-mode",
                               @"fw",
                               @"-wrap-",
                               @"-pi-",
                               @"-hy",
                               @"-ws",
                               @"0.375",
                               @"-ls-",
                               @"-ui-",
                               @"-x",
                               nil];
    
    __block MRFAppDelegate* parent=self;
    __block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSTask *task = [NSTask new];
        NSPipe *newPipe = [NSPipe new];
        NSFileHandle *readHandle = [newPipe fileHandleForReading];
        NSData *inData = nil;
        NSString* scriptPath = [[NSURL fileURLWithPath:self.pdfUtilityPath] path];
        [task setLaunchPath:scriptPath];
        [task setStandardOutput:newPipe];
        
        NSMutableArray* args = [NSMutableArray array];
        [args addObject:@"-o"];
        [args addObject:self.outputFilename];
        [args addObject:self.inputFilename];
        [args addObjectsFromArray:defaultOptions];

        
        NSLog(@"Executing %@ with %@", scriptPath, args);

        
        [task setArguments:args];

        [task setTerminationHandler:^(NSTask * t) {
            
            int status = [t terminationStatus];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self hideConversionProgress:self];
            
                if (status == 0) {
                    NSLog(@"Task succeeded.");
                    [[NSWorkspace sharedWorkspace] openFile:self.outputFilename];
                    NSAlert* alert = [NSAlert alertWithMessageText:@"Conversion completed" defaultButton:@"Dismiss" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
                    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
                    
                } else {
                    NSLog(@"Task failed.");
                    NSAlert* alert = [NSAlert alertWithMessageText:@"Conversion failed" defaultButton:@"Dismiss" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please check the input file"];
                    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
                    

                    //            NSLog(@"Error %@", error);
                }
            }];
            
            
            
        }];
        
        
        [task launch];
        
        while ((inData = [readHandle availableData]) && [inData length] && ![operation isCancelled]) {
            if ([operation isCancelled]) {
                [task terminate];
                NSLog(@"Task canceled");
                             
            } else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // callback
                    [parent updateConversionProgress:inData];
                }];
            }
        }
        

    }];
    
    [self.ops addOperation:operation];

}


@end
