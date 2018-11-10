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
    
    fileprivate var scrollableContentHeight: CGFloat? {
        currentScrollView?.layoutIfNeeded()
        guard let height = currentScrollView?.contentSize.height else { return nil }
        return height
             + (vcs.count > 1
                ? segmentControl.height
                : 0)
    }
}

/// Provides a view controller that has a stretchable header above `SegmentController`.
///
/// You have to provide your own implementation of segment control widget that conforms to `SegmentControlType`.
///
/// - important: If you have a scrollable content inside `SegmentController` pages
/// that would interfere with the main scroll view provided by this class,
/// you should conform you page class to `HeaderSegmentControllerSegmentPageHasScrollView`
/// and return that specific scroll view in `segmentPageEmbedScrollView`.
/// `HeaderSegmentController` will take over and control it's scroll behaviour.
///
open class HeaderSegmentController: UIViewController {
    
    /// The main scroll view
    public var scrollView: NonScrollView!
    public let headerVC: UIViewController
    public let segmentController: SegmentController
    
    public var defaultHeaderHeight: CGFloat { didSet { invalidateLayout() } }
    
    private var cachedContentOffset = [Int: CGPoint]()
    private var cachedGap = [Int: CGFloat]()
    
    private var segmentControllerFrame = CGRect.zero
    
    private var contentHeightObservation: NSKeyValueObservation?
    
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
    }
    
    open func invalidateLayout() {
        scrollView.invalidateLayout()
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
        self.defaultHeaderHeight = defaultHeaderHeight
        segmentController = SegmentController(segmentControl: segmentControl, viewControllers: pages)
        
        super.init(nibName: nil, bundle: nil)
        
        addChild(headerVC)
        addChild(segmentController)
        segmentController.delegate = self
        segmentControllerFrame = CGRect(x: 0, y: self.defaultHeaderHeight, width: 0, height: 0)
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
        
        scrollView = {
            let layout = NonScrollViewLayout(
                viewPlacers: [
                    .init(view: headerVC.view, updateViewAndGenerateFrame: {
                        [unowned self] ref in
                        return .zero + CGSize(width: ref.size.width, height: self.segmentControllerFrame.origin.y)
                    }),
                    .init(view: segmentController.view, updateViewAndGenerateFrame: {
                        [unowned self] ref in
                        return self.segmentControllerFrame + ref.size
                    }),
                ],
                contentSizeGenerator: {
                    [unowned self] ref in
                    if let height = self.segmentController.scrollableContentHeight {
                        return CGSize(width: ref.size.width,
                                      height: max(ref.size.height - self.defaultHeaderHeight, height + self.defaultHeaderHeight))
                    }
                    return CGSize(width: ref.size.height, height: ref.size.height)
            })
            
            let it = NonScrollView(frame: .zero, layout: layout)
            it.alwaysBounceVertical = true
            it.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(it)
            NSLayoutConstraint.activate([
                it.topAnchor.constraint(equalTo: self.view.topAnchor),
                it.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                it.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                it.rightAnchor.constraint(equalTo: self.view.rightAnchor)
                ])
            
            return it
        }()
        
        observeCurrentScrollViewContentHeightIfExists()
        
        var touchBeginsInSegmentController = NSNumber(value: false)
        scrollView.recognizer.onChange = { [unowned self] rec in
            let translationY = rec.translation.y
            guard translationY != 0 else { return }
            let pullDown = translationY < 0
            let pullUp = translationY > 0
            let hitTop = self.segmentControllerFrame.origin.y <= 0
            
            if case .began = rec.state,
                let location = rec.touchLocation(in: self.view) {
                let inside = self.segmentControllerFrame.contains(location)
                touchBeginsInSegmentController = NSNumber(value: inside)
            }
            
            switch (self.currentScrollView, hitTop) {
            case (.some(let scrollable), true):
                
                if pullDown {
                    if scrollable.contentOffset.y > 0, touchBeginsInSegmentController.boolValue {
                        let newOffset = scrollable.contentOffset + rec.translation
                        scrollable.contentOffset = CGPoint(x: 0, y: max(newOffset.y, 0))
                        if newOffset.y < 0 { // over scroll
                            self.segmentControllerFrame -= CGPoint(x: 0, y: newOffset.y)
                        }
                    } else {
                        let newFrame = self.segmentControllerFrame - rec.translation
                        self.segmentControllerFrame = CGRect(origin: .init(x: 0, y: max(newFrame.origin.y, 0)), size: .zero)
                    }
                } else {
                    scrollable.contentOffset += rec.translation
                }
                
             case (.some(let scrollable), false):
                
                if pullUp {
                    let newFrame = self.segmentControllerFrame - rec.translation
                    let y = newFrame.origin.y
                    self.segmentControllerFrame = CGRect(origin: .init(x: 0, y: max(y, 0)), size: .zero)
                    if y < 0 { // over scroll
                        scrollable.contentOffset -= CGPoint(x: 0, y: y)
                    }
                } else {
                    if scrollable.contentOffset.y > 0 {
                        scrollable.contentOffset += rec.translation
                    } else {
                        let newOffset = scrollable.contentOffset + rec.translation
                        scrollable.contentOffset = CGPoint(x: 0, y: max(newOffset.y, 0))
                        if newOffset.y < 0 { // over scroll
                            self.segmentControllerFrame -= CGPoint(x: 0, y: newOffset.y)
                        }
                    }
                }
                
            case (.none, _):
                
                let f = self.segmentControllerFrame - rec.translation
                self.segmentControllerFrame = CGRect(origin: .init(x: 0, y: max(f.origin.y, 0)), size: .zero)
                
            }
        }
    }
}

extension HeaderSegmentController: SegmentControllerDelegate {
    private func observeCurrentScrollViewContentHeightIfExists() {
        contentHeightObservation?.invalidate()
        contentHeightObservation = currentScrollView?.observe(\.contentSize) { [unowned self] _, _ in
            self.scrollView.invalidateLayout()
        }
    }
    
    open func segmentControllerDidScroll(toPageIndex pageIndex: Int) {
        let offset = cachedContentOffset[pageIndex] ?? .zero
        let calibrated = CGPoint(
            x: 0,
            y: offset.y + (cachedGap[pageIndex] ?? defaultHeaderHeight) - segmentControllerFrame.origin.y)
        scrollView.recognizer.lastContentOffset = calibrated
        scrollView.recognizer.contentOffset = calibrated
        scrollView.contentOffset = calibrated
        scrollView.invalidateLayout()
        scrollView.contentOffset = calibrated
        
        observeCurrentScrollViewContentHeightIfExists()
    }
    
    open func segmentControllerWillScroll(fromPageIndex pageIndex: Int) {
        cachedContentOffset[pageIndex] = scrollView.contentOffset
        cachedGap[pageIndex] = segmentControllerFrame.origin.y
    }
}
