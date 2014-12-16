//
//  URLProtocol.swift
//  Mattress
//
//  Created by David Mauro on 11/12/14.
//  Copyright (c) 2014 BuzzFeed. All rights reserved.
//

import Foundation

var caches: [URLCache] = []
private let URLProtocolHandledRequestKey = "URLProtocolHandledRequestKey"

/**
    URLProtocol is an NSURLProtocol in charge of ensuring
    that any requests made as a result of a WebViewCacher
    are forwarded back to the WebViewCacher responsible.

    Additionally it ensures that when we are offline, we will
    use the offline diskCache if possible.
*/
class URLProtocol: NSURLProtocol, NSURLConnectionDataDelegate {
    var connection: NSURLConnection?

    // MARK: - Class Methods

    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        if NSURLProtocol.propertyForKey(URLProtocolHandledRequestKey, inRequest: request) != nil {
            return false
        }

        // We should only use this protocol when there is a webViewCacher
        // responsible for the request, or if we are offline
        if let webViewCacher = webViewCacherForRequest(request) {
            return true
        }
        if let cache = NSURLCache.sharedURLCache() as? URLCache {
            if let handler = cache.isOfflineHandler {
                return handler()
            }
        }
        return false
    }

    /**
        addCache: Adds another URLCache that should
        be checked in with when deciding which/if a
        WebViewCacher is responsible for a request.
    
        This method is responsible for having this
        protocol registered. It will only register
        itself when there is a URLCache that has been
        added.
    */
    class func addCache(cache: URLCache) {
        if caches.count == 0 {
            registerProtocol(true)
        }
        caches.append(cache)
    }

    /**
        removeCache: removes the URLCache from the
        list of caches that should be used to find the
        WebViewCacher responsible for requests.
    
        If there are no more caches, this protocol will
        unregister itself.
    */
    class func removeCache(cache: URLCache) {
        var index = find(caches, cache)
        if let index = index {
            caches.removeAtIndex(index)
            if caches.count == 0 {
                registerProtocol(false)
            }
        }
    }

    class func registerProtocol(shouldRegister: Bool) {
        if shouldRegister {
            NSURLProtocol.registerClass(self)
        } else {
            NSURLProtocol.unregisterClass(self)
        }
    }

    /**
        Finds the webViewCacher responsible for a request by
        asking each of its URLCaches in reverse order.
    */
    class func webViewCacherForRequest(request: NSURLRequest) -> WebViewCacher? {
        for i in reverse(0..<caches.count) {
            let cache = caches[i]
            if let webViewCacher = cache.webViewCacherOriginatingRequest(request) {
                return webViewCacher
            }
        }
        return nil
    }

    class func mutableCanonicalRequestForRequest(request: NSURLRequest) -> NSMutableURLRequest {
        var mutableRequest = request.mutableCopy() as NSMutableURLRequest
        mutableRequest.cachePolicy = .ReturnCacheDataElseLoad
        if let webViewCacher = webViewCacherForRequest(request) {
            mutableRequest = webViewCacher.mutableRequestForRequest(request)
        }
        NSURLProtocol.setProperty(true, forKey: URLProtocolHandledRequestKey, inRequest: mutableRequest)
        return mutableRequest
    }

    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return mutableCanonicalRequestForRequest(request)
    }

    override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, toRequest:b)
    }

    // MARK: - Instance Methods

    override func startLoading() {
        var mutableRequest = URLProtocol.mutableCanonicalRequestForRequest(request)
        if let cache = NSURLCache.sharedURLCache() as? URLCache {
            let cachedResponse = cache.cachedResponseForRequest(mutableRequest)
            if let cachedResponse = cachedResponse {
                client?.URLProtocol(self, cachedResponseIsValid: cachedResponse)
                return
            }
        }
        self.connection = NSURLConnection(request: mutableRequest, delegate: self)
    }

    override func stopLoading() {
        connection?.cancel()
        connection = nil
    }

    // Mark: - NSURLConnectionDataDelegate Methods

    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse) {
        self.client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .Allowed)
    }

    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.client?.URLProtocol(self, didLoadData: data)
    }

    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.client?.URLProtocolDidFinishLoading(self)
    }

    func connection(connection: NSURLConnection!, didFailWithError error: NSError) {
        self.client?.URLProtocol(self, didFailWithError: error)
    }
}