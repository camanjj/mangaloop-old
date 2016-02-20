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

class MangaPageController: UIViewController, UIScrollViewDelegate {
    
    let zoomStep: CGFloat = 2.5

    @IBOutlet weak var scrollView: UIScrollView!
    
    let progressView = CircleProgressView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    let mangaImageView = UIImageView()
    var image: UIImage?
    
    var imageTask: RetrieveImageTask?
    
    let link: String!
    
    var didChangeSuffix = false
    
    init (imageLink: String) {
        
        link = imageLink
        super.init(nibName:"MangaPageController", bundle: nil)

        mangaImageView.contentMode = .ScaleAspectFit
        mangaImageView.layer.allowsEdgeAntialiasing = true
//        mangaImageView.clipsToBounds = false
        

        
        let cache = ImageCache(name: "manga-pages")
        
//        mangaImageView.kf_showIndicatorWhenLoading = true
//
        mangaImageView.kf_setImageWithURL(NSURL(string: imageLink)!, placeholderImage: nil, optionsInfo: [.DownloadPriority(0.4), .TargetCache(cache)], progressBlock: { (receivedSize, totalSize) -> () in
            
            self.progressView.progress = Double(receivedSize)/Double(totalSize)
            
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
                    wself.mangaImageView.kf_setImageWithURL(NSURL(string: newLink)!, placeholderImage: nil, optionsInfo: [.DownloadPriority(0.4), .TargetCache(cache)], progressBlock: { (receivedSize, totalSize) -> () in
                        wself.progressView.progress = Double(receivedSize)/Double(totalSize)
                        }, completionHandler: { (image, error, cacheType, imageURL) -> () in
                            if let _ = error {
                                
                                return
                            }
                            
                            wself.progressView.hidden = true
                            
                            wself.updateZoom()
                            wself.centerImage()
                            wself.updateZoom()
                            
                    })
                    return
                }
                
                self?.progressView.hidden = true
                
                // don't know why but this is the only way to get the current image to load in the full frame
                
                if let _ = self?.view {


//                    self.mangaImageView.image = nil
//                    self.mangaImageView.image = image!
                    self?.updateZoom()
                    self?.centerImage()
                    self?.updateZoom()
                }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        view.addSubview(progressView)
        scrollView.addSubview(mangaImageView)
        
        // set the progress view to the center
        progressView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(view.snp_center)
            make.width.height.equalTo(40)
        }
//        if let image = self.image where mangaImageView.image == nil {
//            mangaImageView.image = image
//            mangaImageView.setNeedsDisplay()
//        }
        
        // add the gestures to the scrollview
        addGestures()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let _ = mangaImageView.image else {
            return
        }
        

        
//        self.view.setNeedsLayout();
//        self.view.layoutIfNeeded();
//        scrollView.frame = view.frame
//        print("View frame on viewWillAppear: \(NSStringFromCGSize(view.frame.size))")
//        print("ScrollView frame on viewWillAppear: \(NSStringFromCGSize(scrollView.frame.size))")
//        
////        updateZoom()
//        self.updateZoom()
//        self.centerImage()
//        self.updateZoom()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.frame
        self.updateZoom()
        self.centerImage()
        self.updateZoom()

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
        
        var zoomRect = CGRect()
        
        zoomRect.size.height = mangaImageView.frame.height / scale;
        zoomRect.size.width  = mangaImageView.frame.width  / scale;

        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
        
        return zoomRect;
        
    }
    
    func updateZoom() {
        
        guard let _ = mangaImageView.image else {
            return
        }
        
        if (scrollView != nil) {
            mangaImageView.frame = scrollView.frame
        }
        
        
        let widthImageFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: mangaImageView.image!.size.height)

        let scaledSize = aspectFitSize(mangaImageView.image!.size, boundingSize: widthImageFrame.size)
        
        if scaledSize.height > UIScreen.mainScreen().bounds.height - 20 {
            mangaImageView.frame = CGRect(x: 0, y: 0, width: scrollView.frame.width, height: scaledSize.height)
            scrollView.contentSize = mangaImageView.frame.size
        }

        
        
        
        let zoomScale = view.bounds.size.width / mangaImageView.image!.size.width//min(view.bounds.size.width / mangaImageView.image!.size.width, view.bounds.size.height / mangaImageView.image!.size.height);
        
        if (zoomScale > 1) {
            self.scrollView.minimumZoomScale = 1;
        }
        
        self.scrollView.minimumZoomScale = zoomScale;
        self.scrollView.zoomScale = zoomScale;
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
        let boundsSize = self.scrollView.bounds.size
        var contentsFrame = self.mangaImageView.frame
        
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
        
        self.mangaImageView.frame = contentsFrame
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
