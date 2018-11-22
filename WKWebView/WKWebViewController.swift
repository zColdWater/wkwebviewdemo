import UIKit
import WebKit

let jsInvokeNative: String = "jsInvokeNative"
let nativeInvokeJs: String = "nativeInvokeJs"
let dismissPage: String = "dismissPage"


class WKWebViewController: UIViewController, WKScriptMessageHandler {

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 适当的时机 移除 WKScriptMessageHandler 防止引用循环
        webview.configuration.userContentController.removeScriptMessageHandler(forName: jsInvokeNative)
        webview.configuration.userContentController.removeScriptMessageHandler(forName: nativeInvokeJs)
        webview.configuration.userContentController.removeScriptMessageHandler(forName: dismissPage)
    }
    
    /// Create WKWebView
    lazy var webview: WKWebView = {
        let userContentController: WKUserContentController = WKUserContentController()
        
        // Inject javascript functions
        userContentController.add(self, name: jsInvokeNative)
        userContentController.add(self, name: nativeInvokeJs)
        userContentController.add(self, name: dismissPage)
        let configuration: WKWebViewConfiguration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        let webview = WKWebView(frame: self.view.frame, configuration: configuration)
        let htmlPath = Bundle.main.path(forResource: "test", ofType: "html")
        let url = URL(fileURLWithPath: htmlPath!)
        let request = URLRequest(url: url)
        webview.load(request)
        return webview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webview)
    }
    
    
    // Native invoke JS function
    func nativeInvokeJavascript() {
        DispatchQueue.main.async {
            // 注意: 此方法 只有在整个WebView都加载完成 才会有反应。
            self.webview.evaluateJavaScript("nativeMessageHandler('action1', 'param1')", completionHandler: { (feedback, error) in
                // here is code
            })
        }
    }
    
    
    
    // MARK: - WKScriptMessageHandler
    
    // Waiting Javascript Invoke Native Function
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("name:\(message.name)")
        print("body:\(message.body)")
        
        // Native 调用 JS 方法
        if message.name == nativeInvokeJs {
            self.nativeInvokeJavascript()
        }
        
        if message.name == dismissPage {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
}






