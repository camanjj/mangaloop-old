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

class MangaPageController: UIViewController, UIScrollViewDelegate {
    
    
    let progressView = CircleProgressView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    let mangaImageView = UIImageView()
    let scrollView = UIScrollView()
    
    var imageTask: RetrieveImageTask!
    
    let link: String!
    
    init (imageLink: String) {
        
        link = imageLink
        super.init(nibName: nil, bundle: nil)

        
        mangaImageView.kf_showIndicatorWhenLoading = true
        mangaImageView.kf_setImageWithURL(NSURL(string: imageLink)!, placeholderImage: nil, optionsInfo: [.DownloadPriority(0.4)], progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { [unowned self](image, error, cacheType, imageURL) -> () in
                
                guard let _ = image else {
                    return
                }
                
                // don't know why but this is the only way to get the current image to load in the full frame
                self.updateZoom()
                self.centerImage()
                self.updateZoom()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(progressView)
        view.addSubview(scrollView)
        scrollView.addSubview(mangaImageView)
        
        // set the progress view to the center
        progressView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(view.snp_center)
        }
        
        scrollView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view.snp_edges)
        }
        
        
        mangaImageView.contentMode = .ScaleAspectFit
        
        
        // add the gestures to the scrollview
        addGestures()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let _ = mangaImageView.image else {
            return
        }
        
        self.scrollView.frame = self.view.frame
        updateZoom()
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

    
    func makePriority() {
        imageTask.downloadTask?.priority = 1.0
    }
    
    func regularPriority() {
        imageTask.downloadTask?.priority = 0.5
    }
    
    func cancelDownload() {
        imageTask.cancel()
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
        
        mangaImageView.frame = scrollView.frame
        
        let zoomScale = min(view.bounds.size.width / mangaImageView.image!.size.width, view.bounds.size.height / mangaImageView.image!.size.height);
        
        if (zoomScale > 1) {
            self.scrollView.minimumZoomScale = 1;
        }
        
        self.scrollView.minimumZoomScale = zoomScale;
        self.scrollView.zoomScale = zoomScale;
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
        
    }
    
    func doubleTap(gestureRecongizer: UIGestureRecognizer) {
        let pointInView = gestureRecongizer.locationInView(mangaImageView)
        
        // 2
        var newZoomScale = scrollView.zoomScale * 1.5
        newZoomScale = min(newZoomScale, scrollView.maximumZoomScale)
        
        // 3
        let scrollViewSize = scrollView.bounds.size
        let w = scrollViewSize.width / newZoomScale
        let h = scrollViewSize.height / newZoomScale
        let x = pointInView.x - (w / 2.0)
        let y = pointInView.y - (h / 2.0)
        
        let rectToZoomTo = CGRectMake(x, y, w, h);
        
        // 4
        scrollView.zoomToRect(rectToZoomTo, animated: true)
    }
    
    func twoFingerTap(gestureRecongizer: UIGestureRecognizer) {
        
    }
    
    
    
}
