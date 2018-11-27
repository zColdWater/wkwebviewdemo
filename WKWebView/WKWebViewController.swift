import UIKit
import WebKit

let jsInvokeNative: String = "jsInvokeNative"
let nativeInvokeJs: String = "nativeInvokeJs"
let dismissPage: String = "dismissPage"


class WKWebViewController: UIViewController, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {

    
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
        
        
        /*! @abstract Adds a script message handler.
         @param scriptMessageHandler The message handler to add.
         @param name The name of the message handler.
         @discussion Adding a scriptMessageHandler adds a function
         window.webkit.messageHandlers.<name>.postMessage(<messageBody>) for all
         frames.
         */
        // Inject javascript functions for javascript invoke native methods
        userContentController.add(self, name: jsInvokeNative)
        userContentController.add(self, name: nativeInvokeJs)
        userContentController.add(self, name: dismissPage)
        
        
        
        
        /*! @abstract Returns an initialized user script that can be added to a @link WKUserContentController @/link.
         @param source The script source.
         @param injectionTime When the script should be injected.
         @param forMainFrameOnly Whether the script should be injected into all frames or just the main frame.
         */
        // injectionTime When the script should be injected.
        let source = "document.body.style.background = \"#777\";"
        let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)
        
        
        
        let configuration: WKWebViewConfiguration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        

        
        
        let webview = WKWebView(frame: self.view.frame, configuration: configuration)
        let htmlPath = Bundle.main.path(forResource: "test", ofType: "html")
        let url = URL(fileURLWithPath: htmlPath!)
        let request = URLRequest(url: url)
        webview.load(request)
        webview.uiDelegate = self
        webview.navigationDelegate = self
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
    
    
    
    // MARK: - WKNavigationDelegate
    
    // 【方法一】
    // 决定网页是否允许跳转。
    // 是否决定要加载当前的H5。
    // WebView里面的每一次请求都会被拦截。
    // 然后通过 decisionHandler 回调参数 来决定 允许 或者 失败。
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let host = navigationAction.request.url?.host {
            if host == "zcoldwater.github.io" {
                // 不允许
                decisionHandler(WKNavigationActionPolicy.cancel)
                return
            }
        }
        // 允许
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    // 【方法二】
    // 收到网页 Response 决定是否跳转
    // 1. 先经过【方法一】再经过【方法二】
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        // 默认回调参数 allow 允许跳转
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    
    // 【方法三】
    // 页面内容开始加载
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("页面内容正在开始加载！")
    }
    
    // 【方法四】
    // 网页内容加载失败
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("网页内容加载失败！")
    }
    
    // 【方法五】
    // 网页内容加载完成后，返回内容至 webview
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("网页内容加载完成后，返回内容至 webview")
    }
    
    // 【方法六】
    // 网页加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("网页加载完成")
    }
    
    // 【方法七】
    // 网页返回内容至 webview 时发生失败
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("网页返回内容至 webview 时发生失败")
    }
    
    // 【方法八】
    // 收到网页重新定向的请求
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("收到页面重定向请求")
    }

    // 【方法九】
    // 处理网页过程中发生终止
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("处理网页过程中发生终止\n 内存占用过大等原因导致的系统调用此方法")
    }

    
    
    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        print("webViewDidClose:\(webView)")
    }
    
    // JS 代码调用 alert("参数A")
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("runJavaScriptAlertPanelWithMessage")
        print("alert message:\(message)")
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
            }}))
        self.present(alert, animated: true, completion: nil)
        
        completionHandler()
    }
    
    // JS 代码调用 confirm("参数A")
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        print("runJavaScriptConfirmPanelWithMessage")
        print("message:\(message)")
        completionHandler(true)
    }
    
    // JS 代码调用 prompt("参数A", "参数B")
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("prompt:\(prompt)")
        print("defaultText:\(String(describing: defaultText))")
        
        // 同步调用
        if defaultText! == "sync" {
            completionHandler(prompt)
            return
        }
        
        // 异步调用
        if defaultText! == "async" {
            let data = prompt.data(using: .utf8)
            let dic = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
            print("data:\(String(describing: dic!["data"]))")
            // 同步返回给JS返回值
            completionHandler(dic!["data"] as? String)
            
            // 为了Demo演示这里就在执行完 返回值 回调JS
            let jsMethod = dic!["callbackName"] as! String
            webview.evaluateJavaScript("\(jsMethod)(\"回调参数111\")", completionHandler: nil)
            return
        }
        
        // 非异步 同步 调用 返回空字符串
        completionHandler("")
    }
    
    // 能否预览用户触摸的元素
    // 根据实际情况实现
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return true
    }
    
    // 定制预览控制器
    // 根据实际情况实现
    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        return nil
    }
    
    // 可弹出的视图控制器
    // 根据实际情况实现
    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
    }
    
    
}

