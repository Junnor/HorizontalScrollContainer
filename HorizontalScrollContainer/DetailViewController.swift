//
//  DetailViewController.swift
//  HorizontalScrollContainer
//
//  Created by Ju on 2017/12/31.
//  Copyright © 2017年 Ju. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    var text: String? {
        didSet {
            titleLabel?.text = text
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = text
        }
    }
    
}
