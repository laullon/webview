package webview

// xcode-select -p
// xcrun --sdk macosx --show-sdk-path

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework WebKit -framework cocoa
#include "macos/webview.m"
*/
import "C"
import (
	"fmt"
	"net/http"
)

var jsGetJson = `
var getJSON = function(url, callback) {
    return new Promise(function (resolve, reject) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onload = resolve;
        xhr.onerror = reject;
        xhr.send();
    });
};
`

var jsFunction = `
function %s(arg) {
    return new Promise(function (resolve, reject) {
        getJSON('/cmd/%s?arg='+arg).then(function (e) {
            console.log(e.target.response);
            resolve(e.target.response)
        }, function (e) {
        // handle errors
        });
    });
}`

type WebView interface {
	http.Handler

	Run()
	Navigate(url string)
	Destroy()

	// Terminate()
	// Dispatch(f func())
	// Window() unsafe.Pointer
	// SetTitle(title string)
	// SetSize(w int, h int)
	// Init(js string)

	Eval(js string)
	Bind(name string, f interface{}) error
}

func New(title string, w, h int) WebView {
	C.StartApp()
	C.bindFunction(C.CString(jsGetJson))
	return &webview{
		f: make(map[string]interface{}),
	}
}

type webview struct {
	f map[string]interface{}
}

func (wv *webview) Run()                { C.run() }
func (wv *webview) Navigate(url string) { C.navigate(C.CString(url)) }
func (wv *webview) Destroy()            {}
func (wv *webview) Eval(js string)      { C.evalJS(C.CString(js)) }

func (wv *webview) Bind(name string, f interface{}) error {
	wv.f["/cmd/"+name] = f
	js := fmt.Sprintf(jsFunction, name, name)
	C.bindFunction(C.CString(js))
	return nil
}

func (wv *webview) ServeHTTP(res http.ResponseWriter, req *http.Request) {
	cmd := req.URL.EscapedPath()
	arg := req.URL.Query().Get("arg")
	if f, ok := wv.f[cmd]; ok {
		fmt.Printf("executing cmd '%s' (%T)\n", cmd, f)
		switch cmdF := f.(type) {
		case func():
			cmdF()

		case func() string:
			resBody := cmdF()
			res.Write([]byte(resBody))

		case func(string):
			cmdF(arg)

		default:
			fmt.Printf("[Error] cmd '%s' (%T) not supported.\n", cmd, f)
		}
	} else {
		fmt.Printf("[Error] cmd '%s' not found.\n", cmd)
	}
}
