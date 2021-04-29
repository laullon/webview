package webview

// xcode-select -p
// xcrun --sdk macosx --show-sdk-path

/*
#cgo CFLAGS: -I.
#cgo LDFLAGS: -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift/ -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx/ -Lmacos/.build/debug -lwebview
#include <stdlib.h>
#include "webview.h"
*/
import "C"
import (
	"fmt"
	"net/http"
)

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
	C.sayHello()
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
func (wv *webview) Eval(js string)      { C._evalJS(C.CString(js)) }

func (wv *webview) Bind(name string, f interface{}) error {
	wv.f["/cmd/"+name] = f
	C._bind(C.CString(name))
	return nil
}

func (wv *webview) ServeHTTP(res http.ResponseWriter, req *http.Request) {
	cmd := req.URL.EscapedPath()
	println("-->", cmd)
	if f, ok := wv.f[cmd]; ok {
		fmt.Printf("executing cmd '%s' (%T)\n", cmd, f)
		switch cmdF := f.(type) {
		case func():
			cmdF()

		case func() string:
			resBody := cmdF()
			res.Write([]byte(resBody))

		default:
			fmt.Printf("[Error] cmd '%s' (%T) not supported.\n", cmd, f)
		}
	} else {
		fmt.Printf("[Error] cmd '%s' not found.\n", cmd)
	}
}
