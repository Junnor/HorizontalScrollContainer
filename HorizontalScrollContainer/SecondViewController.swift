//
//  SecondViewController.swift
//  Parent
//
//  Created by Ju on 2017/12/29.
//  Copyright © 2017年 Ju. All rights reserved.
//

import UIKit


class SecondViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(menuItemShow(notification:)),
                                               name: NSNotification.Name.ShowMenuItem, object: nil)
    }
    
    
    @objc private func menuItemShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let _ = userInfo["index"] as? Int,
            let _ = userInfo["value"] as? Bool else {
                return
        }
        
    }

}
