//
//  DocumentController.mm
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "DocumentController.h"
#import "Document.h"

@implementation DocumentController

- (instancetype)init {
    self = [super init];
    if (self) {
        _documents = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Document Management

- (Document *)createNewDocument {
    Document *document = [[Document alloc] init];
    [self.documents addObject:document];
    self.currentDocument = document;
    
    NSLog(@"Created new document: %@", document.displayName);
    return document;
}

- (Document *)createNewDocumentWithText:(NSString *)text {
    Document *document = [self createNewDocument];
    document.content = text;
    return document;
}

- (Document *)openDocument:(NSURL *)url {
    // Check if document is already open
    for (Document *doc in self.documents) {
        if ([doc.fileURL isEqual:url]) {
            self.currentDocument = doc;
            NSLog(@"Document already open: %@", url.lastPathComponent);
            return doc;
        }
    }
    
    // Create new document and load from file
    Document *document = [[Document alloc] init];
    
    NSError *error = nil;
    BOOL success = [document loadFromURL:url error:&error];
    
    if (success) {
        [self.documents addObject:document];
        self.currentDocument = document;
        NSLog(@"Opened document: %@", url.lastPathComponent);
        return document;
    } else {
        NSLog(@"Failed to open document: %@", error.localizedDescription);
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Failed to Open File";
        alert.informativeText = error.localizedDescription ?: @"Unknown error";
        alert.alertStyle = NSAlertStyleCritical;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        
        return nil;
    }
}

- (BOOL)closeDocument:(Document *)document {
    if (!document) {
        return NO;
    }
    
    // Check for unsaved changes
    if (document.isModified) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"Do you want to save the changes to \"%@\"?", document.displayName];
        alert.informativeText = @"Your changes will be lost if you don't save them.";
        alert.alertStyle = NSAlertStyleWarning;
        [alert addButtonWithTitle:@"Save"];
        [alert addButtonWithTitle:@"Don't Save"];
        [alert addButtonWithTitle:@"Cancel"];
        
        NSModalResponse response = [alert runModal];
        
        if (response == NSAlertFirstButtonReturn) {
            // Save
            if (![self saveDocument:document]) {
                return NO; // Save failed or cancelled
            }
        } else if (response == NSAlertThirdButtonReturn) {
            // Cancel
            return NO;
        }
        // Don't Save - continue with close
    }
    
    // Remove from documents array
    [self.documents removeObject:document];
    
    // Update current document
    if (self.currentDocument == document) {
        if (self.documents.count > 0) {
            self.currentDocument = self.documents.lastObject;
        } else {
            self.currentDocument = nil;
        }
    }
    
    NSLog(@"Closed document: %@", document.displayName);
    return YES;
}

- (BOOL)closeCurrentDocument {
    return [self closeDocument:self.currentDocument];
}

- (BOOL)closeAllDocuments {
    // Work with a copy since we'll be modifying the array
    NSArray *docsCopy = [self.documents copy];
    
    for (Document *document in docsCopy) {
        if (![self closeDocument:document]) {
            return NO; // User cancelled
        }
    }
    
    return YES;
}

#pragma mark - Save Operations

- (BOOL)saveCurrentDocument {
    return [self saveDocument:self.currentDocument];
}

- (BOOL)saveCurrentDocumentAs {
    return [self saveDocumentAs:self.currentDocument];
}

- (BOOL)saveDocument:(Document *)document {
    if (!document) {
        return NO;
    }
    
    // If document has no URL, use Save As
    if (!document.fileURL) {
        return [self saveDocumentAs:document];
    }
    
    NSError *error = nil;
    BOOL success = [document saveToURL:document.fileURL error:&error];
    
    if (success) {
        NSLog(@"Saved document: %@", document.fileURL.lastPathComponent);
    } else {
        NSLog(@"Failed to save document: %@", error.localizedDescription);
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Failed to Save File";
        alert.informativeText = error.localizedDescription ?: @"Unknown error";
        alert.alertStyle = NSAlertStyleCritical;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
    
    return success;
}

- (BOOL)saveDocumentAs:(Document *)document {
    if (!document) {
        return NO;
    }
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.canCreateDirectories = YES;
    savePanel.showsTagField = YES;
    
    if (document.fileURL) {
        savePanel.directoryURL = [document.fileURL URLByDeletingLastPathComponent];
        savePanel.nameFieldStringValue = document.fileURL.lastPathComponent;
    } else {
        savePanel.nameFieldStringValue = document.displayName;
    }
    
    NSModalResponse response = [savePanel runModal];
    
    if (response == NSModalResponseOK) {
        NSURL *url = savePanel.URL;
        NSError *error = nil;
        BOOL success = [document saveToURL:url error:&error];
        
        if (success) {
            NSLog(@"Saved document as: %@", url.lastPathComponent);
            return YES;
        } else {
            NSLog(@"Failed to save document: %@", error.localizedDescription);
            
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Failed to Save File";
            alert.informativeText = error.localizedDescription ?: @"Unknown error";
            alert.alertStyle = NSAlertStyleCritical;
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
            
            return NO;
        }
    }
    
    return NO; // User cancelled
}

#pragma mark - Document Navigation

- (void)switchToDocument:(Document *)document {
    if ([self.documents containsObject:document]) {
        self.currentDocument = document;
        NSLog(@"Switched to document: %@", document.displayName);
    }
}

- (void)switchToNextDocument {
    if (self.documents.count == 0) {
        return;
    }
    
    NSInteger currentIndex = [self.documents indexOfObject:self.currentDocument];
    NSInteger nextIndex = (currentIndex + 1) % self.documents.count;
    self.currentDocument = self.documents[nextIndex];
}

- (void)switchToPreviousDocument {
    if (self.documents.count == 0) {
        return;
    }
    
    NSInteger currentIndex = [self.documents indexOfObject:self.currentDocument];
    NSInteger previousIndex = (currentIndex - 1 + self.documents.count) % self.documents.count;
    self.currentDocument = self.documents[previousIndex];
}

#pragma mark - Utilities

- (NSString *)currentDocumentName {
    return self.currentDocument.displayName;
}

- (NSInteger)documentCount {
    return self.documents.count;
}

- (BOOL)hasUnsavedChanges {
    for (Document *document in self.documents) {
        if (document.isModified) {
            return YES;
        }
    }
    return NO;
}

@end
