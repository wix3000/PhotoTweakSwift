//
//  ViewController.swift
//  PhotoTweakSwift
//
//  Created by Wix Litariz on 2017/4/27.
//  Copyright © 2017年 Wix ART Work. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let sampleImage = CIImage(image: UIImage(named: "SampleImage")!)!
    var croppingParam: [String : AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func crop() {
        let vc = PhotoTweakViewController(image: sampleImage)
        vc.restoreParameter = croppingParam
        vc.delegate = self
        presentViewController(vc, animated: true, completion: nil)
    }
}

extension ViewController: PhotoTweakViewControllerDelegate {
    func photoTweak(photoTweak: PhotoTweakViewController, tweakedImage: CIImage, withParameter parameter: [String : AnyObject]) {
        imageView.image = tweakedImage.UIImageViaCGimage()
        croppingParam = parameter
        photoTweak.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func photoTweakDidCancel(photoTweak: PhotoTweakViewController) {
        photoTweak.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension CIImage {
    func UIImageViaCGimage() -> UIImage? {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        let context = CIContext(EAGLContext: eaglContext, options: options)
        guard let cgImage = context.createCGImage(self, fromRect: extent) else {
            return nil
        }
        cgImage
        return UIImage(CGImage: cgImage)
    }
}
