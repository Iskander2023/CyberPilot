//
//  WebVideoView.swift
//  Robot_Controller
//
//  Created by Admin on 5/03/25.

import WebKit
import UIKit
import os

 //рабочая версия
class WebVideoView: UIView {
    
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    var webView: WKWebView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func loadVideoStream(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func playVideo() {
        let playScript = "document.querySelectorAll('video').forEach(v => v.play());"
        webView.evaluateJavaScript(playScript, completionHandler: nil)
        logger.info("Видео на основоном экране запущено")
    }

    
    func pauseVideo() {
        webView.pauseAllMediaPlayback()
        logger.info("Пауза")
    }
    
    func stopVideo() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        webView.configuration.userContentController.removeAllUserScripts()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        logger.info("⚠️ Видео отключено")
        
    }
}
