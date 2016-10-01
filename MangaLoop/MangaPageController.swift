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
  
  var link: NSURL? {
    didSet {
      // when setting a new link cancel the current image task
      imageTask?.cancel()
      self.snp_removeConstraints()
      downloadMangaPage()
    }
  }
  let progressView = CircleProgressView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
  var imageTask: RetrieveImageTask?
  
  var reloadButton: UIButton?
  
  var delegate: MangaPageImageViewDelegate?
  
  init() {
    super.init(frame: UIScreen.mainScreen().bounds)
    commonInit()
  }
  
  func commonInit() {
    
    // setup the progress view
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
    
    // only procced if we have a url
    guard let link = link else { return }
    
    if let reloadButton = reloadButton {
      reloadButton.removeFromSuperview()
    }
    
    contentMode = .ScaleAspectFit
    layer.allowsEdgeAntialiasing = true
    //        translatesAutoresizingMaskIntoConstraints = false
    
    let cache = ImageCache(name: "manga-pages")
    let options: [KingfisherOptionsInfoItem] = [.DownloadPriority(0.4), .TargetCache(cache)]
    let progressBlock: DownloadProgressBlock = {
      [weak self] (receivedSize, totalSize) in
      self?.progressView.progress = (Double(receivedSize)/Double(totalSize))
    }
    
    
    imageTask = self.kf_setImageWithURL(link, placeholderImage: nil, optionsInfo: options, progressBlock: progressBlock) { [weak self](image, error, cacheType, imageURL) -> () in
      
      
      // check if self is nil
      guard let wself = self else {
        return
      }
      
      // change the suffix for the image
      if let error = error {
        
        print("Link: \(wself.link) error: " + error.localizedDescription)
        
        // the request was cancelled, don't do anything else
        if error.code == NSURLErrorCancelled {
          return
        }
        
        let link = link.absoluteString! as NSString
        let suffix = link.pathExtension
        let newSuffix = suffix == "jpg" ? "png" : "jpg"
        let newLink = "\(link.stringByDeletingPathExtension).\(newSuffix)"
        wself.imageTask = wself.kf_setImageWithURL(NSURL(string: newLink)!, placeholderImage: nil, optionsInfo: options, progressBlock: progressBlock, completionHandler: { (image, error, cacheType, imageURL) -> () in
            if let error = error {
              wself.addReloadButton()
              print("Link: \(wself.link) error: " + error.localizedDescription)
              return
            }
            
            wself.progressView.hidden = true
            wself.handleImage()
            
        })
        return
      }
      
      print("Got image: " + link.absoluteString!)
      
      wself.progressView.hidden = true
      wself.handleImage()
      
    }
    
  }
  
  func handleImage() {
    
    if image == nil {
      return
    }
    
    let scaledSize = aspectFitSize(image!.size, boundingSize: CGSize(width: UIScreen.mainScreen().bounds.width, height: image!.size.height))
    
    snp_makeConstraints { (make) -> Void in
      make.size.equalTo(scaledSize)
    }
    
    // frame = CGRect(origin: CGPointZero, size: scaledSize)
    
    if let delegate = delegate {
      delegate.imageDownloaded(scaledSize)
    }
  }
  
  func addReloadButton() {
    
    
    if let reloadButton = reloadButton {
      reloadButton.removeFromSuperview()
    }
    
    reloadButton = UIButton()
    reloadButton?.setTitle("Reload", forState: .Normal)
    reloadButton?.setTitleColor(UIColor.blackColor(), forState: .Normal)
    reloadButton?.sizeToFit()
    
    addSubview(reloadButton!)
    reloadButton!.center = center
    
    reloadButton?.addTarget(self, action: #selector(downloadMangaPage), forControlEvents: .TouchUpInside)
    
    
  }
  
  func aspectFitSize(aspectRatio: CGSize, boundingSize bs: CGSize) -> CGSize {
    var boundingSize = bs;
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
    
    guard let image = image else { return UIScreen.mainScreen().bounds.size}
    
    let scaledSize = aspectFitSize(image.size, boundingSize: CGSize(width: UIScreen.mainScreen().bounds.width, height: image.size.height))
    return scaledSize
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}


class MangaPageController: UIViewController, UIScrollViewDelegate {
  
  let zoomStep: CGFloat = 2.5
  
  @IBOutlet weak var scrollView: UIScrollView!
  
  var mangaImageView = MangaPageImageView()
  var image: UIImage?
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init() {
    super.init(nibName: String(MangaPageController.self), bundle: nil)
    
    mangaImageView.delegate = self
    mangaImageView.downloadMangaPage()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    scrollView.addSubview(mangaImageView)
    scrollView.contentSize = mangaImageView.getSize()
    updateZoom()
    
    addGestures()
    
  }
  
  func addGestures() {
    
    let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
    let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(twoFingerTap(_:)))
    
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
    mangaImageView.imageTask?.downloadTask?.priority = 1.0
  }
  
  func regularPriority() {
    mangaImageView.imageTask?.downloadTask?.priority = 0.5
  }
  
  func cancelDownload() {
    mangaImageView.imageTask?.cancel()
  }
  
  
  //MARK: UIScrollView delegate methods
  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return mangaImageView
  }
  
  //MARK: Zooming and Panning Methods
  func zoom(rectForScale scale: CGFloat, center: CGPoint) -> CGRect {
    
    //        guard let mangaImageView = mangaImageView else {
    //            return CGRect.zero
    //        }
    
    var zoomRect = CGRect()
    
    zoomRect.size.height = mangaImageView.frame.height / scale;
    zoomRect.size.width  = mangaImageView.frame.width  / scale;
    
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
    
  }
  
  func updateZoom() {
    
    // make sure that the imageview is not nil and contains a valid image
    guard let image = mangaImageView.image else {
      return
    }
    
    
    // center the image if it is not longer than the page
    if mangaImageView.getSize().height <= UIScreen.mainScreen().bounds.height {
      
      mangaImageView.snp_updateConstraints { (make) -> Void in
        make.center.equalTo(scrollView)
      }
    }
    
    
    
    let zoomScale = view.bounds.size.width / image.size.width//min(view.bounds.size.width / mangaImageView.image!.size.width, view.bounds.size.height / mangaImageView.image!.size.height);
    
    if (zoomScale > 1) {
      self.scrollView.minimumZoomScale = 1;
    }
    
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 3
    scrollView.zoomScale = 1;
  }
  
  
  func centerImage() {
    
    //        guard let mangaImageView = mangaImageView else {
    //            return
    //        }
    
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
    
    if let reloadButton = mangaImageView.reloadButton where CGRectContainsPoint(reloadButton.frame, gestureRecongizer.locationInView(self.mangaImageView)) {
      mangaImageView.downloadMangaPage()
      return
    }
    
    
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
