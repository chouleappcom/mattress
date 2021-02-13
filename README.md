Mattress
========
A Swift framework for storing entire web pages into a disk cache distinct from, but interoperable with, the standard NSURLCache layer. This is useful for both pre-caching web content for faster loading, as well as making web content available for offline browsing.

**Requirements**
----------------

- iOS 11+
- Swift Package Manager 5.3+

**Usage**
---------
You should create an instance of URLCache and set it as the shared
cache for your app in your application:didFinishLaunching: method.

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let kB = 1024
    let MB = 1024 * kB
    let GB = 1024 * MB
    let isOfflineHandler: (() -> Bool) = {
        // This is for demonstration only.
        // You should use Reachability or your preferred method to determine offline status
        // and return a proper value here.
        return false
    }
    let urlCache = Mattress.URLCache(memoryCapacity: 20 * MB, diskCapacity: 20 * MB, diskPath: nil,
    	mattressDiskCapacity: 1 * GB, mattressDiskPath: nil, mattressSearchPathDirectory: .DocumentDirectory,
    	isOfflineHandler: isOfflineHandler)
    
    NSURLCache.setSharedURLCache(urlCache)
    return true
}
```

To cache a webPage in the Mattress disk cache, simply call URLCache's diskCacheURL:loadedHandler: method.

```swift
NSLog("Caching page")
let urlToCache = NSURL(string: "https://www.google.com")
if let
    cache = NSURLCache.sharedURLCache() as? Mattress.URLCache,
    urlToCache = urlToCache
{
    cache.diskCacheURL(urlToCache, loadedHandler: { (webView) -> (Bool) in
            /*
               Note: The below code should work for fairly simple pages. However, if the page you are
               attempting to cache contains progressively / lazily loaded images or other assets you
               will also need to trigger any JavaScript functions here to mimic user actions and
               ensure those assets are also loaded before returning true.
            */
            let state = webView.stringByEvaluatingJavaScriptFromString("document.readyState")
            if state == "complete" {
                // Loading is done once we've returned true
                return true
            }
            return false
        }, completeHandler: { () -> Void in
            NSLog("Finished caching")
        }, failureHandler: { (error) -> Void in
            NSLog("Error caching: %@", error)
    })
}
```

Once cached, you can simply load the webpage in a UIWebView and it will be loaded from the Mattress cache, like magic.


**Contributing**
----------------

Contributions are welcome. Please feel free to open a pull request. 

We also welcome feature requests and bug reports. Just open an issue.

**License**
---------

Mattress is licensed under the MIT License.
