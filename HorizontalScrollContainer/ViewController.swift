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
    
    
    // MARK: - For menu container
    
    private var twovc: SecondViewController!
    
    private var scrollContainer: JuScrollContainerView!
    private func initializerMenuContainer() {
        
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 64, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 64)
        view.addSubview(containerView)
        
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
                                                titles: ["One", "Two", "Three"],
                                                viewItems: viewItems,
                                                managerController: self,
                                                isTitleViewStyle: false,
                                                useSeperateLine: false,
                                                useBadge: false,
                                                isRedPoint: false)
        scrollContainer.delegate = self
        scrollContainer.showRedBadgeValues = [1: 3]
        containerView.addSubview(scrollContainer)
        
        
        // Set properties
        
        scrollContainer.menuViewHeight = 70

        scrollContainer.itemFont = UIFont.systemFont(ofSize: 17)
        scrollContainer.selectedItemColor = UIColor.red
        scrollContainer.unselectedItemColor = UIColor.black

        scrollContainer.indicatorColor = UIColor.red
        scrollContainer.indicatorWidth = 50
        scrollContainer.indicatorHeight = 5

        // Add subViewControllers to self
        addChildViewController(onevc)
        onevc.didMove(toParentViewController: self)
        
        addChildViewController(twovc)
        twovc.didMove(toParentViewController: self)
        
        addChildViewController(threevc)
        threevc.didMove(toParentViewController: self)
    }
    
    
    
}

extension ViewController: JuScrollContainerViewDelegate {
    
    func scrollContainerView(containerView: JuScrollContainerView, scrollAt page: Int, isFirstScrollToIt: Bool) {
        if isFirstScrollToIt {
            print("isFirstScrollToIt, page = \(page)")
            if page == 1 {
                scrollContainer.shouldHideBadgeIndex = page
            }
        } else {
            print("not isFirstScrollToIt page = \(page)")
        }
    }
    
}
