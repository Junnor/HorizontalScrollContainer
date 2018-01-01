//
//  ViewController.swift
//  HorizontalScrollContainer
//
//  Created by Ju on 2017/12/31.
//  Copyright © 2017年 Ju. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    private let controllerTitle = "Container"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = controllerTitle
                
        initializerMenuContainer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        scrollContainer.frame = containerView.bounds
    }
    
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - For menu container
    
    private var twovc: SecondViewController!
    
    private var scrollContainer: JuScrollContainerView!
    private func initializerMenuContainer() {
        // Button items
        let one = UIButton()
        let two = UIButton()
        let three = UIButton()
        
        one.setTitle("One", for: .normal)
        two.setTitle("Two", for: .normal)
        three.setTitle("Three", for: .normal)
        
        var buttonItems = [UIButton]()
        buttonItems.append(one)
        buttonItems.append(two)
        buttonItems.append(three)
        
        // SubViewControllers
        let onevc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FirstViewController") as! FirstViewController
        twovc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewController") as! SecondViewController
        let threevc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ThirdViewController") as! ThirdViewController
        
        var viewItems = [UIView]()
        
        viewItems.append(onevc.view)
        viewItems.append(twovc.view)
        viewItems.append(threevc.view)
        
        // Container(subViewController's view will added to container)
        scrollContainer = JuScrollContainerView(frame: containerView.bounds,
                                                buttonItems: buttonItems,
                                                viewItems: viewItems)
        containerView.addSubview(scrollContainer)
        
        // Set properties
        scrollContainer.containerTitle = controllerTitle
        
//        scrollContainer.defaultOffsetPage = 1

//        scrollContainer.menuViewHeight = 70
//        scrollContainer.menuTitleViewColor = UIColor.cyan.withAlphaComponent(1.0)

//        scrollContainer.itemFont = UIFont.systemFont(ofSize: 17)
//        scrollContainer.selectedItemColor = UIColor.red
//        scrollContainer.unselectedItemColor = UIColor.black

//        scrollContainer.indicatorColor = UIColor.red
//        scrollContainer.indicatorWidth = 50
//        scrollContainer.indicatorHeight = 5

        // Add subViewControllers to self
        addChildViewController(onevc)
        onevc.didMove(toParentViewController: self)
        
        addChildViewController(twovc)
        twovc.didMove(toParentViewController: self)
        
        addChildViewController(threevc)
        threevc.didMove(toParentViewController: self)
        
        // Set notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollAtIndex(notification:)),
                                               name: scrollContainer.atCurrentIndexNotificationName,
                                               object: nil)
    }
    
    
    @objc private func scrollAtIndex(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let _ = userInfo["currentIndex"] as? Int else { return }
    }
    
    
}
