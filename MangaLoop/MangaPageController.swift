//
//  MangaPageController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/27/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import CircleProgressView
import SnapKit
import Kingfisher
import Alamofire
import AVFoundation


protocol MangaPageImageViewDelegate {
    func imageDownloaded(scaledSize: CGSize)
}

class MangaPageImageView: UIImageView {
    
    var link: String
    let progressView = CircleProgressView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    var imageTask: RetrieveImageTask?
    
    var delegate: MangaPageImageViewDelegate?
    
    init(link: String) {
        self.link = link
        super.init(frame: UIScreen.mainScreen().bounds)
        
        progressView.centerFillColor = UIColor.whiteColor()
        progressView.trackBackgroundColor = UIColor.clearColor()
        progressView.trackFillColor = UIColor.redColor()
        progressView.trackWidth = 5
        progressView.backgroundColor = UIColor.clearColor()
        
        
        addSubview(progressView)
        
        progressView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
            make.width.height.equalTo(50)
        }
    }
    
    func downloadMangaPage() {
        contentMode = .ScaleAspectFit
        layer.allowsEdgeAntialiasing = true
//        translatesAutoresizingMaskIntoConstraints = false
        
        let cache = ImageCache(name: "manga-pages")
        imageTask = self.kf_setImageWithURL(NSURL(string: link)!, placeholderImage: UIImage(), optionsInfo: [.DownloadPriority(0.4), .TargetCache(cache)], progressBlock: { [weak self] (receivedSize, totalSize) -> () in
            
            self?.progressView.progress = Double(receivedSize)/Double(totalSize)
            
            }) { [weak self](image, error, cacheType, imageURL) -> () in
                
                
                // check if self is nil
                guard let wself = self else {
                    return
                }
                
                // change the suffix for the image
                if let error = error {
                    
                    // the request was cancelled, don't do anything else
                    if error.code == NSURLErrorCancelled {
                        return
                    }
                    
                    let link = wself.link as NSString
                    let suffix = link.pathExtension
                    let newSuffix = suffix == "jpg" ? "png" : "jpg"
                    let newLink = "\(link.stringByDeletingPathExtension).\(newSuffix)"
                    wself.imageTask = wself.kf_setImageWithURL(NSURL(string: newLink)!, placeholderImage: nil, optionsInfo: [.DownloadPriority(0.4), .TargetCache(cache)], progressBlock: { (receivedSize, totalSize) -> () in
                        wself.progressView.progress = Double(receivedSize)/Double(totalSize)
                        }, completionHandler: { (image, error, cacheType, imageURL) -> () in
                            if let _ = error {
                                
                                return
                            }
                            
                            wself.progressView.hidden = true
                            wself.handleImage()
                            
                    })
                    return
                }
                
                wself.progressView.hidden = true
                wself.handleImage()
                
        }

    }
    
    func handleImage() {
        
        if image == nil {
            return
        }
        
        let scaledSize = aspectFitSize(image!.size, boundingSize: CGSize(width: UIScreen.mainScreen().bounds.width, height: image!.size.height))
        print(scaledSize)
        snp_remakeConstraints { (make) -> Void in
            make.size.equalTo(scaledSize)
        }
        
        if let delegate = delegate {
            delegate.imageDownloaded(scaledSize)
        }
    }
    
    func aspectFitSize(aspectRatio: CGSize, var boundingSize: CGSize) -> CGSize {
        let mW = boundingSize.width / aspectRatio.width
        let mH = boundingSize.height / aspectRatio.height
        if mH < mW {
            boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
        }
        else if mW < mH {
            boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
        }
        return boundingSize;
    }
    
//    func setFrame() {
//        let scaledSize = aspectFitSize(image!.size, boundingSize: CGSize(width: UIScreen.mainScreen().bounds.width, height: image!.size.height))
//        
//        self.frame = CGRect(origin: CGPoint.zero, size: scaledSize)
//    }
    
    func getSize() -> CGSize {
        let scaledSize = aspectFitSize(image!.size, boundingSize: CGSize(width: UIScreen.mainScreen().bounds.width, height: image!.size.height))
        return scaledSize
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class MangaPageController: UIViewController, UIScrollViewDelegate {
    
    let zoomStep: CGFloat = 2.5
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var mangaImageView: MangaPageImageView? = nil
    var image: UIImage?
    
    var imageTask: RetrieveImageTask?
    
    var didChangeSuffix = false
    
    init() {
        super.init(nibName: String(MangaPageController.self), bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let mangaImageView = mangaImageView {
            scrollView.addSubview(mangaImageView)
            scrollView.contentSize = mangaImageView.getSize()
            self.updateZoom()
//            self.centerImage()
//            self.updateZoom()
        }
        // add the gestures to the scrollview
        addGestures()
        
    }
    
    
    func addMangaPage(page: MangaPageImageView) {
//        page.transform = CGAffineTransformIdentity
        mangaImageView = page
        mangaImageView!.delegate = self
        if let scrollView = scrollView {
            scrollView.addSubview(mangaImageView!)
            scrollView.contentSize = mangaImageView!.getSize()
            self.updateZoom()

        }
        
    }
    
    func addGestures() {
        
        let singleTap = UITapGestureRecognizer(target: self, action: Selector("singleTap:"))
        let doubleTap = UITapGestureRecognizer(target: self, action: Selector("doubleTap:"))
        let twoFingerTap = UITapGestureRecognizer(target: self, action: Selector("twoFingerTap:"))
        
        doubleTap.numberOfTapsRequired = 2
        twoFingerTap.numberOfTouchesRequired = 2
        
        singleTap.requireGestureRecognizerToFail(doubleTap)
        
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addGestureRecognizer(doubleTap)
        scrollView.addGestureRecognizer(twoFingerTap)
        
        scrollView.delegate = self
        
        scrollView.canCancelContentTouches = true
        scrollView.clipsToBounds = true
        
        
    }
    
    func toggleNavBar() {
        if let navigationController = navigationController where navigationController.navigationBarHidden {
            
            navigationController.setNavigationBarHidden(false, animated: true)
            navigationController.setToolbarHidden(false, animated: true)
            
            setNeedsStatusBarAppearanceUpdate()
            
        } else if let navigationController = navigationController where !navigationController.navigationBarHidden {
            
            navigationController.setNavigationBarHidden(true, animated: true)
            navigationController.setToolbarHidden(true, animated: true)
            
            setNeedsStatusBarAppearanceUpdate()
            
        }
    }
    
    
    func makePriority() {
        imageTask?.downloadTask?.priority = 1.0
    }
    
    func regularPriority() {
        imageTask?.downloadTask?.priority = 0.5
    }
    
    func cancelDownload() {
        imageTask?.cancel()
    }
    
    
    //MARK: UIScrollView delegate methods
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return mangaImageView
    }
    
    //MARK: Zooming and Panning Methods
    func zoom(rectForScale scale: CGFloat, center: CGPoint) -> CGRect {
        
        guard let mangaImageView = mangaImageView else {
            return CGRect.zero
        }
        
        var zoomRect = CGRect()
        
        zoomRect.size.height = mangaImageView.frame.height / scale;
        zoomRect.size.width  = mangaImageView.frame.width  / scale;
        
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
        
        return zoomRect;
        
    }
    
    func updateZoom() {
        
        guard let mangaImageView = mangaImageView else {
            return
        }
        

        // center the image if it is not longer than the page
        if mangaImageView.getSize().height <= UIScreen.mainScreen().bounds.height {
        
            mangaImageView.snp_updateConstraints { (make) -> Void in
                make.center.equalTo(scrollView)
            }
        }
        
        
        
        let zoomScale = view.bounds.size.width / mangaImageView.image!.size.width//min(view.bounds.size.width / mangaImageView.image!.size.width, view.bounds.size.height / mangaImageView.image!.size.height);
        
        if (zoomScale > 1) {
            self.scrollView.minimumZoomScale = 1;
        }
        
        scrollView.minimumZoomScale = 1;
        scrollView.maximumZoomScale = 3
        scrollView.zoomScale = 1;
    }
    
    func aspectFitSize(aspectRatio: CGSize, var boundingSize: CGSize) -> CGSize {
        let mW = boundingSize.width / aspectRatio.width
        let mH = boundingSize.height / aspectRatio.height
        if mH < mW {
            boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
        }
        else if mW < mH {
            boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
        }
        return boundingSize;
    }
    
    func centerImage() {
        
        guard let mangaImageView = mangaImageView else {
            return
        }
        
        let boundsSize = self.scrollView.bounds.size
        var contentsFrame = mangaImageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
//        mangaImageView.frame.origin = CGPoint(x: 100, y: 100)
//        mangaImageView.frame = contentsFrame
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerImage()
    }
    
    func singleTap(gestureRecongizer: UIGestureRecognizer) {
        toggleNavBar()
    }
    
    func doubleTap(gestureRecongizer: UIGestureRecognizer) {
        
        let pointInView = gestureRecongizer.locationInView(mangaImageView)
        
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let newScale = scrollView.zoomScale * zoomStep
            let zoomRect = zoom(rectForScale: newScale, center: pointInView)
            scrollView.zoomToRect(zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    func twoFingerTap(gestureRecongizer: UIGestureRecognizer) {
        
    }
    
}


extension MangaPageController: MangaPageImageViewDelegate {
    
    
    func imageDownloaded(scaledSize: CGSize) {
        if let scrollView = scrollView {
            scrollView.contentSize = scaledSize
            updateZoom()

        }
    }
}