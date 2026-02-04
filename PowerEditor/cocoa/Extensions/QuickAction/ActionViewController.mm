//
//  ActionViewController.mm
//  Notepad++ Quick Action Extension
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "ActionViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ActionViewController ()
@property (strong) IBOutlet NSView *view;
@end

@implementation ActionViewController

- (void)loadView {
    // Create a minimal view for the extension
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get the items from the extension context
    NSExtensionContext *context = self.extensionContext;
    
    // Process input items
    for (NSExtensionItem *item in context.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            [self processItemProvider:itemProvider];
        }
    }
}

- (void)processItemProvider:(NSItemProvider *)itemProvider {
    // Handle file URLs
    if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeFileURL.identifier]) {
        [itemProvider loadItemForTypeIdentifier:UTTypeFileURL.identifier
                                        options:nil
                              completionHandler:^(NSURL *url, NSError *error) {
            if (url && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self openFileInNotepadPlusPlus:url];
                });
            }
        }];
    }
    // Handle plain text
    else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeText.identifier]) {
        [itemProvider loadItemForTypeIdentifier:UTTypeText.identifier
                                        options:nil
                              completionHandler:^(NSString *text, NSError *error) {
            if (text && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self openTextInNotepadPlusPlus:text];
                });
            }
        }];
    }
    // Handle URLs (web pages)
    else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeURL.identifier]) {
        [itemProvider loadItemForTypeIdentifier:UTTypeURL.identifier
                                        options:nil
                              completionHandler:^(NSURL *url, NSError *error) {
            if (url && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self openURLInNotepadPlusPlus:url];
                });
            }
        }];
    }
}

- (void)openFileInNotepadPlusPlus:(NSURL *)fileURL {
    // Use NSWorkspace to open the file with Notepad++
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *appURL = [workspace URLForApplicationWithBundleIdentifier:@"org.notepad-plus-plus"];
    
    if (appURL) {
        NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
        configuration.activates = YES;
        
        [workspace openURLs:@[fileURL]
       withApplicationAtURL:appURL
              configuration:configuration
          completionHandler:^(NSRunningApplication *app, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [self showErrorAlert:error.localizedDescription];
                }
                [self completeAction];
            });
        }];
    } else {
        [self showErrorAlert:@"Notepad++ application not found. Please ensure Notepad++ is installed."];
        [self completeAction];
    }
}

- (void)openTextInNotepadPlusPlus:(NSString *)text {
    // Create a temporary file with the text content
    NSString *tempDir = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"notepad-quick-action-%@.txt",
                         [[NSUUID UUID] UUIDString]];
    NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
    
    NSError *error = nil;
    [text writeToFile:filePath
           atomically:YES
             encoding:NSUTF8StringEncoding
                error:&error];
    
    if (!error) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [self openFileInNotepadPlusPlus:fileURL];
    } else {
        [self showErrorAlert:error.localizedDescription];
        [self completeAction];
    }
}

- (void)openURLInNotepadPlusPlus:(NSURL *)url {
    // Download the URL content and open it
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (content) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self openTextInNotepadPlusPlus:content];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showErrorAlert:@"Unable to decode URL content as text"];
                    [self completeAction];
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showErrorAlert:error ? error.localizedDescription : @"Failed to download URL content"];
                [self completeAction];
            });
        }
    }];
    [task resume];
}

- (void)showErrorAlert:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Open in Notepad++";
    alert.informativeText = message;
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)completeAction {
    // Complete the extension request
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

@end
