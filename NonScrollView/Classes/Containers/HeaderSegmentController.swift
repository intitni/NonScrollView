import UIKit

public protocol HeaderSegmentControllerSegmentPageHasScrollView: AnyObject {
    var segmentPageEmbedScrollView: UIScrollView { get }
}

extension HeaderSegmentControllerSegmentPageHasScrollView {
    public var scrollViewContentHeight: CGFloat {
        segmentPageEmbedScrollView.layoutIfNeeded()
        return segmentPageEmbedScrollView.contentSize.height
    }
}

extension SegmentController {
    fileprivate var currentScrollView: UIScrollView? {
        return (currentPageVC as? HeaderSegmentControllerSegmentPageHasScrollView)?.segmentPageEmbedScrollView
    }
    
    fileprivate var segmentControlHeight: CGFloat {
        return vcs.count > 1 ? segmentControl.panelHeight : 0
    }
    
    fileprivate var scrollableContentHeight: CGFloat? {
        currentScrollView?.layoutIfNeeded()
        guard let height = currentScrollView?.contentSize.height else { return nil }
        return height + segmentControlHeight
    }
}

/// Provides a view controller that has a stretchable header above `SegmentController`.
///
/// You have to provide your own implementation of segment control widget that conforms to `SegmentControlType`.
///
/// - important: If you have a scrollable content inside `SegmentController` pages that would interfere with the main scroll view provided by this class, you should conform you page class to `HeaderSegmentControllerSegmentPageHasScrollView` and return that specific scroll view in `segmentPageEmbedScrollView`. `HeaderSegmentController` will take over and control it's scroll behaviour.
///
open class HeaderSegmentController: UIViewController {
    
    /// The main scroll view
    public var scrollView: NonScrollView!
    public let headerVC: UIViewController
    public let segmentController: SegmentController
    
    public var headerHeight: CGFloat { didSet { invalidateLayout() } }
    
    private var segmentControllerOrigin = CGPoint.zero
    private var touchBeginsInSegmentController = false
    private var contentHeightObservation: NSKeyValueObservation?
    private var contentInsetObservation: NSKeyValueObservation?
    
    /// Returns the current displaying page
    private var currentPageVC: UIViewController? {
        return segmentController.currentPageVC
    }
    
    /// Returns the current displaying page's embeded scroll view if exists.
    private var currentScrollView: UIScrollView? {
        return segmentController.currentScrollView
    }
    
    deinit {
        contentHeightObservation?.invalidate()
        contentInsetObservation?.invalidate()
    }
    
    open func invalidateLayout() {
        let offset = calibrateContentOffset()
        scrollView.invalidateLayout()
        updateContentOffset(to: offset)
    }
    
    open func setPages(_ viewControllers: [UIViewController]) {
        segmentController.setViewControllers(viewControllers)
        invalidateLayout()
    }
    
    /// Initailize a `HeaderSegmentController`.
    /// - parameters:
    ///     - headerVC: A view controller for header.
    ///     - maxHeaderHeight: The default height of header view controller.
    ///     - segmentControl: Segment control widget on top of pages.
    ///     - pages: All pages view controllers to display in segment controller.
    public init(
        headerVC: UIViewController,
        defaultHeaderHeight: CGFloat,
        segmentControl: UIControl & SegmentControlType,
        pages: [UIViewController]
    ) {
        self.headerVC = headerVC
        self.headerHeight = defaultHeaderHeight
        segmentController = SegmentController(segmentControl: segmentControl, viewControllers: pages)
        
        super.init(nibName: nil, bundle: nil)
        
        addChild(headerVC)
        addChild(segmentController)
        segmentController.delegate = self
        segmentControllerOrigin = .init(x: 0, y: self.headerHeight)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        for case let v as HeaderSegmentControllerSegmentPageHasScrollView in segmentController.vcs {
            let s = v.segmentPageEmbedScrollView
            s.isScrollEnabled = false
        }
        
        /// In this example, we are only providing a stored frame for segmentController, frame for headerVC can be calculated from it.
        /// There is no updateView blocks because they will be done in recognizer.onChange.
        let layout = NonScrollViewLayout(
            viewPlacers: [
                .init(view: headerVC.view, generateFrame: { [unowned self] ref in
                    return .zero + CGSize(width: ref.size.width, height: self.segmentControllerOrigin.y)
                }),
                .init(view: segmentController.view, generateFrame: { [unowned self] ref in
                    return .init(origin: self.segmentControllerOrigin, size: ref.size)
                }),
            ],
            contentSizeGenerator: {
                [unowned self] ref in
                if let height = self.segmentController.scrollableContentHeight {
                    return CGSize(width: ref.size.width,
                                  height: max(ref.size.height + self.headerHeight, height + self.headerHeight))
                }
                // If current page is not scrollable
                return CGSize(width: ref.size.width, height: ref.size.height + self.headerHeight)
        })
        
        scrollView = {
            let it = NonScrollView(frame: .zero, layout: layout)
            if #available(iOS 11.0, *) {
                it.contentInsetAdjustmentBehavior = .never
            } else {
                automaticallyAdjustsScrollViewInsets = false
            }
            it.alwaysBounceVertical = true
            it.delegate = self
            it.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(it)
            NSLayoutConstraint.activate([
                it.topAnchor.constraint(equalTo: self.view.topAnchor),
                it.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                it.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                it.rightAnchor.constraint(equalTo: self.view.rightAnchor)
                ])
            
            return it
        }()
        
        observeCurrentScrollViewContentHeightIfExists()
        
        // I am using a lot of `calibrateContentOffset` in this observation because I JUST CAN'T GET IT RIGHT!
        scrollView.recognizer.onChange = { [unowned self] rec in
            enum ScrollDirection { case scrollDown, scrollUp }

            let translationY = rec.translation.y
            guard translationY != 0 else { return }
            let hitTop = self.segmentControllerOrigin.y <= 0
            let scrollDirection = translationY < 0 ? ScrollDirection.scrollUp : .scrollDown

            if case .began = rec.touchState,
                let location = rec.touchLocation(in: self.scrollView) {
                let inside = (self.segmentController.view.frame).contains(location)
                self.touchBeginsInSegmentController = inside
                
                let hitTop = self.segmentControllerOrigin.y <= 0
                let scrollableAtTop = (self.currentScrollView?.contentOffset.y ?? 0) <= 0
                
                switch (hitTop, scrollableAtTop, inside) {
                case (false, false, true): self.convertContentInsetToDefaultMode()
                case (false, false, false): self.convertContentInsetToShortMode()
                default: break
                }
            }
            
            switch (self.currentScrollView, hitTop, scrollDirection) {
            case (let scrollable?, true, .scrollDown):
                
                scrollable.contentOffset += rec.translation
                
            case (let scrollable?, true, .scrollUp):
                
                if scrollable.contentOffset.y > 0 {
                    let newOffset = scrollable.contentOffset + rec.translation
                    scrollable.contentOffset = CGPoint(x: 0, y: max(newOffset.y, 0))
                    if newOffset.y < 0 { // over scroll
                        self.segmentControllerOrigin -= CGPoint(x: 0, y: newOffset.y)
                        self.calibrateContentOffset()
                    }
                } else {
                    let newOrigin = self.segmentControllerOrigin - rec.translation
                    self.segmentControllerOrigin = .init(x: 0, y: max(newOrigin.y, 0))
                }
            
             case (let scrollable?, false, .scrollDown):
                
                let newOrigin = self.segmentControllerOrigin - rec.translation
                let y = newOrigin.y
                self.segmentControllerOrigin = .init(x: 0, y: max(y, 0))
                if y < 0 { // over scroll
                    scrollable.contentOffset -= CGPoint(x: 0, y: y)
                    self.calibrateContentOffset()
                }
                
            case (let scrollable?, false, .scrollUp):
                
                if scrollable.contentOffset.y > 0 {
                    if self.touchBeginsInSegmentController {
                        let newOffset = scrollable.contentOffset + rec.translation
                        scrollable.contentOffset = CGPoint(x: 0, y: max(newOffset.y, 0))
                        if newOffset.y < 0 { // over scroll
                            self.segmentControllerOrigin -= CGPoint(x: 0, y: newOffset.y)
                            self.calibrateContentOffset()
                        }
                    } else {
                        let newOrigin = self.segmentControllerOrigin - rec.translation
                        self.segmentControllerOrigin = .init(x: 0, y: newOrigin.y)
                    }
                    
                } else {
                    let newOrigin = self.segmentControllerOrigin - rec.translation
                    self.segmentControllerOrigin = .init(x: 0, y: max(newOrigin.y, 0))
                }
                
            case (.none, _, _):
                
                self.segmentControllerOrigin = .init(x: 0, y: max(self.headerHeight - rec.contentOffset.y, 0))
                
            }
        }
    }
    
    private func observeCurrentScrollViewContentHeightIfExists() {
        contentHeightObservation?.invalidate()
        contentHeightObservation = currentScrollView?.observe(\.contentSize, options: [.new, .old, .initial]) { [unowned self] s, change in
            if let old = change.oldValue, let new = change.newValue, old === new { return }
            self.scrollView.invalidateLayout()
            self.calibrateContentOffset()
        }
        contentInsetObservation?.invalidate()
        contentInsetObservation = currentScrollView?.observe(\.contentSize, options: [.new, .old, .initial]) { [unowned self] s, change in
            if let old = change.oldValue, let newInset = change.newValue, old === newInset { return }
            var ci = self.scrollView.contentInset
            ci.bottom = s.contentInset.bottom
            self.scrollView.contentInset = ci
        }
    }

    /// Calibrates contentOffset of outter scrollView to match that of scrollable page.
    @discardableResult
    private func calibrateContentOffset() -> CGPoint {
        let segmentOffsetY = headerHeight - segmentControllerOrigin.y
        let scrollableContentOffsetY = currentScrollView?.contentOffset.y ?? 0
        let offset = CGPoint(x: 0, y: segmentOffsetY + scrollableContentOffsetY)
        updateContentOffset(to: offset)
        return offset
    }
    
    /// Silently update contentOffset of scrollView
    private func updateContentOffset(to offset: CGPoint) {
        scrollView.silentlyUpdateContentOffset(to: offset)
    }
    
    private func convertContentInsetToShortMode() {
        let preservedContentOffset = scrollView.contentOffset
        var contentInset = scrollView.contentInset
        contentInset.top = -(self.currentScrollView?.contentOffset.y ?? 0)
        guard contentInset != scrollView.contentInset else { return }
        scrollView.contentInset = contentInset
        scrollView.silentlyUpdateContentOffset(to: preservedContentOffset)
    }
    
    private func convertContentInsetToDefaultMode() {
        let preservedContentOffset = scrollView.contentOffset
        var contentInset = scrollView.contentInset
        contentInset.top = 0
        guard contentInset != scrollView.contentInset else { return }
        scrollView.contentInset = contentInset
        scrollView.silentlyUpdateContentOffset(to: preservedContentOffset)
    }
}

extension HeaderSegmentController: SegmentControllerDelegate {
    
    open func segmentControllerDidScroll(toPageIndex pageIndex: Int) {
        invalidateLayout()
        observeCurrentScrollViewContentHeightIfExists()
    }
    
    open func segmentControllerWillScroll(fromPageIndex pageIndex: Int) {
        // do nothing
    }
}

extension HeaderSegmentController: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        calibrateContentOffset()
    }
}
