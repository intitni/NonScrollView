import UIKit

// MARK: - Protocols

public protocol SegmentControllerDelegate: AnyObject {
    func segmentControllerDidScroll(toPageIndex pageIndex: Int)
    func segmentControllerWillScroll(fromPageIndex pageIndex: Int)
}

public protocol SegmentControlTypeDelegate: AnyObject {
    func segmentControlDidSelect(itemAtIndex index: Int)
}

public protocol SegmentControlTypeDataSource: AnyObject {
    /// Returns titles of all pages
    var titles: [String] { get }
    /// Returns number of pages
    var numberOfItem: Int { get }
}

public protocol SegmentControlType: AnyObject {
    /// Height of segment control
    var panelHeight: CGFloat { get }
    /// Observe actions of segment control. When added to a `SegmentController`, it will be automatically set.
    var delegate: SegmentControlTypeDelegate? { get set }
    /// Provides data to segment control. When added to a `SegmentController`, it will be automatically set.
    var dataSource: SegmentControlTypeDataSource? { get set }
    func reloadData()
}

public protocol PassiveSegmentControlType: SegmentControlType {
    /// Highlight item at index
    func highlightItem(atIndex index: Int, animated: Bool)
}

public protocol ProactiveSegmentControlType: SegmentControlType {
    /// Highlight items proactively according to page offset.
    ///
    /// - parameter pageOffset: from -1 to pageCount
    func updateHighlighterOffset(toMatchPageOffset pageOffset: CGFloat)
}

// MARK: - SegmentController

open class SegmentController: UIViewController {

    enum Constants {
        static let cellIndentifier = "cell"
    }
    
    public weak var delegate: SegmentControllerDelegate?
    public var vcs: [UIViewController]
    public var segmentControl: UIControl & SegmentControlType
    public var currentPageIndex: Int = 0
    
    public var currentPageVC: UIViewController {
        return vcs[currentPageIndex]
    }

    var pageViewController: UIPageViewController!
    var pageScrollView: UIScrollView?
    
    private var pageOffset: CGFloat {
        let base = CGFloat(currentPageIndex)
        guard let scrollView = pageScrollView else { return base }
        let width = scrollView.bounds.size.width
        let offset = scrollView.contentOffset.x / (width == 0 ? 1 : width)
        return offset + base
    }
    
    private let disposables = DisposableBag()
    
    public init(segmentControl: UIControl & SegmentControlType, viewControllers: [UIViewController]) {
        self.vcs = viewControllers
        self.segmentControl = segmentControl
        super.init(nibName: nil, bundle: nil)
        segmentControl.delegate = self
        segmentControl.dataSource = self
    }
    
    public func setViewControllers(_ viewControllers: [UIViewController]) {
        vcs.forEach { $0.removeFromParent() }
        vcs = viewControllers
        segmentControl.reloadData()
        guard let first = viewControllers.first else { return }
        pageViewController?.setViewControllers([first], direction: .forward, animated: false, completion: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        segmentControl = {
            let it = segmentControl
            it.delegate = self
            it.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(it)
            NSLayoutConstraint.activate([
                it.topAnchor.constraint(equalTo: view.topAnchor),
                it.leftAnchor.constraint(equalTo: view.leftAnchor),
                it.rightAnchor.constraint(equalTo: view.rightAnchor),
                it.heightAnchor.constraint(equalToConstant: vcs.count > 0 ? it.panelHeight : 0)
                ])
            it.backgroundColor = .red
            return it
        }()
        
        automaticallyAdjustsScrollViewInsets = false
        pageViewController = {
            let it = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            it.dataSource = self
            it.delegate = self
            
            view.addSubview(it.view)
            it.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.view.topAnchor.constraint(equalTo: segmentControl.bottomAnchor),
                it.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                it.view.rightAnchor.constraint(equalTo: view.rightAnchor),
                it.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                ])
            
            for case let scrollView as UIScrollView in it.view.subviews {
                pageScrollView = scrollView
                scrollView.observe(\.contentOffset) { [weak self] _, _ in
                    self?.scrollViewContentOffsetDidChange()
                } .addTo(disposables)
                break
            }
            
            if let first = vcs.first {
                it.setViewControllers([first], direction: .forward, animated: false, completion: nil)
            }
            
            return it
        }()
    }
}

// MARK: - UIPageViewControllerDataSource

extension SegmentController: UIPageViewControllerDataSource {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = vcs.firstIndex(of: viewController), index < vcs.endIndex - 1 else { return nil }
        return vcs[index + 1]
    }
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = vcs.firstIndex(of: viewController), index > 0 else { return nil }
        return vcs[index - 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension SegmentController: UIPageViewControllerDelegate {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]
    ) {
        delegate?.segmentControllerWillScroll(fromPageIndex: currentPageIndex)
    }
    
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed else { return }
        guard let currentViewController = pageViewController.viewControllers?.first else { return }
        guard let index = vcs.firstIndex(of: currentViewController) else { return }
        
        currentPageIndex = index
        delegate?.segmentControllerDidScroll(toPageIndex: index)
        (segmentControl as? ProactiveSegmentControlType)?.updateHighlighterOffset(toMatchPageOffset: pageOffset)
        (segmentControl as? PassiveSegmentControlType)?.highlightItem(atIndex: index, animated: true)
    }
}

extension SegmentController: UIScrollViewDelegate {
    public func scrollViewContentOffsetDidChange() {
        (segmentControl as? ProactiveSegmentControlType)?.updateHighlighterOffset(toMatchPageOffset: pageOffset)
    }
}

// MARK: - SegmentControlTypeDelegate

extension SegmentController: SegmentControlTypeDelegate {
    public func segmentControlDidSelect(itemAtIndex index: Int) {
        guard currentPageIndex != index else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentPageIndex ? .forward : .reverse
        let vc = vcs[index]
        delegate?.segmentControllerWillScroll(fromPageIndex: currentPageIndex)
        currentPageIndex = index
        pageViewController.setViewControllers([vc], direction: direction, animated: true) { [unowned self] completed in
            guard completed else { return }
            self.delegate?.segmentControllerDidScroll(toPageIndex: index)
        }
    }
}

// MARK: - SegmentControlTypeDelegate

extension SegmentController: SegmentControlTypeDataSource {
    open var titles: [String] { return vcs.map { $0.title ?? "" } }
    open var numberOfItem: Int { return vcs.count }
}
