import AppKit
import WebKit

var running = true
var webView: WKWebView?
var app: NSApplication?
var scriptHandler: WKScriptMessageHandler?

let jsGetJson = """
var getJSON = function(url, callback) {
    return new Promise(function (resolve, reject) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onload = resolve;
        xhr.onerror = reject;
        xhr.send();
    });
};
"""

let jsFunction = """
function %@() {
    return new Promise(function (resolve, reject) {
        getJSON('/cmd/%@').then(function (e) {
            console.log(e.target.response);
            resolve(e.target.response)
        }, function (e) {
        // handle errors
        });
    });
}
"""

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("start app")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("applicationWillTerminate")
        running = false
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        NSLog("windowDidResize")
    }
    
    func windowWillClose(_ notification: Notification) {
        NSLog("windowWillClose")
        running = false
    }
}

class ScriptHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        NSLog("message: %@",message.name)
    }
}


@_cdecl("sayHello") // export to C as `sayHello`
public func sayHello() {
    
     app = NSApplication.shared
    


    let appDelegate = AppDelegate()
    app!.delegate = appDelegate
    app!.setActivationPolicy(.regular)
    app!.finishLaunching()
    app!.mainMenu = makeMainMenu()

    let window = NSWindow(contentRect: NSMakeRect(0, 0, 1024, 768),
                          styleMask: [.closable, .titled, .resizable, .miniaturizable],
                          backing: .buffered,
                          defer: true)
    
    let windowDelegate = WindowDelegate()
    window.delegate = windowDelegate
    window.title = "Hey, Window under control!"
    window.center()
    window.orderFrontRegardless()
    
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    
    scriptHandler =  ScriptHandler()
    webConfiguration.userContentController.add(scriptHandler!, name:"app")
    
    webView = WKWebView(frame: .zero, configuration: webConfiguration)

    
    window.contentView = webView


    app!.activate(ignoringOtherApps: true)

}

// https://github.com/eonil/CocoaProgrammaticHowtoCollection/blob/master/ComponentUsages/ApplicationMenu/main.swift
func makeMainMenu() -> NSMenu {
    let mainMenu            = NSMenu() // `title` really doesn't matter.
    let mainAppMenuItem     = NSMenuItem(title: "Application", action: nil, keyEquivalent: "") // `title` really doesn't matter.
    mainMenu.addItem(mainAppMenuItem)

    let appMenu             = NSMenu() // `title` really doesn't matter.
    mainAppMenuItem.submenu = appMenu

    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

    return mainMenu
}

@_cdecl("run")
func run(){
    NSLog("run")
    app?.run()
//    while(running) {
//        var ev: NSEvent?
//        ev = app!.nextEvent(matching: .any, until: nil, inMode: .default, dequeue: true)
//        if (ev != nil) {
////            NSLog("%@", ev!)
//            app!.sendEvent(ev!)
//        }
//    }
//    app!.terminate(nil)
}

@_cdecl("navigate")
func navigate(target: UnsafePointer<CChar>?) {
    NSLog("navigate")
    let myURL = URL(string:String(cString: target!))
    let myRequest = URLRequest(url: myURL!)
    webView!.load(myRequest)

    let script = WKUserScript(source: jsGetJson, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    webView!.configuration.userContentController.addUserScript(script)

    NSLog("navigate done")
}

@_cdecl("_bind")
func bind(cName: UnsafePointer<CChar>?) {
    let name = String(cString: cName!)
    let js = String(format:jsFunction, name,name)
    let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    webView!.configuration.userContentController.addUserScript(script)
}

@_cdecl("_evalJS")
func evalJS(cJS: UnsafePointer<CChar>?) {
    let js = String(cString: cJS!)
    webView?.evaluateJavaScript(js) { (result, error) in
        if (error == nil) && (result != nil){
            print(result!)
        }
    }
}
