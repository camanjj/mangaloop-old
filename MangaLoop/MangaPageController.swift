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
  func imageDownloaded(_ scaledSize: CGSize)
}

class MangaPageImageView: UIImageView {
  
  var link: URL? {
    didSet {
      // when setting a new link cancel the current image task
      imageTask?.cancel()
      self.snp.removeConstraints()
      downloadMangaPage()
    }
  }
  let progressView = CircleProgressView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
  var imageTask: RetrieveImageTask?
  
  var reloadButton: UIButton?
  
  var delegate: MangaPageImageViewDelegate?
  
  init() {
    super.init(frame: UIScreen.main.bounds)
    commonInit()
  }
  
  func commonInit() {
    
    // setup the progress view
    progressView.centerFillColor = UIColor.white
    progressView.trackBackgroundColor = UIColor.clear
    progressView.trackFillColor = UIColor.red
    progressView.trackWidth = 5
    progressView.backgroundColor = UIColor.clear
    
    addSubview(progressView)
    
    progressView.snp.makeConstraints { (make) -> Void in
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
    
    contentMode = .scaleAspectFit
    layer.allowsEdgeAntialiasing = true
    //        translatesAutoresizingMaskIntoConstraints = false
    
    let cache = ImageCache(name: "manga-pages")
    let options: [KingfisherOptionsInfoItem] = [.downloadPriority(0.4), .targetCache(cache)]
    let progressBlock: DownloadProgressBlock = {
      [weak self] (receivedSize, totalSize) in
      self?.progressView.progress = (Double(receivedSize)/Double(totalSize))
    }
    
    
    imageTask = self.kf.setImage(with: ImageResource(downloadURL: link), placeholder: nil, options: options, progressBlock: progressBlock) { [weak self](image, error, cacheType, imageURL) -> () in
      
      
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
        
        let link = link.absoluteString as NSString
        let suffix = link.pathExtension
        let newSuffix = suffix == "jpg" ? "png" : "jpg"
        let newLink = "\(link.deletingPathExtension).\(newSuffix)"
        wself.imageTask = wself.kf.setImage(with: ImageResource(downloadURL: URL(string: newLink)!), placeholder: nil, options: options, progressBlock: progressBlock) { [weak self] (image, error, cacheType, imageURL) -> () in
            if let error = error {
              wself.addReloadButton()
              print("Link: \(wself.link) error: " + error.localizedDescription)
              return
            }
            
            wself.progressView.isHidden = true
            wself.handleImage()
            
        }
        return
      }
      
      print("Got image: " + link.absoluteString)
      
      wself.progressView.isHidden = true
      wself.handleImage()
      
    }
    
  }
  
  func handleImage() {
    
    if image == nil {
      return
    }
    
    let scaledSize = aspectFitSize(image!.size, boundingSize: CGSize(width: UIScreen.main.bounds.width, height: image!.size.height))
    
    snp.makeConstraints { (make) -> Void in
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
    reloadButton?.setTitle("Reload", for: UIControlState())
    reloadButton?.setTitleColor(UIColor.black, for: UIControlState())
    reloadButton?.sizeToFit()
    
    addSubview(reloadButton!)
    reloadButton!.center = center
    
    reloadButton?.addTarget(self, action: #selector(downloadMangaPage), for: .touchUpInside)
    
    
  }
  
  func aspectFitSize(_ aspectRatio: CGSize, boundingSize bs: CGSize) -> CGSize {
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
    
    guard let image = image else { return UIScreen.main.bounds.size}
    
    let scaledSize = aspectFitSize(image.size, boundingSize: CGSize(width: UIScreen.main.bounds.width, height: image.size.height))
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
    super.init(nibName: String(describing: MangaPageController.self), bundle: nil)
    
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
    
    singleTap.require(toFail: doubleTap)
    
    scrollView.addGestureRecognizer(singleTap)
    scrollView.addGestureRecognizer(doubleTap)
    scrollView.addGestureRecognizer(twoFingerTap)
    
    scrollView.delegate = self
    
    scrollView.canCancelContentTouches = true
    scrollView.clipsToBounds = true
    
    
  }
  
  func toggleNavBar() {
    if let navigationController = navigationController, navigationController.isNavigationBarHidden {
      
      navigationController.setNavigationBarHidden(false, animated: true)
      navigationController.setToolbarHidden(false, animated: true)
      
      setNeedsStatusBarAppearanceUpdate()
      
    } else if let navigationController = navigationController, !navigationController.isNavigationBarHidden {
      
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
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
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
    if mangaImageView.getSize().height <= UIScreen.main.bounds.height {
      
      mangaImageView.snp.updateConstraints { (make) -> Void in
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
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    centerImage()
  }
  
  func singleTap(_ gestureRecongizer: UIGestureRecognizer) {
    
    if let reloadButton = mangaImageView.reloadButton, reloadButton.frame.contains(gestureRecongizer.location(in: self.mangaImageView)) {
      mangaImageView.downloadMangaPage()
      return
    }
    
    
    toggleNavBar()
  }
  
  func doubleTap(_ gestureRecongizer: UIGestureRecognizer) {
    
    let pointInView = gestureRecongizer.location(in: mangaImageView)
    
    if scrollView.zoomScale == scrollView.minimumZoomScale {
      let newScale = scrollView.zoomScale * zoomStep
      let zoomRect = zoom(rectForScale: newScale, center: pointInView)
      scrollView.zoom(to: zoomRect, animated: true)
    } else {
      scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
    }
  }
  
  func twoFingerTap(_ gestureRecongizer: UIGestureRecognizer) {
    
  }
  
}


extension MangaPageController: MangaPageImageViewDelegate {
  
  
  func imageDownloaded(_ scaledSize: CGSize) {
    if let scrollView = scrollView {
      scrollView.contentSize = scaledSize
      updateZoom()
      
    }
  }
}
