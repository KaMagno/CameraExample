//
//  PreviewViewController.swift
//  Camera
//
//  Created by Kaique Magno Dos Santos on 19/04/18.
//  Copyright © 2018 Dreamers and Makers. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {

    @IBOutlet weak var outletImage:UIImageView!
    
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.outletImage.image = self.image
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
