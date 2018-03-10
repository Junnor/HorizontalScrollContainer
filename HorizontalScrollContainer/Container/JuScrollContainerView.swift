//
//  JuScrollContainerView.swift
//  HorizontalScrollContainer
//
//  Created by Ju on 2017/12/31.
//  Copyright © 2017年 Ju. All rights reserved.
//

import UIKit


@objc protocol JuScrollContainerViewDelegate: class {
    
    /*
     page: 当前所在的滚动页面 [0...]
     isFirstScrollToIt: 是否为第一次滚动到 page 页
     */
    @objc optional func scrollContainerView(containerView: JuScrollContainerView, scrollAt page: Int, isFirstScrollToIt: Bool)
}

private let defaultSelectedPage = 0

class JuScrollContainerView: UIView {
    
    
    weak var delegate: JuScrollContainerViewDelegate?
    
    // MARK: - Designated init
    
    init(frame: CGRect,
         titles: [String],
         viewItems: [UIView],
         managerController: UIViewController,
         isTitleViewStyle: Bool = false,
         useSeperateLine: Bool = false,
         useBadge: Bool = false,
         isRedPoint: Bool = false) {
        
        super.init(frame: frame)
        
        
        if titles.count != viewItems.count {
            fatalError("items count not equal")
        }
        
        
        self.menuTitles = titles
        self.viewItems = viewItems
        self.managerController = managerController
        
        self.useSeperateLine = useSeperateLine
        self.isTitleViewStyle = isTitleViewStyle
        self.useBadge = useBadge
        self.isRedPoint = isRedPoint
        
        for _ in 0..<viewItems.count {
            hasShowPages.append(false)
        }
        
        
        addAllSubView()
        setupConstraints()
        resetSubviewsLayoutIfNeeded()
        firstLoadDataNotification()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isTitleViewStyle = false
    private weak var managerController: UIViewController!
    
    // MARK: - Public properties
    
    /// Default offset page for container
    var defaultOffsetPage = defaultSelectedPage {
        didSet {
            if defaultOffsetPage >= viewItems.count {
                fatalError("The defaultOffsetPage property must be less than viewItems.count")
            } else {
                userDefaultOffsetPage = true
                lastIndex = defaultOffsetPage
            }
        }
        
    }
    
    /// Menu view height
    var menuViewHeight: CGFloat = 44 {
        didSet {
            //            print("set menuViewHeight")
            menuHeight?.isActive = false
            menuHeight = menuView.heightAnchor.constraint(equalToConstant: menuViewHeight)
            menuHeight?.isActive = true
        }
    }
    
    /// Menu view background color
    var menuTitleViewBackgroundColor = UIColor(red: 251/255.0, green: 250/255.0, blue: 251/255.0, alpha: 1.0) {
        didSet {
            //            print("set menuTitleViewColor")
            menuTitleView?.backgroundColor = menuTitleViewBackgroundColor
        }
    }
    
    /// Unselected button item text color
    var unselectedItemColor = UIColor.darkGray {
        didSet {
            //            print("set unselectedItemColor")
        }
    }
    
    /// Selected button item text color
    var selectedItemColor = UIColor.darkGray {
        didSet {
            //            print("set selectedItemColor")
            
            // Prevent the order is not right when set public properties value
            lastIndex = defaultOffsetPage
        }
    }
    
    /// Button item font
    var itemFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            //            print("set itemFont")
            for title in titleLabels {
                title.font = itemFont
            }
        }
    }
    
    /// Indicator color
    var indicatorColor = UIColor.gray {
        didSet {
            //            print("set indicatorColor")
            indicatorView?.backgroundColor = indicatorColor
        }
    }
    
    /// Indicator view width, value within (0 , screenWidth/viewItems.count)
    var indicatorWidth: CGFloat = 40 {
        didSet {
            //            print("set indicatorWidth")
            indicatorView?.frame.size.width = indicatorWidth
        }
    }
    
    /// Indicator view height, value within (0 , realTitleBottomMargin]
    var indicatorHeight: CGFloat = 3 {
        didSet {
            //            print("set indicatorHeight")
            indicatorView?.frame.size.height = indicatorHeight
            
            indicatorView?.layer.cornerRadius = indicatorHeight/2
            indicatorView?.layer.masksToBounds = true
        }
    }
    
    
    /// [index: value]
    var showRedBadgeValues: [Int: Int] = [:] {
        didSet {
            for (index, value) in showRedBadgeValues {
                if index < redBadgeLabels.count && useBadge { // Not out if bounds
                    redBadgeLabels[index].isHidden = false
                    
                    if !isRedPoint {
                        redBadgeLabels[index].text = "\(value)"
                    }
                }
            }
        }
    }
    
    var shouldHideBadgeIndex: Int = 0 {
        didSet {
            if shouldHideBadgeIndex < redBadgeLabels.count {
                redBadgeLabels[shouldHideBadgeIndex].isHidden = true
            }
        }
    }
    
    
    // MARK: - Private properties
    
    private var titleViews: [UIView] = []
    private var redBadgeLabels: [UILabel] = []  // 是小红点的情况就不显示小红点文字了
    private var titleLabels: [UILabel] = []
    
    private var buttonItems: [UIButton] = []
    private var viewItems: [UIView] = []
    private var useSeperateLine = false
    private var useBadge = false
    private var isRedPoint = false
    
    private let seperateLineHeight: CGFloat = 0.5
    
    private var menuView: UIView!
    private var scrollView: UIScrollView!
    private var menuTitleView: UIView!
    private var titleStackView: UIStackView!
    private var indicatorView: UIView!
    
    private var menuHeight: NSLayoutConstraint!
    private var menuTitles: [String] = [String]()
    private var indicatorOriginsX: [CGFloat] = [CGFloat]()
    private var itemsViewFrameOriginX: [CGFloat] = [CGFloat]()
    
    private var indicatorViewLastOriginX: CGFloat = 0.0
    private var scale: CGFloat!
    private var userDefaultOffsetPage = false
    
    private let moveDuration: TimeInterval = 0.2
    private let realTitleBottomMargin: CGFloat = 6
    private var badgeWidth: CGFloat = 18
    
    // MARK: - Helper
    
    private func addAllSubView() {
        // Menu container
        menuView = UIView()
        
        
        // Title container
        menuTitleView = UIView()
        titleStackView = UIStackView()
        
        // Indicator
        indicatorView = UIView()
        indicatorView.layer.cornerRadius = indicatorHeight/2
        indicatorView.layer.masksToBounds = true
        indicatorView.backgroundColor = indicatorColor
        
        if isTitleViewStyle {
            menuView.backgroundColor = UIColor.clear
            menuTitleView.backgroundColor = UIColor.clear
        } else {
            menuView.backgroundColor = UIColor(red: 204/255.0, green: 204/255.0, blue: 204/255.0, alpha: 1)
            menuTitleView.backgroundColor = menuTitleViewBackgroundColor
        }
        
        // ScrollView
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        if isRedPoint {
            badgeWidth = 6
        }
        
        for i in 0..<menuTitles.count {
            let view = UIView()
            
            let button = UIButton(type: .custom)
            button.tag = i
            button.addTarget(self,
                             action: #selector(contentOffSetXForButton(sender:)),
                             for: .touchUpInside)
            
            let titleLabel = UILabel()
            titleLabel.text = menuTitles[i]
            
            let badgeLabel = UILabel()
            badgeLabel.backgroundColor = UIColor(red: 251/255.0, green: 98/255.0, blue: 100/255.0, alpha: 1)
            badgeLabel.textColor = UIColor.white
            badgeLabel.layer.cornerRadius = badgeWidth/2
            badgeLabel.layer.masksToBounds = true
            badgeLabel.textAlignment = .center
            badgeLabel.isHidden = true
            
            view.addSubview(titleLabel)
            view.addSubview(badgeLabel)
            view.addSubview(button)
            
            redBadgeLabels.append(badgeLabel)
            titleLabels.append(titleLabel)
            buttonItems.append(button)
            titleViews.append(view)
            
            titleStackView.addArrangedSubview(view)
        }
        
        titleStackView.alignment = .fill
        titleStackView.axis = .horizontal
        titleStackView.distribution = .fillEqually
        
        for i in 0 ..< viewItems.count {
            scrollView.addSubview(viewItems[i])
        }
        
        menuTitleView.addSubview(titleStackView)
        menuTitleView.addSubview(indicatorView)
        
        menuView.addSubview(menuTitleView)
        
        if isTitleViewStyle {
        } else {
            self.addSubview(menuView)
        }
        self.addSubview(scrollView)
    }
    
    private func setupConstraints() {
        var all: [NSLayoutConstraint] = []
        
        menuTitleView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // not title view style
        if !isTitleViewStyle {
            menuView.translatesAutoresizingMaskIntoConstraints = false
            
            let menuTop = menuView.topAnchor.constraint(equalTo: topAnchor)
            let menuLeading = menuView.leadingAnchor.constraint(equalTo: leadingAnchor)
            let menuTrailing = menuView.trailingAnchor.constraint(equalTo: trailingAnchor)
            menuHeight = menuView.heightAnchor.constraint(equalToConstant: menuViewHeight)
            
            
            var menuConstraints: [NSLayoutConstraint] = []
            menuConstraints.append(menuTop)
            menuConstraints.append(menuLeading)
            menuConstraints.append(menuTrailing)
            menuConstraints.append(menuHeight)
            
            all += menuConstraints
        }
        
        // Title view
        let titleViewTop = menuTitleView.topAnchor.constraint(equalTo: menuView.topAnchor)
        let titleViewLeading = menuTitleView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor)
        let titleViewTrailing = menuTitleView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor)
        let titleViewBottom = menuTitleView.bottomAnchor.constraint(equalTo: menuView.bottomAnchor, constant: useSeperateLine ? -0.5 : 0)
        
        var titleViewConstraints: [NSLayoutConstraint] = []
        titleViewConstraints.append(titleViewTop)
        titleViewConstraints.append(titleViewLeading)
        titleViewConstraints.append(titleViewTrailing)
        titleViewConstraints.append(titleViewBottom)
        
        // Title stack view
        let titleStackViewTop = titleStackView.topAnchor.constraint(equalTo: menuTitleView.topAnchor)
        let titleStackViewLeading = titleStackView.leadingAnchor.constraint(equalTo: menuTitleView.leadingAnchor)
        let titleStackViewTrailing = titleStackView.trailingAnchor.constraint(equalTo: menuTitleView.trailingAnchor)
        let titleStatckViewBottom = titleStackView.bottomAnchor.constraint(equalTo: menuTitleView.bottomAnchor, constant: -0.5)
        
        var titleStackViewConstraints: [NSLayoutConstraint] = []
        titleStackViewConstraints.append(titleStackViewTop)
        titleStackViewConstraints.append(titleStackViewLeading)
        titleStackViewConstraints.append(titleStackViewTrailing)
        titleStackViewConstraints.append(titleStatckViewBottom)
        
        // Subview in titleStackView
        var titleLabelConstraints: [NSLayoutConstraint] = []
        var titleButtonConstraints: [NSLayoutConstraint] = []
        var badgeLabelConstraints: [NSLayoutConstraint] = []
        for i in 0..<titleStackView.arrangedSubviews.count {
            
            
            titleLabels[i].translatesAutoresizingMaskIntoConstraints = false
            buttonItems[i].translatesAutoresizingMaskIntoConstraints = false
            redBadgeLabels[i].translatesAutoresizingMaskIntoConstraints = false
            
            
            let titleCenterX = titleLabels[i].centerXAnchor.constraint(equalTo: titleViews[i].centerXAnchor)
            let titleCenterY = titleLabels[i].centerYAnchor.constraint(equalTo: titleViews[i].centerYAnchor)
            
            let titleButtonTop = buttonItems[i].topAnchor.constraint(equalTo: titleViews[i].topAnchor)
            let titleButtonBottom = buttonItems[i].bottomAnchor.constraint(equalTo: titleViews[i].bottomAnchor)
            let titleButtonLeading = buttonItems[i].leadingAnchor.constraint(equalTo: titleViews[i].leadingAnchor)
            let titleButtonTrailing = buttonItems[i].trailingAnchor.constraint(equalTo: titleViews[i].trailingAnchor)
            
            let badgeWidth = redBadgeLabels[i].widthAnchor.constraint(equalToConstant: self.badgeWidth)
            let badgeHeight = redBadgeLabels[i].heightAnchor.constraint(equalToConstant: self.badgeWidth)
            let badgeTop = redBadgeLabels[i].topAnchor.constraint(equalTo: titleLabels[i].topAnchor, constant: -5)
            let badgeLeading = redBadgeLabels[i].leadingAnchor.constraint(equalTo: titleLabels[i].trailingAnchor, constant: 2)
            
            titleLabelConstraints.append(titleCenterX)
            titleLabelConstraints.append(titleCenterY)
            
            titleButtonConstraints.append(titleButtonTop)
            titleButtonConstraints.append(titleButtonBottom)
            titleButtonConstraints.append(titleButtonLeading)
            titleButtonConstraints.append(titleButtonTrailing)
            
            badgeLabelConstraints.append(badgeWidth)
            badgeLabelConstraints.append(badgeHeight)
            badgeLabelConstraints.append(badgeTop)
            badgeLabelConstraints.append(badgeLeading)
        }
        
        // Scroll view
        var scrollViewConstraints: [NSLayoutConstraint] = []
        let scrollViewTop = scrollView.topAnchor.constraint(equalTo: isTitleViewStyle ? topAnchor : menuView.bottomAnchor)
        let scrollViewLeading = scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let scrollViewTrailing = scrollView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let scrollViewBottom = scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        scrollViewConstraints.append(scrollViewTop)
        scrollViewConstraints.append(scrollViewLeading)
        scrollViewConstraints.append(scrollViewTrailing)
        scrollViewConstraints.append(scrollViewBottom)
        
        // Activate
        all += titleViewConstraints
        all += titleStackViewConstraints
        all += scrollViewConstraints
        all += titleLabelConstraints
        all += titleButtonConstraints
        all += badgeLabelConstraints
        
        NSLayoutConstraint.activate(all)
        
        // Is title view style
        if isTitleViewStyle {  // 最好是设置为两个字的
            menuView.translatesAutoresizingMaskIntoConstraints = false
            // add your views and set up all the constraints
            
            var sumTitleTextCount = 0
            for text in menuTitles {
                sumTitleTextCount += text.count
            }
            
            let itemWidth =  useBadge ? 70 : 50
            let standard = itemWidth * viewItems.count
            let width: CGFloat = min(CGFloat(standard), UIScreen.main.bounds.width - 40)
            menuView.widthAnchor.constraint(equalToConstant: width).isActive = true
            menuView.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            // This is the magic sauce!
            menuView.layoutIfNeeded()
            menuView.sizeToFit()
            
            // Now the frame is set (you can print it out)
            menuView.translatesAutoresizingMaskIntoConstraints = true // make nav bar happy
            managerController?.navigationItem.titleView = menuView
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //        print("\nlayoutSubviews")
        
        resetSubviewsLayoutIfNeeded()
    }
    
    
    private func resetSubviewsLayoutIfNeeded() {
        //        print("resetSubviewsLayoutIfNeeded\n")
        
        var contentSize = scrollView.bounds.size
        contentSize.width = contentSize.width * CGFloat(viewItems.count)
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
        
        let itemWidth: CGFloat = menuView.bounds.width/CGFloat(viewItems.count)
        for i in 0..<viewItems.count {
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
        
        if self.hasShowPages.count > defaultOffsetPage {
            // Notification defaultOffsetPage view controller when first load container
            if self.hasShowPages[defaultOffsetPage] == false {
                
                // Set scrollview offset with container first loaded
                if defaultOffsetPage != defaultSelectedPage {
                    let offset = CGPoint(x: UIScreen.main.bounds.width * CGFloat(defaultOffsetPage), y: 0)
                    scrollView.setContentOffset(offset, animated: false)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.setItemsFirstShowData(index: self.defaultOffsetPage, value: true)
                })
            }
        }
    }
    
    private var hasShowPages: [Bool] = []
    private func setItemsFirstShowData(index: Int, value: Bool) {
        hasShowPages[index] = value
        if value == true {
            delegate?.scrollContainerView?(containerView: self, scrollAt: index, isFirstScrollToIt: true)
        }
    }
    
    private func mutipleTimeScrollTo(index: Int) {
        delegate?.scrollContainerView?(containerView: self, scrollAt: index, isFirstScrollToIt: false)
    }
    
    private var lastIndex = defaultSelectedPage {
        didSet {
            for i in 0..<viewItems.count {
                let color = i == lastIndex ? selectedItemColor : unselectedItemColor
                titleLabels[i].textColor = color
            }
        }
    }
    
    // MARK: - Menu button tapped
    @objc private func contentOffSetXForButton(sender: UIButton){
        let index = sender.tag
        
        let scrollWithAnimation = canScrollWithAnimation(current: index)
        lastIndex = index
        
        let shouldScrollOffset = CGPoint(x: CGFloat(index)*scrollView.bounds.width, y: 0)
        scrollView.setContentOffset(shouldScrollOffset, animated: scrollWithAnimation)
        UIView.animate(withDuration: moveDuration, animations: {
            self.indicatorView.frame.origin.x = self.indicatorOriginsX[index]
            self.indicatorViewLastOriginX = self.indicatorView.frame.origin.x
            
            if self.hasShowPages[index] == false {
                self.setItemsFirstShowData(index: index, value: true)
            } else {
                self.mutipleTimeScrollTo(index: index)
            }
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
            if self.hasShowPages[index] == false {
                self.setItemsFirstShowData(index: index, value: true)
            } else {
                self.mutipleTimeScrollTo(index: index)
            }
        }
        
    }
    
}

