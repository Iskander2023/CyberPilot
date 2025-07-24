//
//  WebView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 23/04/25.
//

import SwiftUI
import WebKit


struct WebView: UIViewRepresentable {
    let urlString: String
    var onLoadFailed: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoadFailed: onLoadFailed)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)

        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            return
        }
        let request = URLRequest(url: url)
        uiView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var onLoadFailed: (() -> Void)?

        init(onLoadFailed: (() -> Void)?) {
            self.onLoadFailed = onLoadFailed
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadFailed?()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onLoadFailed?()
        }
    }
}


//struct WebView: UIViewRepresentable {
//    let urlString: String
//    
//    var onLoadFailed: (() -> Void)?  // Новый колбэк для ошибки загрузки
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(onLoadFailed: onLoadFailed)
//    }
//
//    func makeUIView(context: Context) -> WKWebView {
//        let config = WKWebViewConfiguration()
//        config.allowsInlineMediaPlayback = true
//        config.mediaTypesRequiringUserActionForPlayback = []
//        config.allowsAirPlayForMediaPlayback = true
//        
//        let webView = WKWebView(frame: .zero, configuration: config)
//        webView.navigationDelegate = context.coordinator
//        return webView
//    }
//
//    
//    func updateUIView(_ uiView: WKWebView, context: Context) {
//        guard let url = URL(string: urlString) else { return }
//        let request = URLRequest(url: url)
//        uiView.load(request)
//    }
//    
//    
//    class Coordinator: NSObject, WKNavigationDelegate {
//            var onLoadFailed: (() -> Void)?
//
//            init(onLoadFailed: (() -> Void)?) {
//                self.onLoadFailed = onLoadFailed
//            }
//
//            func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//                print("❌ Failed to load video: \(error.localizedDescription)")
//                onLoadFailed?()
//            }
//
//            func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//                print("❌ Provisional navigation failed: \(error.localizedDescription)")
//                onLoadFailed?()
//            }
//        }
//    }




