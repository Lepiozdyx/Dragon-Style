import SwiftUI
import WebKit
import Foundation
import UIKit
import UniformTypeIdentifiers

struct WebViewManager: UIViewRepresentable {
    var webView: WKWebView
    var url: URL
    
    var timeStarted: Date = Date.now
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    init(address: URL) {
        url = address
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.evaluateJavaScript("navigator.userAgent") { result, error in
            if let userAgent = result as? String {
                print(result)
            }}
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bounces = true
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        webView.uiDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebViewManager
        
        init(_ parent: WebViewManager) {
            self.parent = parent
            super.init()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.timeStarted = Date.now
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let finalURL = webView.url else {
                return
            }
            
            if finalURL.absoluteString != WebManager.initialURL && !finalURL.absoluteString.contains("google"){
                if WebManager.getSavedUrl() == ""
                {
                    WebManager.trySetSavedUrl(finalURL)
                }
            } else {
                print("Failed to load: \(finalURL)")
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Navigation failed")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("Navigation failed")
        }
        
        func topViewController(from root: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
            guard let root = root else { return nil }
            
            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }
            
            if let nav = top as? UINavigationController {
                return topViewController(from: nav.visibleViewController)
            }
            
            if let tab = top as? UITabBarController {
                return topViewController(from: tab.selectedViewController)
            }
            
            return top
        }
        
        public func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url else {
                return nil
            }
            parent.webView.load(URLRequest(url: url))
            return nil
        }
        
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            DispatchQueue.main.async {
                if let url = navigationAction.request.url,
                   let scheme = url.scheme?.lowercased() {
                    let inAppSchemes: Set<String> = ["http", "https", "about", "data", "file"]
                    if !inAppSchemes.contains(scheme) {
                        print("Opening url: \(url)")
                        UIApplication.shared.open(url, options: [:]) { success in
                            if success {
                                print("Successfully opened url: \(url)")
                            } else {
                                print("Failed to open url: \(url)")
                            }
                        }
                        decisionHandler(.cancel)
                        return
                    }
                }
                decisionHandler(.allow)
            }
        }
        
        public func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                completionHandler()
            }))
            
            topViewController()?.present(alertController, animated: true, completion: nil)
        }
        
        public func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                completionHandler(true)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                completionHandler(false)
            }))
            
            topViewController()?.present(alertController, animated: true, completion: nil)
        }
        
        public func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .actionSheet)
            
            alertController.addTextField { (textField) in
                textField.text = defaultText
            }
            
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                if let text = alertController.textFields?.first?.text {
                    completionHandler(text)
                } else {
                    completionHandler(defaultText)
                }
                
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                
                completionHandler(nil)
                
            }))
            
            topViewController()?.present(alertController, animated: true, completion: nil)
        }
    }
}
