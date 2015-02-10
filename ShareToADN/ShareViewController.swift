//
//  ShareViewController.swift
//  ShareToADN
//
//  Created by dasdom on 09.08.14.
//  Copyright (c) 2014 Dominik Hauser. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import PostToADN
import KeychainAccess

class ShareViewController: SLComposeServiceViewController, NSURLSessionDelegate {

    var urlSession: NSURLSession?
    
    var imageToShare: UIImage?
    var urlToShare: NSURL?
    let adnApiCommunicator = ADNAPICommunicator()

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
//    override func viewDidLoad() { // 1
//        let items = extensionContext?.inputItems
//        var itemProvider: NSItemProvider?
//        
//        if items != nil && items!.isEmpty == false {
//            let item = items![0] as NSExtensionItem
//            if let attachments = item.attachments {
//                if !attachments.isEmpty {
//                    itemProvider = attachments[0] as? NSItemProvider
//                }
//            }
//        }
//        
//        let imageType = kUTTypeImage as NSString as String
//        let urlType = kUTTypeURL as NSString  as String
//        
//        if itemProvider?.hasItemConformingToTypeIdentifier(imageType) == true {
//            itemProvider?.loadItemForTypeIdentifier(imageType, options: nil) { (item, error) -> Void in
//                if error == nil {
//                    let url = item as NSURL
//                    if let imageData = NSData(contentsOfURL: url) {
//                        self.imageToShare = UIImage(data: imageData)
//                    }
//                }
//            }
//        } else if itemProvider?.hasItemConformingToTypeIdentifier(urlType) == true {
//            itemProvider?.loadItemForTypeIdentifier(urlType, options: nil) { (item, error) -> Void in
//                if error == nil {
//                    if let url = item as? NSURL {
//                        self.urlToShare = url
//                    }
//                }
//            }
//        }
//    }
    
    override func presentationAnimationDidFinish() {
        let items = extensionContext?.inputItems
        var itemProvider: NSItemProvider?
        
        println("items: \(items)")
        
        if items != nil && items!.isEmpty == false {
            let item = items![0] as! NSExtensionItem
            if let attachments = item.attachments {
//                if !attachments.isEmpty {
//                    itemProvider = attachments[0] as? NSItemProvider
//                }
                for attachment in attachments {
                    itemProvider = attachment as? NSItemProvider
                    
                    let imageType = kUTTypeImage as NSString as String
                    let urlType = kUTTypeURL as NSString  as String
                    
                    if itemProvider?.hasItemConformingToTypeIdentifier(urlType) == true {
                        itemProvider?.loadItemForTypeIdentifier(urlType, options: nil) { (item, error) -> Void in
                            if error == nil {
                                if let url = item as? NSURL {
                                    self.urlToShare = url
                                }
                            }
                        }
                    } else if itemProvider?.hasItemConformingToTypeIdentifier(imageType) == true {
                        itemProvider?.loadItemForTypeIdentifier(imageType, options: nil) { (item, error) -> Void in
                            if error == nil {
                                println("item: \(item)")
                                if let url = item as? NSURL {
                                    if let imageData = NSData(contentsOfURL: url) {
                                        self.imageToShare = UIImage(data: imageData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    override func isContentValid() -> Bool {
        charactersRemaining = 256 - contentText.utf16Count
        
        return contentText.utf16Count < 256
    }

    override func didSelectPost() {
       
        let accessToken = KeychainAccess.passwordForAccount("AccessToken")
        if accessToken == nil {
            return
        }
        
        if let urlToShare = urlToShare {
            
            println("\(urlToShare.absoluteString)")
            
            var linkLocation = 0
            var linkLength = self.contentText.utf16Count
            var postString = String()
            var index = 0
            for char in self.contentText {
                if char == "[" {
                    linkLocation = index
                } else if char == "]" {
                    linkLength = index - linkLocation - 1
                } else {
                    postString.append(char)
                }
                ++index
            }
            
            let linkDict = ["url" : urlToShare.absoluteString!, "pos": "\(linkLocation)", "len": "\(linkLength)"]
            let linksArray: [[String:String]] = [linkDict]
            
            let urlSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            self.urlSession = NSURLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: nil)
            
            let request = RequestFactory()
            let urlSessionTask = self.urlSession!.dataTaskWithRequest(RequestFactory.postRequestFromPostText(postString, linksArray: linksArray, accessToken: accessToken!), completionHandler: { (data, response, error) -> Void in
                println("response: \(response)")
                let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("responseString: \(responseString)")
                self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
            })
            
            urlSessionTask.resume()
        } else if let imageToShare = imageToShare {
            activityIndicatorView.startAnimating()
            adnApiCommunicator.postText(contentText, linksArray: [], accessToken: accessToken!, image: imageToShare) {
                println("finished")
                self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
            }
            
        }
        
    }

    override func configurationItems() -> [AnyObject]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return NSArray() as! [AnyObject]
    }

//    func postRequestFromPostText(postText: String, linksArray: [[String:String]], accessToken:String) -> NSURLRequest {
//        var urlString = "https://api.app.net/posts?include_post_annotations=1"
//        var url = NSURL(string: urlString)
//        var postRequest = NSMutableURLRequest(URL: url)
//        
//        let authorizationString = "Bearer " + accessToken;
//        postRequest.addValue(authorizationString, forHTTPHeaderField: "Authorization")
//        postRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        postRequest.HTTPMethod = "POST"
//        
//        var postDictionary = Dictionary<String, AnyObject>()
//        postDictionary["text"] = postText
//        
//        postDictionary["entities"] = ["links": linksArray, "parse_links": true]
//        
//        println("postDictionary \(postDictionary)")
//        
//        var error: NSError? = nil
//        let postData = NSJSONSerialization.dataWithJSONObject(postDictionary, options: nil, error: &error)
//        
//        postRequest.HTTPBody = postData
//        
//        return postRequest
//    }
}
