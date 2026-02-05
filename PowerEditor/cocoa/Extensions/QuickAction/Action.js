//
//  Action.js
//  Notepad++ Quick Action Extension
//
//  This script is called for web-based Quick Actions (e.g., when invoked from Safari)
//  Copyright © 2024 Notepad++. All rights reserved.
//

var Action = function() {};

Action.prototype = {
    
    run: function(parameters) {
        // Called when the action is invoked from a web context
        parameters.completionFunction({
            "URL": document.URL,
            "title": document.title,
            "selectedText": window.getSelection().toString(),
            "pageSource": document.documentElement.outerHTML
        });
    },
    
    finalize: function(parameters) {
        // Called after the main app processes the action
        // Can be used to clean up or provide feedback
    }
    
};

var ExtensionPreprocessingJS = new Action;
