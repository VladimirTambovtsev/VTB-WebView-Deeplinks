//
//  WebView.swift
//  VTB Deeplinks
//
//  Created by Владимир Тамбовцев on 27.08.2024.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Enable JavaScript console logging
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        // Inject script to capture console messages
        let script = WKUserScript(
            source: """
            (function() {
                var originalLog = console.log;
                var originalError = console.error;
                var originalWarn = console.warn;
                var originalInfo = console.info;
                
                console.log = function() {
                    originalLog.apply(console, arguments);
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: 'log',
                        message: Array.from(arguments).map(arg => String(arg)).join(' ')
                    });
                };
                
                console.error = function() {
                    originalError.apply(console, arguments);
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: 'error',
                        message: Array.from(arguments).map(arg => String(arg)).join(' ')
                    });
                };
                
                console.warn = function() {
                    originalWarn.apply(console, arguments);
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: 'warn',
                        message: Array.from(arguments).map(arg => String(arg)).join(' ')
                    });
                };
                
                console.info = function() {
                    originalInfo.apply(console, arguments);
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: 'info',
                        message: Array.from(arguments).map(arg => String(arg)).join(' ')
                    });
                };
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        configuration.userContentController.addUserScript(script)
        configuration.userContentController.add(context.coordinator, name: "consoleLog")
        
        // Create webview with configuration
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // Set delegates for debugging
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Enable inspection for debugging (only works in debug builds)
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only load if URL hasn't been loaded yet
        if uiView.url == nil || uiView.url != url {
            let request = URLRequest(url: url)
            print("🌐 [WebView] Loading URL: \(url.absoluteString)")
            uiView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🚀 [Navigation] Started loading: \(webView.url?.absoluteString ?? "unknown")")
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            print("✅ [Navigation] Committed: \(webView.url?.absoluteString ?? "unknown")")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✨ [Navigation] Finished loading: \(webView.url?.absoluteString ?? "unknown")")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [Navigation] Failed: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URL Error Code: \(urlError.code.rawValue)")
                print("   URL Error Description: \(urlError.localizedDescription)")
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("⚠️ [Navigation] Failed Provisional: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URL Error Code: \(urlError.code.rawValue)")
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                print("📤 [Request] \(navigationAction.request.httpMethod ?? "GET") \(url.absoluteString)")
                
                // Log request headers
                if let headers = navigationAction.request.allHTTPHeaderFields, !headers.isEmpty {
                    print("   Headers: \(headers)")
                }
                
                // Log request body if present
                if let httpBody = navigationAction.request.httpBody,
                   let bodyString = String(data: httpBody, encoding: .utf8) {
                    print("   Body: \(bodyString)")
                }
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let response = navigationResponse.response as? HTTPURLResponse {
                let url = response.url?.absoluteString ?? "unknown"
                print("📥 [Response] \(response.statusCode) \(url)")
                
                // Log response headers
                if !response.allHeaderFields.isEmpty {
                    print("   Headers: \(response.allHeaderFields)")
                }
                
                // Log content type
                if let contentType = response.value(forHTTPHeaderField: "Content-Type") {
                    print("   Content-Type: \(contentType)")
                }
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate (for JavaScript console logs)
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            print("🔔 [JS Alert] \(message)")
            completionHandler()
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            print("❓ [JS Confirm] \(message)")
            completionHandler(true)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            print("⌨️ [JS Prompt] \(prompt)")
            completionHandler(defaultText)
        }
    }
}

// MARK: - WKScriptMessageHandler for JavaScript console messages
extension WebView.Coordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "consoleLog" {
            if let body = message.body as? [String: Any],
               let level = body["level"] as? String,
               let logMessage = body["message"] as? String {
                let emoji: String
                switch level {
                case "error":
                    emoji = "🔴"
                case "warn":
                    emoji = "🟡"
                case "info":
                    emoji = "🔵"
                default:
                    emoji = "📝"
                }
                print("\(emoji) [JS Console.\(level)] \(logMessage)")
            }
        } else {
            print("💬 [JS Message] \(message.name): \(message.body)")
        }
    }
}
