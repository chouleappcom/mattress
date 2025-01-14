//
//  WKWebViewCacher.swift
//  Mattress
//
//  Created by Claude Houle on 2020-04-16.

import Foundation
import UIKit
import WebKit
import os

public typealias WKWebViewLoadedHandler = (WKWebView) -> (Bool)
typealias WKWebViewCacherCompletionHandler = (WKWebViewCacher) -> ()

/**
 WKWebViewCacher is in charge of loading all of the
 requests associated with a url and ensuring that
 all of that webpage's request have the property
 to signal that they should be stored in the Mattress
 disk cache.
 */
class WKWebViewCacher: NSObject {

    // MARK: - Properties
    private let queue = DispatchQueue(label: "MattressWKWebViewCacher", attributes: .concurrent)

    /// Handler called to determine if a webpage is considered loaded.
    var loadedHandler: WKWebViewLoadedHandler?

    /// Handler called once a webpage has finished loading.
    var completionHandler: WKWebViewCacherCompletionHandler?

    /// Handler called if a webpage fails to load.
    var failureHandler: ((Error) -> ())? = nil

    /// Main URL for the webpage request.
    private var mainDocumentURL: URL?

    /// Webview used to load the webpage.
    private var webView: WKWebView?

    // MARK: - Instance Methods

    /**
     Uses the associated mainDocumentURL to determine if it
     thinks it is responsible for a given NSURLRequest.

     This is necessary because the UIWebView can fire off requests
     without telling the webViewDelegate about them, so the
     URLProtocol will catch them for us, which should result in
     this method being called.

     :param: request The request in question.

     :returns: A Bool indicating whether this WebViewCacher is
     responsible for that NSURLRequest.
     */
    func didOriginateRequest(request: URLRequest) -> Bool {
        if let mainDocumentURL = mainDocumentURL {
            if request.mainDocumentURL == mainDocumentURL || request.url == mainDocumentURL {
                return true
            }
        }
        return false
    }

    /**
     Creates a mutable request for a given request that should
     be handled by the WebViewCacher.

     The property signaling that the request should be stored in
     the Mattress disk cache will be added.

     :param: request The request.

     :returns: A mutable request based on the requested passed in.
     */
    func mutableRequestForRequest(request: URLRequest) -> URLRequest {
        let mutableRequest = request
        NSURLProtocol.setProperty(true, forKey: MattressCacheRequestPropertyKey, in: mutableRequest as! NSMutableURLRequest)
        return mutableRequest
    }

    /**
     mattressCacheURL:loadedHandler:completionHandler: is the main
     entry point for dealing with WebViewCacher. Calling this method
     will result in a new UIWebView being generated to cache all the
     requests associated with the given NSURL to the Mattress disk cache.

     :param: url The url to be cached.
     :param: loadedHandler The handler that will be called every time
     the webViewDelegate's webViewDidFinishLoading method is called.
     This should return a Bool indicating whether we should stop
     loading.
     :param: completionHandler Called once the loadedHandler has returned
     true and we are done caching the requests at the given url.
     :param: completionHandler Called if the webpage fails to load.
     */
    func mattressCacheURL(url: URL,
                          loadedHandler: @escaping WKWebViewLoadedHandler,
                          completionHandler: @escaping WKWebViewCacherCompletionHandler,
                          failureHandler: @escaping (Error) -> ()) {
        self.loadedHandler = loadedHandler
        self.completionHandler = completionHandler
        self.failureHandler = failureHandler
        loadURLInWebView(url: url)
    }

    // MARK: WebView Loading

    /**
     Loads a URL in the webview associated with the WebViewCacher.

     :param: url URL of the webpage to be loaded.
     */
    private func loadURLInWebView(url: URL) {
        let webView = WKWebView(frame: .zero)
        let request = URLRequest(url: url)
        let mutableRequest = mutableRequestForRequest(request: request)
        self.webView = webView
        webView.navigationDelegate = self
        webView.load(mutableRequest)
    }
}

// MARK: - UIWebViewDelegate
extension WKWebViewCacher: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        var isComplete = true


        queue.sync(flags: .barrier){
            if let loadedHandler = self.loadedHandler {
                isComplete = loadedHandler(webView)
            }
            if isComplete == true {
                webView.stopLoading()
                self.webView = nil

                if let completionHandler = self.completionHandler {
                    completionHandler(self)
                }
                self.completionHandler = nil
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // We can ignore this error as it just means canceled.
        // http://stackoverflow.com/a/1053411/1084997
        if (error as NSError).code == NSURLErrorCancelled {
            return
        }

        os_log("WebViewLoadError: %s", type: .error, "\(error)")

        queue.sync(flags: .barrier){
            if let failureHandler = self.failureHandler {
                failureHandler(error)
            }
            self.failureHandler = nil
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        mainDocumentURL = navigationAction.request.mainDocumentURL
        if !URLCache.requestShouldBeStoredInMattress(request: request) {
            let mutableRequest = mutableRequestForRequest(request: request)
            webView.load(mutableRequest)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    @available(iOS 13, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        let request = navigationAction.request
        mainDocumentURL = navigationAction.request.mainDocumentURL
        if !URLCache.requestShouldBeStoredInMattress(request: request) {
            let mutableRequest = mutableRequestForRequest(request: request)
            webView.load(mutableRequest)
            decisionHandler(.cancel, preferences)
            return
        }

        decisionHandler(.allow, preferences)
    }
}
