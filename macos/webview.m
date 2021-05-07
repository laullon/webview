//
//  main.m
//  webview_objc
//
//  Created by German Laullon on 29/4/21.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <WebKit/WKWebView.h>
#import <WebKit/WKWebViewConfiguration.h>
#import <WebKit/WKPreferences.h>
#import <WebKit/WKUserScript.h>
#import <WebKit/WKUserContentController.h>
#import <WebKit/WKWebsiteDataRecord.h>
#import <WebKit/WKWebsiteDataStore.h>

void StartApp(void);
void bindFunction(char const*);
void evalJS(char const*);
void navigate(char const*);
void run(void);

WKWebView *webView;

void StartApp(void){
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    id menubar = [NSMenu new];
    id appMenuItem = [NSMenuItem new];
    [menubar addItem:appMenuItem];
    [NSApp setMainMenu:menubar];
    
    id appMenu = [NSMenu new];
    id appName = [[NSProcessInfo processInfo] processName];
    id quitTitle = [@"Quit " stringByAppendingString:appName];
    id quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];
    
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    [theConfiguration.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
    webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:theConfiguration];

    NSSet *dataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:dataTypes
                                               modifiedSince:[NSDate dateWithTimeIntervalSince1970:0]
                                           completionHandler:^{ NSLog(@"cache deleted"); }];

    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1024, 768)
                                                   styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |NSWindowStyleMaskResizable |NSWindowStyleMaskMiniaturizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:YES];
    [window center];
    [window setTitle:appName];
    [window orderFrontRegardless];
    window.contentView=webView;
    
    [NSApp activateIgnoringOtherApps:YES];
    return;
}

void bindFunction(char const* name){
    WKUserScript *script = [[WKUserScript alloc] initWithSource:@(name)
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                               forMainFrameOnly:NO];
    [webView.configuration.userContentController addUserScript:script];
}

void evalJS(char const* js){
    [webView evaluateJavaScript:@(js)
              completionHandler:^(NSString *result, NSError *error)
     {
        NSLog(@"Error %@",error);
        NSLog(@"Result %@",result);
    }];
}

void navigate(char const* target){
    NSURL *nsurl=[NSURL URLWithString:@(target)];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    [webView loadRequest:nsrequest];
}

void run(void){
    [NSApp run];
}
