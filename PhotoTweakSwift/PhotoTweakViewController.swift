//
//  PhotoTweakViewController.swift
//  PhotoTweakSwift
//
//  Created by Wix Litariz on 2017/4/27.
//  Copyright © 2017年 Wix ART Work. All rights reserved.
//

import UIKit

protocol PhotoTweakViewControllerDelegate: class {
    func photoTweakDidCancel(_ photoTweak: PhotoTweakViewController)
    func photoTweak(_ photoTweak: PhotoTweakViewController, tweakedImage: CIImage, withParameter parameter: [String: AnyObject])
}

struct PTParameterKey{
    static let rotateAngle = "angle"
    static let cropRect = "rect"
}

class PhotoTweakViewController: UIViewController {
    
    private(set) var image: CIImage
    
    private(set) var header: UIView!
    private(set) var footer: UIView!
    private(set) var ratioMenu: UIScrollView!
    
    var restoreParameter: [String: AnyObject]?
    
    weak var delegate: PhotoTweakViewControllerDelegate?
    
    init(image: CIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = PhotoTweakView(frame: UIScreen.mainScreen().bounds, image: UIImage(CIImage: image))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
        
        drawHeader()
        drawFooter()
        drawRatioMenu()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animateWithDuration(0.25, animations: restoreStatus)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func drawHeader() {
        header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 48))
        header.backgroundColor = UIColor(white: 17.0/255.0, alpha: 1.0)
        
        let cancelBtn = UIButton(frame: CGRect(x: 5, y: 0, width: 48, height: 48))
        cancelBtn.setImage(UIImage(named: "btnCancelWhiteNormal"), forState: .Normal)
        cancelBtn.setImage(UIImage(named: "btnCancelWhiteHighlighted"), forState: .Highlighted)
        cancelBtn.addTarget(self, action: #selector(self.onCancel), forControlEvents: .TouchUpInside)
        header.addSubview(cancelBtn)
        
        let cropBtn = UIButton(frame: CGRect(x: view.bounds.width - 53, y: 0, width: 48, height: 48))
        cropBtn.setImage(UIImage(named: "btnCutNormal"), forState: .Normal)
        cropBtn.setImage(UIImage(named: "btnCutHighlighted"), forState: .Highlighted)
        cropBtn.addTarget(self, action: #selector(self.onCompleted), forControlEvents: .TouchUpInside)
        header.addSubview(cropBtn)
        
        let title = UILabel()
        title.font = UIFont(name: "PingFangTC-Regular", size: 17)
        title.textColor = UIColor.whiteColor()
        title.text = "裁切照片"
        title.sizeToFit()
        header.addSubview(title)
        title.center = CGPoint(x: header.bounds.midX, y: header.bounds.midY)
        
        view.addSubview(header)
    }
    
    private func drawFooter() {
        footer = UIView(frame: CGRect(x: 0, y: view.bounds.height - 48, width: view.bounds.width, height: 48))
        footer.backgroundColor = UIColor(white: 17.0/255.0, alpha: 1.0)
        
        let ratioBtn = UIButton(frame: CGRect(x: 5, y: 0, width: 48, height: 48))
        ratioBtn.setImage(UIImage(named: "btnPhotoSize43White"), forState: .Normal)
        ratioBtn.setImage(UIImage(named: "btnPhotoSize43Highlighted"), forState: .Highlighted)
        ratioBtn.addTarget(self, action: #selector(self.onRatio), forControlEvents: .TouchUpInside)
        footer.addSubview(ratioBtn)
        
        let resetBtn = UIButton(frame: CGRect(x: view.bounds.midX - 24, y: 0, width: 48, height: 48))
        resetBtn.setImage(UIImage(named: "btnResetWhiteNormal"), forState: .Normal)
        resetBtn.setImage(UIImage(named: "btnResetWhiteHighlighted"), forState: .Highlighted)
        resetBtn.addTarget(self, action: #selector(self.onReset), forControlEvents: .TouchUpInside)
        footer.addSubview(resetBtn)
        
        let rotateBtn = UIButton(frame: CGRect(x: view.bounds.width - 53, y: 0, width: 48, height: 48))
        rotateBtn.setImage(UIImage(named: "iconRotateNormal"), forState: .Normal)
        rotateBtn.setImage(UIImage(named: "iconRotateHighlighted"), forState: .Highlighted)
        rotateBtn.addTarget(self, action: #selector(self.onRotate), forControlEvents: .TouchUpInside)
        footer.addSubview(rotateBtn)
        
        view.addSubview(footer)
    }
    
    private func drawRatioMenu() {
        let menu = UIScrollView(frame: CGRect(x: 0, y: view.bounds.height - 96, width: view.bounds.width, height: 48))
        menu.backgroundColor = UIColor(white: 17.0 / 255.0, alpha: 1)
        menu.alpha = 0
        
        let keys = ["11","32","53","43","54","75","169"]
        
        let origin = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        origin.setTitle("origin", forState: .Normal)
        origin.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        origin.titleLabel?.font = UIFont.systemFontOfSize(10)
        origin.tag = 0
        origin.addTarget(self, action: #selector(self.onRatioButton(_:)), forControlEvents: .TouchUpInside)
        menu.addSubview(origin)
        
        var x: CGFloat = 48
        for i in 1...keys.count {
            let key = keys[i - 1]
            let btn = UIButton(frame: CGRect(x: x, y: 0, width: 48, height: 48))
            btn.setImage(UIImage(named: "btnPhotoSize\(key)White"), forState: .Normal)
            btn.setImage(UIImage(named: "btnPhotoSize\(key)WhiteHighlighted"), forState: .Highlighted)
            btn.tag = i
            btn.addTarget(self, action: #selector(self.onRatioButton(_:)), forControlEvents: .TouchUpInside)
            menu.addSubview(btn)
            x += 48
        }
        
        menu.contentSize = CGSize(width: x, height: 0)
        view.addSubview(menu)
        
        ratioMenu = menu
    }
    
    func restoreStatus() {
        guard let angle = restoreParameter?[PTParameterKey.rotateAngle] as? CGFloat,
              let rect = (restoreParameter?[PTParameterKey.cropRect] as? NSValue)?.CGRectValue() else {
            return
        }
        
        let ptView = view as! PhotoTweakView
        ptView.setRotateAngle(to: angle)
        
//        ptView.scrollView.zoomScale = 1.0
        let scale = ptView.scrollView.zoomScale
        let imageOrigin = ptView.convertRect(ptView.imageView.frame, fromView: ptView.scrollView).origin
        let cropFrame = CGRect(x: rect.minX * scale + imageOrigin.x,
                               y: rect.minY * scale + imageOrigin.y,
                               width: rect.width * scale,
                               height: rect.height * scale)
        ptView.cropView.frame = cropFrame
        ptView.resizeScrollView()
        ptView.relocateCropView(false)
        
//        if #available(iOS 10.0, *) {
//            NSTimer.scheduledTimerWithTimeInterval(1.5, repeats: false) { (timer) in
//                ptView.relocateCropView()
//            }
//        } else {
//            // Fallback on earlier versions
//        }
    }
    
    func onRotate() {
        (view as? PhotoTweakView)?.rotate90Degree()
    }
    
    func onReset() {
        (view as? PhotoTweakView)?.reset()
    }
    
    func onRatio() {
        UIView.animateWithDuration(0.25) { [weak ratioMenu] in
            ratioMenu?.alpha = ratioMenu?.alpha > 0.5 ? 0 : 1
        }
    }
    
    func onCancel() {
        delegate?.photoTweakDidCancel(self)
    }
    
    func onCompleted() {
        let ptView = view as! PhotoTweakView
        var param = [String:AnyObject]()
        // 旋轉角度
        param[PTParameterKey.rotateAngle] = ptView.rotatedAngle
        
        // 裁切範圍
        let imageFrame = ptView.convertRect(ptView.imageView.frame, fromView: ptView.scrollView)
        let cropFrame = ptView.cropView.frame
        let scale = ptView.scrollView.zoomScale
        let targetFrame = CGRect(x: round((cropFrame.minX - imageFrame.minX) / scale),
                                 y: round((cropFrame.minY - imageFrame.minY) / scale),
                                 width: round(cropFrame.width / scale),
                                 height: round(cropFrame.height / scale))
        
        param[PTParameterKey.cropRect] = NSValue(CGRect: targetFrame)
        print(param)
        let cropedImage = PhotoTweakViewController.crop(image: image, byParameter: param)
        delegate?.photoTweak(self, tweakedImage: cropedImage, withParameter: param)
    }
    
    func onRatioButton(sender: UIButton) {
        let ratios = [CGVector(dx: image.extent.size.width, dy: image.extent.size.height),
                      CGVector(dx: 1, dy: 1),
                      CGVector(dx: 3, dy: 2),
                      CGVector(dx: 5, dy: 3),
                      CGVector(dx: 4, dy: 3),
                      CGVector(dx: 5, dy: 4),
                      CGVector(dx: 7, dy: 5),
                      CGVector(dx: 16, dy: 9)]
        
        let ratio = image.extent.size.height > image.extent.size.width ?
                    CGVector(dx: ratios[sender.tag].dy, dy: ratios[sender.tag].dx) :
                    ratios[sender.tag]
        (view as? PhotoTweakView)?.setCropRatio(to: ratio)
    }
    
    static func crop(image image: CIImage, byParameter param: [String:AnyObject]) -> CIImage {
        var image = image
        if let rotateAngle = param[PTParameterKey.rotateAngle] as? CGFloat {
            image = image.imageByApplyingTransform(CGAffineTransformMakeRotation(-rotateAngle))
            image = image.imageByApplyingTransform(CGAffineTransformMakeTranslation(-image.extent.minX, -image.extent.minY))
        }
        
        guard var rect = (param[PTParameterKey.cropRect] as? NSValue)?.CGRectValue() else {
            return image
        }
        
        // 反轉Y軸
        rect.origin.y = image.extent.height - rect.maxY
        
        let output = image.imageByCroppingToRect(rect)
        
        return output
    }
}

