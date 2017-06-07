//
//  PhotoTweakView.swift
//  PhotoTweakSwift
//
//  Created by Wix Litariz on 2017/6/7.
//  Copyright © 2017年 Wix ART Work. All rights reserved.
//

import UIKit

struct PTCropViewConstants {
    static let cropLineCount = 2
    static let gridLineCount = 0
}

private enum PTCropCornerPosition {
    case UpperLeft
    case UpperRight
    case LowerRight
    case LowerLeft
}

class PTCropCornerView: UIView {
    
    private let position: PTCropCornerPosition
    var horizontal = UIView(frame: CGRect.zero)
    var vertical = UIView(frame: CGRect.zero)
    
    var cornerLineColor = UIColor.whiteColor() {
        didSet {
            horizontal.backgroundColor = cornerLineColor
            vertical.backgroundColor = cornerLineColor
        }
    }
    var lineWidth: CGFloat = 5 {
        didSet {
            layoutSubviews()
        }
    }
    
    private init(position: PTCropCornerPosition) {
        self.position = position
        super.init(frame: CGRect.zero)
        
        backgroundColor = UIColor.clearColor()
        
        horizontal.backgroundColor = cornerLineColor
        vertical.backgroundColor = cornerLineColor
        addSubview(horizontal)
        addSubview(vertical)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let horPos: CGPoint
        let verPos: CGPoint
        
        switch position {
        case .UpperLeft:
            horPos = CGPoint(x: 0, y: 0)
            verPos = CGPoint(x: 0, y: 0)
        case .UpperRight:
            horPos = CGPoint(x: 0, y: 0)
            verPos = CGPoint(x: bounds.width - lineWidth, y: 0)
        case .LowerRight:
            horPos = CGPoint(x: 0, y: bounds.height - lineWidth)
            verPos = CGPoint(x: bounds.width - lineWidth, y: 0)
        case .LowerLeft:
            horPos = CGPoint(x: 0, y: bounds.height - lineWidth)
            verPos = CGPoint(x: 0, y: 0)
        }
        
        horizontal.frame = CGRect(origin: horPos, size: CGSize(width: bounds.width, height: lineWidth))
        vertical.frame = CGRect(origin: verPos, size: CGSize(width: lineWidth, height: bounds.height))
    }
}

@objc protocol PTCropViewDelegate: class {
    @objc optional func cropViewChanged(cropView: PTCropView)
    @objc optional func cropViewFinishedChange(cropView: PTCropView)
    func cropView(cropView: PTCropView, canChangeTo frame: CGRect) -> Bool
}

class PTCropView: UIView {
    
    var upperLeft: PTCropCornerView!
    var upperRight: PTCropCornerView!
    var lowerRight: PTCropCornerView!
    var lowerLeft: PTCropCornerView!
    
    var horizontalCropLines = [UIView]()
    var horizontalGridLines = [UIView]()
    var verticalCropLines = [UIView]()
    var verticalGridLines = [UIView]()
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    private var panningPattern: PTCropViewPanningPattern?
    weak var delegate: PTCropViewDelegate?
    
    var minSideLength: CGFloat = 60
    var activityBorderWidth: CGFloat = 30
    
    private var cropLinesDismissed: Bool = true
    private var gridLinesDismissed: Bool = true
    
    var cropLineColor: UIColor? {
        get {
            return layer.borderColor == nil ? nil : UIColor.init(CGColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.CGColor
        }
    }
    var cropLineWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    var gridLineColor: UIColor? = UIColor(red: 0.52, green: 0.48, blue: 0.47, alpha: 0.8) {
        didSet {
            for line in horizontalGridLines {
                line.backgroundColor = gridLineColor
            }
            for line in verticalGridLines {
                line.backgroundColor = gridLineColor
            }
        }
    }
    var cornerLength: CGFloat = 25 {
        didSet {
            updateCornerViewFrame()
        }
    }
    var cornerEdge: CGFloat = 3 {
        didSet {
            updateCornerViewFrame()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clearColor()
        cropLineColor = UIColor.whiteColor()
        cropLineWidth = 1
        
        for _ in 0..<PTCropViewConstants.cropLineCount {
            let line = UIView()
            line.backgroundColor = cropLineColor
            horizontalCropLines.append(line)
            self.addSubview(line)
        }
        
        for _ in 0..<PTCropViewConstants.cropLineCount {
            let line = UIView()
            line.backgroundColor = cropLineColor
            verticalCropLines.append(line)
            self.addSubview(line)
        }
        
        for _ in 0..<PTCropViewConstants.gridLineCount {
            let line = UIView()
            line.backgroundColor = gridLineColor
            horizontalGridLines.append(line)
            self.addSubview(line)
        }
        
        for _ in 0..<PTCropViewConstants.gridLineCount {
            let line = UIView()
            line.backgroundColor = gridLineColor
            verticalGridLines.append(line)
            self.addSubview(line)
        }
        
        upperLeft = PTCropCornerView(position: .UpperLeft)
        upperLeft.autoresizingMask = []
        self.addSubview(upperLeft)
        
        upperRight = PTCropCornerView(position: .UpperRight)
        upperRight.autoresizingMask = .FlexibleLeftMargin
        self.addSubview(upperRight)
        
        lowerRight = PTCropCornerView(position: .LowerRight)
        lowerRight.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin]
        self.addSubview(lowerRight)
        
        lowerLeft = PTCropCornerView(position: .LowerLeft)
        lowerLeft.autoresizingMask = .FlexibleTopMargin
        self.addSubview(lowerLeft)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlerOfRecognizer(_:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.delaysTouchesBegan = false
        panGestureRecognizer.delaysTouchesEnded = false
        panGestureRecognizer.maximumNumberOfTouches = 1
        
        updateCornerViewFrame()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, withEvent: event)
        
        if hit === self {
            if point.x < activityBorderWidth || point.x > bounds.width - activityBorderWidth ||
                point.y < activityBorderWidth || point.y > bounds.height - activityBorderWidth {
                return self
            }
            return nil
        }
        return hit
    }
    
    private func updateCornerViewFrame() {
        let upper = -cornerEdge
        let lower = bounds.height - cornerLength + cornerEdge
        let left = -cornerEdge
        let right = bounds.width - cornerLength + cornerEdge
        
        upperLeft.frame = CGRect(x: left, y: upper, width: cornerLength, height: cornerLength)
        upperRight.frame = CGRect(x: right, y: upper, width: cornerLength, height: cornerLength)
        lowerRight.frame = CGRect(x: right, y: lower, width: cornerLength, height: cornerLength)
        lowerLeft.frame = CGRect(x: left, y: lower, width: cornerLength, height: cornerLength)
    }
    
    @objc private func handlerOfRecognizer(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.locationInView(self)
        switch recognizer.state {
        case .Began:
            if location.x < activityBorderWidth {
                panningPattern = (location.y < activityBorderWidth ? .UpperLeft : (location.y > bounds.height - activityBorderWidth ? .LowerLeft : .Left))
                return
            }
            if location.x > bounds.width - activityBorderWidth {
                panningPattern = (location.y < activityBorderWidth ? .UpperRight : (location.y > bounds.height - activityBorderWidth ? .LowerRight : .Right))
                return
            }
            panningPattern = (location.y < activityBorderWidth ? .Upper : (location.y > bounds.height - activityBorderWidth ? .Lower : .Center))
        case .Changed:
            guard let pattern = panningPattern else { return }
            if pattern == .Center { return }
            
            var frame = self.frame
            
            switch pattern {
            case .UpperLeft, .Left, .LowerLeft:
                frame.origin.x = min(frame.origin.x + location.x, frame.maxX - minSideLength)
                frame.size.width = max(frame.size.width - location.x, minSideLength)
            case .UpperRight, .Right, .LowerRight:
                frame.size.width = max(location.x, minSideLength)
            default:
                break
            }
            
            switch pattern {
            case .UpperLeft, .Upper, .UpperRight:
                frame.origin.y = min(frame.origin.y + location.y, frame.maxY - minSideLength)
                frame.size.height = max(frame.size.height - location.y, minSideLength)
            case .LowerLeft, .Lower, .LowerRight:
                frame.size.height = max(location.y, minSideLength)
            default:
                break
            }
            
            if delegate == nil || delegate?.cropView(self, canChangeTo: frame) == true {
                self.frame = frame
                updateCropLines(false)
                delegate?.cropViewChanged?(self)
            }
        case .Ended:
            panningPattern = nil
            delegate?.cropViewFinishedChange?(self)
        default:
            print(recognizer.state.rawValue)
            break
        }
    }
    
    func updateLines(lines: [UIView], horizontal: Bool) {
        for i in 0..<lines.count {
            let line = lines[i]
            if horizontal {
                line.frame = CGRect(x: 0,
                                    y: (frame.height / CGFloat(lines.count + 1)) * CGFloat(i + 1),
                                    width: frame.width,
                                    height: 1 / UIScreen.mainScreen().scale)
            } else {
                line.frame = CGRect(x: (frame.width / CGFloat(lines.count + 1)) * CGFloat(i + 1),
                                    y: 0,
                                    width: 1 / UIScreen.mainScreen().scale,
                                    height: frame.height)
            }
        }
    }
    
    func updateCropLines(animated: Bool) {
        if cropLinesDismissed { showCropLines() }
        
        func animationBlock() {
            updateLines(horizontalCropLines, horizontal: true)
            updateLines(verticalCropLines, horizontal: false)
        }
        
        if animated {
            UIView.animateWithDuration(0.25, animations: animationBlock)
        } else {
            animationBlock()
        }
    }
    
    func updateGridLines(animated: Bool) {
        if gridLinesDismissed { showGridLines() }
        
        func animationBlock() {
            updateLines(horizontalGridLines, horizontal: true)
            updateLines(verticalGridLines, horizontal: false)
        }
        
        if animated {
            UIView.animateWithDuration(0.25, animations: animationBlock)
        } else {
            animationBlock()
        }
    }
    
    func showCropLines() {
        cropLinesDismissed = false
        UIView.animateWithDuration(0.2) {
            self.horizontalCropLines.forEach({ (line) in line.alpha = 1.0 })
            self.verticalCropLines.forEach({ (line) in line.alpha = 1.0 })
        }
    }
    
    func showGridLines() {
        gridLinesDismissed = false
        UIView.animateWithDuration(0.2) {
            self.horizontalGridLines.forEach({ (line) in line.alpha = 1.0 })
            self.verticalGridLines.forEach({ (line) in line.alpha = 1.0 })
        }
    }
    
    func dismissCropLines() {
        UIView.animateWithDuration(0.2, animations: {
            self.horizontalCropLines.forEach({ (line) in line.alpha = 0.0 })
            self.verticalCropLines.forEach({ (line) in line.alpha = 0.0 })
            }, completion: { [unowned self] (ok) in
                self.cropLinesDismissed = true
            })
    }
    
    func dismissGridLines() {
        UIView.animateWithDuration(0.2, animations: {
            self.horizontalGridLines.forEach({ (line) in line.alpha = 0.0 })
            self.verticalGridLines.forEach({ (line) in line.alpha = 0.0 })
            }, completion: { [unowned self] (ok) in
                self.gridLinesDismissed = true
            })
    }
}

class PTRotateView: UIControl {
    
    var imageView: UIImageView!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var value: CGFloat = 0.0 {
        didSet {
            value = max(min(value, maxValue), minValue)
            imageView.transform = CGAffineTransformMakeRotation(value)
        }
    }
    var continuous = true
    var minValue: CGFloat = -CGFloat(M_PI_4) {
        didSet {
            if (value < minValue) {
                setValue(to: minValue, animated: false)
            }
        }
    }
    var maxValue: CGFloat = CGFloat(M_PI_4) {
        didSet {
            if (value > maxValue) {
                setValue(to: maxValue, animated: false)
            }
        }
    }
    
    convenience init() {
        let frame = CGRect(origin: CGPointZero, size: CGSize(width: 290, height: 70))
        self.init(frame: frame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(image: UIImage(named: "rotateControl"))
        addSubview(imageView)
        imageView.center = CGPoint(x: bounds.midX, y: bounds.maxY - imageView.frame.height / 2.0)
        imageView.autoresizingMask = [.FlexibleBottomMargin]
        
        clipsToBounds = true
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.gestureHandler(for:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        addGestureRecognizer(panGestureRecognizer)
    }
    
    func setValue(to value: CGFloat, animated: Bool = true) {
        if animated {
            UIView.animateWithDuration(0.3, animations: { [unowned self] in
                self.value = value
                })
        } else {
            self.value = value
        }
        sendActionsForControlEvents(.ValueChanged)
    }
    
    func gestureHandler(for recogenizer: UIPanGestureRecognizer) {
        guard continuous || recogenizer.state == .Ended else {
            return
        }
        
        let translation = recogenizer.translationInView(self)
        recogenizer.setTranslation(CGPointZero, inView: self)
        
        setValue(to: value + -translation.x * CGFloat(M_PI_2 / 145.0), animated: false)
        
        if recogenizer.state == .Ended {
            sendActionsForControlEvents(.TouchUpInside)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum PTCropViewPanningPattern {
    case UpperLeft
    case Upper
    case UpperRight
    case Left
    case Center
    case Right
    case LowerLeft
    case Lower
    case LowerRight
}

class PhotoTweakView: UIView {
    
    private struct Params {
        static let backgroundColor = UIColor(white: 86.0/255.0, alpha: 1)
        static let maskColor = UIColor(white: 0, alpha: 0.6)
        static let rotationLimitDegree: Double = 45
        static let maxContentRatio = CGVector(dx: 0.9, dy: 0.7)
        static let headerHeight: CGFloat = 60
        static let waitAfterCropEnded = 2.0
        static let padding: CGFloat = 16
    }
    
    var masks: [UIView] = [UIView(), UIView(), UIView(), UIView()]
    
    var scrollView: UIScrollView!
    var imageView: UIImageView!
    var cropView: PTCropView!
    var rotateView: PTRotateView!
    var headerBar: UIView!
    var footerBar: UIView!
    
    var limitRotateAngle: CGFloat = CGFloat(Params.rotationLimitDegree * (M_PI / 180))
    
    private var originSize = CGSizeZero
    private var originCenter = CGPointZero
    private var yOffset: CGFloat = 0
    private var cropEndedTimer: NSTimer?
    
    private var rotatedCount: Int = 0
    var rotatedAngle: CGFloat {
        return CGFloat(Double(rotatedCount) * M_PI_2) + rotateView.value
    }
    
    init(frame: CGRect, image: UIImage) {
        super.init(frame: frame)
        
        backgroundColor = Params.backgroundColor
        clipsToBounds = true
        
        let SVFrame = CGRect(x: bounds.origin.x, y: bounds.origin.y + 48, width: bounds.width, height: bounds.height - 96)
        scrollView = UIScrollView(frame: SVFrame)
        scrollView.minimumZoomScale = 0
        scrollView.maximumZoomScale = 1
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.delegate = self
        addSubview(scrollView)
        
        addGestureRecognizer(scrollView.panGestureRecognizer)
        addGestureRecognizer(scrollView.pinchGestureRecognizer!)
        
        imageView = UIImageView(image: image)
        scrollView.addSubview(imageView)
        
        masks.forEach { (mask) in
            mask.backgroundColor = Params.maskColor
            mask.userInteractionEnabled = false
            addSubview(mask)
        }
        
        cropView = PTCropView()
        cropView.delegate = self
        addSubview(cropView)
        scrollView.panGestureRecognizer.requireGestureRecognizerToFail(cropView.panGestureRecognizer)
        
        rotateView = PTRotateView()
        addSubview(rotateView)
        rotateView.center = self.center
        let maxAngle = Params.rotationLimitDegree * (M_PI / 180.0)
        rotateView.minValue = CGFloat(-maxAngle)
        rotateView.maxValue = CGFloat(maxAngle)
        rotateView.addTarget(self, action: #selector(self.resizeScrollView), forControlEvents: .ValueChanged)
        scrollView.panGestureRecognizer.requireGestureRecognizerToFail(rotateView.panGestureRecognizer)
        
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        let maxContentSize = CGSize(width: Params.maxContentRatio.dx * bounds.width, height: Params.maxContentRatio.dy * bounds.height - Params.headerHeight)
        
        let image = imageView.image!
        let scale = max(image.size.width / maxContentSize.width, image.size.height / maxContentSize.height)
        let frame = CGRect(x: 0, y: 0, width: image.size.width / scale, height: image.size.height / scale)
        originSize = frame.size
        
        yOffset = maxContentSize.height / 2 + Params.headerHeight
        
        scrollView.frame = frame
        originCenter = CGPoint(x: bounds.midX, y: yOffset)
        scrollView.center = originCenter
        
        let minZoom = scrollView.bounds.width / imageView.frame.width
        scrollView.minimumZoomScale = minZoom
        scrollView.zoomScale = minZoom
        cropView.frame = scrollView.frame
        rotateView.frame.origin.y = cropView.frame.maxY
        updateMasks()
    }
    
    func updateMasks(animated: Bool = false) {
        func animation() {
            masks[0].frame = CGRect(x: 0, y: 0, width: cropView.frame.maxX, height: cropView.frame.minY)
            masks[1].frame = CGRect(x: 0, y: cropView.frame.minY, width: cropView.frame.minX, height: bounds.height - cropView.frame.minY)
            masks[2].frame = CGRect(x: cropView.frame.minX, y: cropView.frame.maxY, width: bounds.width - cropView.frame.minX, height: bounds.height - cropView.frame.maxY)
            masks[3].frame = CGRect(x: cropView.frame.maxX, y: 0, width: bounds.width - cropView.frame.maxX, height: cropView.frame.maxY)
        }
        
        if animated {
            UIView.animateWithDuration(0.25, animations: animation)
        } else {
            animation()
        }
    }
    
    func relocateCropView(animeted: Bool = true) {
        let maxCropSize = CGSize(width: bounds.width * Params.maxContentRatio.dx, height: bounds.height * Params.maxContentRatio.dy - Params.headerHeight)
        let scale = max(cropView.frame.width / maxCropSize.width, cropView.frame.height / maxCropSize.height)
        let newSize = CGSize(width: cropView.frame.width / scale, height: cropView.frame.height / scale)
        
        func animation() {
            cropView.frame.size = newSize
            cropView.center = originCenter
            
            rotateView.alpha = 1.0
            updateMasks()
            scrollView.minimumZoomScale = 0 // 先取消限制，下面再重算
            scrollView.zoomScale /= scale
            resizeScrollView(false)
        }
        
        if animeted {
            UIView.animateWithDuration(0.25, animations: animation)
        } else {
            animation()
        }
        
        rotateView.frame.origin.y = cropView.frame.maxY
    }
    
    func checkCropFrame() {
        resizeScrollView()
    }
    
    func rotate90Degree() {
        rotatedCount = (rotatedCount + 3) % 4
        
        UIView.animateWithDuration(0.25) { [unowned self] in
            let center = self.cropView.center
            self.cropView.bounds = CGRect(x: 0, y: 0, width: self.cropView.bounds.height, height: self.cropView.bounds.width)
            self.cropView.center = center
            self.resizeScrollView()
            self.relocateCropView(false)
        }
    }
    
    func reset() {
        rotatedCount = 0
        cropEndedTimer?.invalidate()
        cropEndedTimer = nil
        
        UIView.animateWithDuration(0.25) { [unowned self] in
            self.rotateView.setValue(to: 0)
            self.cropView.frame.size = self.originSize
            self.cropView.center = self.originCenter
            self.scrollView.frame.size = self.originSize
            self.scrollView.center = self.originCenter
            self.relocateCropView(false)
            self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        }
    }
    
    func setCropRatio(to ratio: CGVector) {
        // 如果已經是該比例，則長寬對調
        let currentRatio = cropView.bounds.width / cropView.bounds.height
        if abs(ratio.dx / ratio.dy - currentRatio) < 0.00001 {
            UIView.animateWithDuration(0.25) { [unowned self] in
                let center = self.cropView.center
                self.cropView.bounds = CGRect(x: 0, y: 0, width: self.cropView.bounds.height, height: self.cropView.bounds.width)
                self.cropView.center = center
                self.resizeScrollView()
                self.relocateCropView(false)
            }
            return
        }
        
        let maxContentSize = CGSize(width: Params.maxContentRatio.dx * bounds.width, height: Params.maxContentRatio.dy * bounds.height - Params.headerHeight)
        let scale = min(maxContentSize.width / ratio.dx, maxContentSize.height / ratio.dy)
        let frame = CGRect(x: 0, y: 0, width: ratio.dx * scale, height: ratio.dy * scale)
        UIView.animateWithDuration(0.25) { [unowned self] in
            let center = self.cropView.center
            self.cropView.frame = frame
            self.cropView.center = center
            self.resizeScrollView(false)
            self.relocateCropView(false)
        }
    }
    
    func setRotateAngle(to angle: CGFloat, animated: Bool = false) {
        var angle = angle
        while angle < 0 { angle += CGFloat(M_PI * 2) }
        angle += CGFloat(M_PI_4)
        
        rotatedCount = Int(Double(angle) / M_PI_2)
        rotateView.value = CGFloat((Double(angle) % M_PI_2) - M_PI_4)
        print(rotatedAngle)
        self.resizeScrollView()
        //        self.relocateCropView(false)
    }
    
    func onCropEnded() {
        cropEndedTimer = nil
        relocateCropView()
    }
    
    func resizeScrollView(keepContentLocal: Bool = true) {
        scrollView.transform = CGAffineTransformMakeRotation(rotatedAngle)
        
        let w = fabs(cos(rotatedAngle)) * cropView.bounds.width + fabs(sin(rotatedAngle)) * cropView.bounds.height
        let h = fabs(sin(rotatedAngle)) * cropView.bounds.width + fabs(cos(rotatedAngle)) * cropView.bounds.height
        
        let offsetCenter = CGPoint(x: scrollView.contentOffset.x + scrollView.bounds.width / 2, y: scrollView.contentOffset.y + scrollView.bounds.height / 2)
        
        scrollView.bounds.size = CGSize(width: w, height: h)
        let cropCenterAtScroll = self.convertPoint(cropView.center, toView: scrollView)
        let centerDelta = CGPoint(x: cropCenterAtScroll.x - scrollView.bounds.midX, y: cropCenterAtScroll.y - scrollView.bounds.midY)
        scrollView.center = cropView.center
        
        let newOffset = CGPoint(x: offsetCenter.x - w / 2, y: offsetCenter.y - h / 2)
        scrollView.contentOffset = newOffset
        
        let zoomScaleToBounds = max(w / imageView.bounds.size.width, h / imageView.bounds.size.height)
        scrollView.minimumZoomScale = zoomScaleToBounds
        if scrollView.zoomScale < zoomScaleToBounds {
            scrollView.zoomScale = zoomScaleToBounds
        }
        else if keepContentLocal {
            scrollView.contentOffset.x += centerDelta.x
            scrollView.contentOffset.y += centerDelta.y
        }
        
        clampContentOffset()
    }
    
    func clampContentOffset() {
        if scrollView.contentOffset.x < 0 { scrollView.contentOffset.x = 0 }
        if scrollView.contentOffset.y < 0 { scrollView.contentOffset.y = 0 }
        
        if scrollView.contentSize.height - scrollView.contentOffset.y <= scrollView.bounds.height {
            scrollView.contentOffset.y = scrollView.contentSize.height - scrollView.bounds.height
        }
        if scrollView.contentSize.width - scrollView.contentOffset.x <= scrollView.bounds.width {
            scrollView.contentOffset.x = scrollView.contentSize.width - scrollView.bounds.width
        }
    }
}

// - MARK: UIScrollViewDelegate
extension PhotoTweakView: UIScrollViewDelegate {
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if cropEndedTimer != nil {
            cropEndedTimer!.invalidate()
            cropEndedTimer = NSTimer.scheduledTimerWithTimeInterval(Params.waitAfterCropEnded, target: self, selector: #selector(self.onCropEnded), userInfo: nil, repeats: false)
        }
    }
}

// - MARK: PTCropViewDelegate
extension PhotoTweakView: PTCropViewDelegate {
    func cropViewChanged(cropView: PTCropView) {
        if self.rotateView.alpha > 0.001 {
            UIView.animateWithDuration(0.25) { [unowned self] in
                self.rotateView.alpha = 0
            }
        }
        cropEndedTimer?.invalidate()
        updateMasks()
        checkCropFrame()
    }
    
    func cropViewFinishedChange(cropView: PTCropView) {
        cropEndedTimer?.invalidate()
        cropEndedTimer = NSTimer.scheduledTimerWithTimeInterval(Params.waitAfterCropEnded, target: self, selector: #selector(self.onCropEnded), userInfo: nil, repeats: false)
        cropView.dismissCropLines()
    }
    
    func cropView(cropView: PTCropView, canChangeTo frame: CGRect) -> Bool {
        return true
    }
}
