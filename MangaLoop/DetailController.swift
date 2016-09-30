//
//  DetailController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/30/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import TLTagsControl

class DetailController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tagsControl: TLTagsControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tagsControl.mode = .Edit

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
