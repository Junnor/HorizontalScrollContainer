//
//  JuScrollContainerView.swift
//  HorizontalScrollContainer
//
//  Created by Ju on 2017/12/31.
//  Copyright © 2017年 Ju. All rights reserved.
//

import UIKit

private let defaultSelectedPage = 0

extension NSNotification.Name {
    static let ShowMenuItem = NSNotification.Name(rawValue: "ShowMenuItem")
}

class JuScrollContainerView: UIView {

    // MARK: - Designated init
    
    init(frame: CGRect, buttonItems: [UIButton], viewItems: [UIView]) {
        super.init(frame: frame)
        
        print("init(frame: CGRect, buttonItems: [UIButton], viewItems: [UIView])")
        
        if buttonItems.count != viewItems.count {
            fatalError("items count not equal")
        }
        
        self.buttonItems = buttonItems
        self.viewItems = viewItems
        
        for _ in 0..<buttonItems.count {
            firstShowWithItems.append(false)
        }
        
        addAllSubView()
        setupConstraints()
        resetSubviewsLayoutIfNeeded()
        firstLoadDataNotification()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    // MARK: - Notification
    
    /// Set container title to have a better notification name
    var containerTitle = ""
    
    /// Scroll to current page's notificatin name
    var atCurrentIndexNotificationName: NSNotification.Name {
        return NSNotification.Name(rawValue: "com.ju.\(containerTitle)AtMenuItem")
    }
    
    // MARK: - Public properties
    
    /// Default offset page for container
    var defaultOffsetPage = defaultSelectedPage {
        didSet {
            if defaultOffsetPage >= buttonItems.count {
                fatalError("The defaultOffsetPage property must be less than buttonItems.count")
            } else {
                userDefaultOffsetPage = true
                lastIndex = defaultOffsetPage
            }
        }
        
    }
    
    /// Menu view height
    var menuViewHeight: CGFloat = 49 {
        didSet {
            print("set menuViewHeight")
            menuHeight?.isActive = false
            menuHeight = menuView.heightAnchor.constraint(equalToConstant: menuViewHeight)
            menuHeight?.isActive = true
        }
    }
    
    /// Menu view background color
    var menuTitleViewBackgroundColor = UIColor(red: 251/255.0, green: 250/255.0, blue: 251/255.0, alpha: 1.0) {
        didSet {
            print("set menuTitleViewColor")
            menuTitleView?.backgroundColor = menuTitleViewBackgroundColor
        }
    }
    
    /// Unselected button item text color
    var unselectedItemColor = UIColor.darkGray {
        didSet {
            print("set unselectedItemColor")
        }
    }
    
    /// Selected button item text color
    var selectedItemColor = UIColor.darkGray {
        didSet {
            print("set selectedItemColor")
            
            // Prevent the order is not right when set public properties value
            lastIndex = defaultOffsetPage
        }
    }

    /// Button item font
    var itemFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            print("set itemFont")
            for button in buttonItems {
                button.titleLabel?.font = itemFont
            }
        }
    }
    
    /// Indicator color
    var indicatorColor = UIColor.gray {
        didSet {
            print("set indicatorColor")
            indicatorView?.backgroundColor = indicatorColor
        }
    }
    
    /// Indicator view width, value within (0 , screenWidth/buttonItems.count)
    var indicatorWidth: CGFloat = 40 {
        didSet {
            print("set indicatorWidth")
            indicatorView?.frame.size.width = indicatorWidth
        }
    }
    
    /// Indicator view height, value within (0 , realTitleBottomMargin]
    var indicatorHeight: CGFloat = 3 {
        didSet {
            print("set indicatorHeight")
            indicatorView?.frame.size.height = indicatorHeight
            
            indicatorView?.layer.cornerRadius = indicatorHeight/2
            indicatorView?.layer.masksToBounds = true
        }
    }
    
    // MARK: - Private properties
    
    private var buttonItems: [UIButton] = []
    private var viewItems: [UIView] = []
    
    private var menuView: UIView!
    private var scrollView: UIScrollView!
    private var menuTitleView: UIView!
    private var titleStackView: UIStackView!
    private var indicatorView: UIView!
    
    private var menuHeight: NSLayoutConstraint!
    private var titles: [String] = [String]()
    private var indicatorOriginsX: [CGFloat] = [CGFloat]()
    private var itemsViewFrameOriginX: [CGFloat] = [CGFloat]()
    
    private var indicatorViewLastOriginX: CGFloat = 0.0
    private var scale: CGFloat!
    private var userDefaultOffsetPage = false

    private let moveDuration: TimeInterval = 0.2
    private let realTitleBottomMargin: CGFloat = 6
    
    // MARK: - Helper
    
    private func addAllSubView() {
        // Menu container
        menuView = UIView()
        self.addSubview(menuView)
        
        // Title container
        menuTitleView = UIView()
        menuTitleView.backgroundColor = menuTitleViewBackgroundColor
        titleStackView = UIStackView()
        
        // Indicator
        indicatorView = UIView()
        indicatorView.layer.cornerRadius = indicatorHeight/2
        indicatorView.layer.masksToBounds = true
        indicatorView.backgroundColor = indicatorColor
        
        // ScrollView
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        for button in buttonItems {
            button.setTitleColor(unselectedItemColor, for: .normal)
            button.titleLabel?.textColor = unselectedItemColor
            button.titleLabel?.font = itemFont
            button.addTarget(self,
                             action: #selector(contentOffSetXForButton(sender:)),
                             for: .touchUpInside)
            
            titles.append(button.currentTitle!)
            titleStackView.addArrangedSubview(button)
        }
        
        titleStackView.alignment = .center
        titleStackView.axis = .horizontal
        titleStackView.distribution = .fillEqually
        
        for i in 0 ..< viewItems.count {
            scrollView.addSubview(viewItems[i])
        }
        
        menuTitleView.addSubview(titleStackView)
        menuTitleView.addSubview(indicatorView)
        
        menuView.addSubview(menuTitleView)
        
        self.addSubview(scrollView)
    }
    
    private func setupConstraints() {
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuTitleView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Menu view
        let menuTop = menuView.topAnchor.constraint(equalTo: topAnchor)
        let menuLeading = menuView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let menuTrailing = menuView.trailingAnchor.constraint(equalTo: trailingAnchor)
        menuHeight = menuView.heightAnchor.constraint(equalToConstant: menuViewHeight)
        
        var menuConstraints: [NSLayoutConstraint] = []
        menuConstraints.append(menuTop)
        menuConstraints.append(menuLeading)
        menuConstraints.append(menuTrailing)
        menuConstraints.append(menuHeight)
        
        // Title view
        let titleViewTop = menuTitleView.topAnchor.constraint(equalTo: menuView.topAnchor)
        let titleViewLeading = menuTitleView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor)
        let titleViewTrailing = menuTitleView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor)
        let titleViewBottom = menuTitleView.bottomAnchor.constraint(equalTo: menuView.bottomAnchor)
        
        var titleViewConstraints: [NSLayoutConstraint] = []
        titleViewConstraints.append(titleViewTop)
        titleViewConstraints.append(titleViewLeading)
        titleViewConstraints.append(titleViewTrailing)
        titleViewConstraints.append(titleViewBottom)
        
        // Title stack view
        let titleStackViewTop = titleStackView.topAnchor.constraint(equalTo: menuTitleView.topAnchor)
        let titleStackViewLeading = titleStackView.leadingAnchor.constraint(equalTo: menuTitleView.leadingAnchor)
        let titleStackViewTrailing = titleStackView.trailingAnchor.constraint(equalTo: menuTitleView.trailingAnchor)
        let titleStatckViewBottom = titleStackView.bottomAnchor.constraint(equalTo: menuTitleView.bottomAnchor, constant: -realTitleBottomMargin)
        
        var titleStackViewConstraints: [NSLayoutConstraint] = []
        titleStackViewConstraints.append(titleStackViewTop)
        titleStackViewConstraints.append(titleStackViewLeading)
        titleStackViewConstraints.append(titleStackViewTrailing)
        titleStackViewConstraints.append(titleStatckViewBottom)
        
        // Scroll view
        var scrollViewConstraints: [NSLayoutConstraint] = []
        let scrollViewTop = scrollView.topAnchor.constraint(equalTo: menuView.bottomAnchor)
        let scrollViewLeading = scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let scrollViewTrailing = scrollView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let scrollViewBottom = scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        scrollViewConstraints.append(scrollViewTop)
        scrollViewConstraints.append(scrollViewLeading)
        scrollViewConstraints.append(scrollViewTrailing)
        scrollViewConstraints.append(scrollViewBottom)
        
        // Activate
        var all: [NSLayoutConstraint] = []
        all += menuConstraints
        all += titleViewConstraints
        all += titleStackViewConstraints
        all += scrollViewConstraints
        
        NSLayoutConstraint.activate(all)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("\nlayoutSubviews")
        
        resetSubviewsLayoutIfNeeded()
    }

    private func resetSubviewsLayoutIfNeeded() {
        print("resetSubviewsLayoutIfNeeded\n")
        
        var contentSize = scrollView.bounds.size
        contentSize.width = contentSize.width * CGFloat(buttonItems.count)
        scrollView.contentSize = contentSize
        
        itemsViewFrameOriginX.removeAll()
        for i in 0 ..< viewItems.count {
            var itemFrame = scrollView.bounds
            let originX = itemFrame.width * CGFloat(i)
            itemFrame.origin.x = originX
            viewItems[i].frame = itemFrame
            
            itemsViewFrameOriginX.append(originX)
        }
        
        // for menuItems originX
        indicatorOriginsX.removeAll()
        
        let itemWidth: CGFloat = menuView.bounds.width/CGFloat(buttonItems.count)
        for i in 0..<buttonItems.count {
            let tmpFrame = CGRect(x: itemWidth*CGFloat(i), y: 0, width: itemWidth, height: 1)
            let indicatorOriginX = tmpFrame.midX - indicatorWidth/2
            indicatorOriginsX.append(indicatorOriginX)
        }
        
        // for sectionIndicatorView
        var indicatorX: CGFloat = 0
        if userDefaultOffsetPage {  // For Default page
            userDefaultOffsetPage = false

            let offset = CGPoint(x: CGFloat(defaultOffsetPage)*scrollView.bounds.width, y: 0)
            scrollView.setContentOffset(offset, animated: false)
            
            indicatorX = indicatorOriginsX[defaultOffsetPage]
        } else { // For rotate
            let offset = CGPoint(x: scrollView.bounds.width * CGFloat(lastIndex), y: 0)
            scrollView.setContentOffset(offset, animated: false)
            
            indicatorX = indicatorOriginsX[lastIndex]
        }
        
        indicatorView.frame = CGRect(x: indicatorX, y: menuView.frame.height - realTitleBottomMargin, width: indicatorWidth, height: indicatorHeight)
        indicatorViewLastOriginX = indicatorView.frame.origin.x

        // indicator scroll scale
        let indicatorScale = indicatorOriginsX[1] - indicatorOriginsX[0]
        scale = indicatorScale / UIScreen.main.bounds.size.width
    }
    
    private func firstLoadDataNotification() {
        
        if self.firstShowWithItems.count > defaultOffsetPage {
            // Notification defaultOffsetPage view controller when first load container
            if self.firstShowWithItems[defaultOffsetPage] == false {
              
                // Set scrollview offset with container first loaded
                if defaultOffsetPage != defaultSelectedPage {
                    let offset = CGPoint(x: UIScreen.main.bounds.width * CGFloat(defaultOffsetPage), y: 0)
                    scrollView.setContentOffset(offset, animated: false)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.setItemsShowData(index: self.defaultOffsetPage, value: true)
                    self.scrollTo(index: self.defaultOffsetPage)
                })
            }
        }
    }
    
    private var firstShowWithItems: [Bool] = []
    private func setItemsShowData(index: Int, value: Bool) {
        firstShowWithItems[index] = value
        if value == true {
            // Notification
            var userInfo: [String: Any] = [:]
            userInfo["index"] = index
            userInfo["value"] = value
            NotificationCenter.default.post(name: NSNotification.Name.ShowMenuItem,
                                            object: nil,
                                            userInfo: userInfo)
        }
    }
    
    private func scrollTo(index: Int) {
        // Notification
        var userInfo: [String: Int] = [:]
        userInfo["currentIndex"] = index
        
        NotificationCenter.default.post(name: atCurrentIndexNotificationName,
                                        object: nil,
                                        userInfo: userInfo)
    }
    
    private var lastIndex = defaultSelectedPage {
        didSet {
            for i in 0..<buttonItems.count {
                let color = i == lastIndex ? selectedItemColor : unselectedItemColor
                buttonItems[i].setTitleColor(color, for: .normal)
            }
        }
    }
    
    // MARK: - Menu button tapped
    @objc private func contentOffSetXForButton(sender: UIButton){
        let currentTitle = sender.currentTitle!
        let index = titles.index(of: currentTitle)!
        
        let scrollWithAnimation = canScrollWithAnimation(current: index)
        lastIndex = index

        let shouldScrollOffset = CGPoint(x: CGFloat(index)*scrollView.bounds.width, y: 0)
        scrollView.setContentOffset(shouldScrollOffset, animated: scrollWithAnimation)
        UIView.animate(withDuration: moveDuration, animations: {
            self.indicatorView.frame.origin.x = self.indicatorOriginsX[index]
            self.indicatorViewLastOriginX = self.indicatorView.frame.origin.x
            
            if self.firstShowWithItems[index] == false {
                self.setItemsShowData(index: index, value: true)
            }
            self.scrollTo(index: index)
        })
    }
    
    
    private func canScrollWithAnimation(current index: Int) -> Bool {
        var range: [Int] = [index]
        range.append(index+1)
        range.append(index-1)
        
        if range.contains(lastIndex) {
            return true
        } else {
            return false
        }
    }
}


extension JuScrollContainerView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x == 0.0 {
            return
        }
        
        UIView.animate(withDuration: moveDuration, animations: {
            let x = scrollView.contentOffset.x * self.scale + self.indicatorOriginsX[0]
            self.indicatorView.frame.origin.x = x
            self.indicatorViewLastOriginX = x
        })
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if itemsViewFrameOriginX.contains(scrollView.contentOffset.x) {
            let index = itemsViewFrameOriginX.index(of: scrollView.contentOffset.x)!
            lastIndex = index
            if self.firstShowWithItems[index] == false {
                self.setItemsShowData(index: index, value: true)
            }
            self.scrollTo(index: index)
        }
        
    }

}
