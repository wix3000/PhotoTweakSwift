//
//  ViewController.swift
//  PhotoTweakSwift
//
//  Created by Wix Litariz on 2017/4/27.
//  Copyright © 2017年 Wix ART Work. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let vc = PTRotateView() //PTCropView(frame: CGRect(x: 50, y: 50, width: 200, height: 200))
//        view.addSubview(vc)
    }
    
    override func viewDidAppear(animated: Bool) {
        let vc = PhotoTweakViewController(image: CIImage(image: UIImage(named: "SampleImage")!)!)
        presentViewController(vc, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

