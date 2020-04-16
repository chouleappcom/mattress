//
//  ViewController.swift
//  MattressExample
//
//  Created by Kevin Lord on 11/13/15.
//  Copyright © 2015 BuzzFeed. All rights reserved.
//

import UIKit
import Mattress
import os

class ViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    let urlToCache = URL(string: "https://www.google.com")

    @IBAction func cachePage() {

        os_log("Caching page", type: .debug)
        if let cache = NSURLCache.shared as? Mattress.URLCache,
			let urlToCache = urlToCache
        {
			cache.diskCacheURL(url: urlToCache, loadedHandler: { (webView) -> (Bool) in
				let state = webView.stringByEvaluatingJavaScript(from: "document.readyState")
                    if state == "complete" {
                        // Loading is done once we've returned true
                        return true
                    }
                    return false
                }, completeHandler: { () -> Void in
                    os_log("Finished caching", type: .debug)
                }, failureHandler: { (error) -> Void in
                    os_log("Error caching %s", type: .error, "\(error)")
            })
        }
    }

    @IBAction func loadPage() {
        if let urlToCache = urlToCache {
            let request = URLRequest(url: urlToCache)
            webView.loadRequest(request)
        }
    }
}

