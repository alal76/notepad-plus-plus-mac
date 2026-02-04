//
//  main.m
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Create the application
        NSApplication *app = [NSApplication sharedApplication];
        
        // Create and set the app delegate
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        
        // Run the application
        return NSApplicationMain(argc, argv);
    }
}
