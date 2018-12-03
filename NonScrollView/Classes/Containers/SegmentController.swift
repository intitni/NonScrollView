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
    public var computedCurrentPageIndex: Int {
        let page = max(0, Int(floor(pageOffset)))
        return min(max(0, page), vcs.endIndex - 1)
    }
    
    public var currentPageVC: UIViewController {
        return vcs[currentPageIndex]
    }

    private var scrollView: UIScrollView!
    private var collectionView: UICollectionView!
    private let flowLayout =  UICollectionViewFlowLayout()
    
    private var pageOffset: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let width = collectionView.bounds.size.width
        let offset = collectionView.contentOffset.x / (width == 0 ? 1 : width)
        return offset
    }
    private let disposables = DisposableBag()
    
    public init(segmentControl: UIControl & SegmentControlType, viewControllers: [UIViewController]) {
        self.vcs = viewControllers
        self.segmentControl = segmentControl
        super.init(nibName: nil, bundle: nil)
        viewControllers.forEach(self.addChild)
        segmentControl.delegate = self
        segmentControl.dataSource = self
    }
    
    public func setViewControllers(_ viewControllers: [UIViewController]) {
        vcs.forEach { $0.removeFromParent() }
        vcs = viewControllers
        viewControllers.forEach(self.addChild)
        collectionView.reloadData()
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
        collectionView = {
            let it = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumLineSpacing = 0
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.sectionInset = .zero
            if #available(iOS 11.0, *) {
                it.insetsLayoutMarginsFromSafeArea = false
            }
            it.alwaysBounceHorizontal = false
            it.backgroundColor = .white
            it.isPagingEnabled = true
            it.dataSource = self
            it.delegate = self
            it.register(ViewControllerCell.self, forCellWithReuseIdentifier: Constants.cellIndentifier)
            view.addSubview(it)
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.topAnchor.constraint(equalTo: segmentControl.bottomAnchor),
                it.leftAnchor.constraint(equalTo: view.leftAnchor),
                it.rightAnchor.constraint(equalTo: view.rightAnchor),
                it.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                ])
            return it
        }()
        
        collectionView.observe(\.contentOffset) { [weak self] _, _ in
            self?.scrollViewContentOffsetDidChange()
        } .addTo(disposables)
    }
}

// MARK: - UICollectionViewDataSource

extension SegmentController: UICollectionViewDataSource {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vcs.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellIndentifier, for: indexPath)
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let vc = vcs[indexPath.row]
        (cell as? ViewControllerCell)?.configure(with: vc)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SegmentController: UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.segmentControllerWillScroll(fromPageIndex: currentPageIndex)
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentPageIndex = computedCurrentPageIndex
        delegate?.segmentControllerDidScroll(toPageIndex: currentPageIndex)
        (segmentControl as? PassiveSegmentControlType)?.highlightItem(atIndex: currentPageIndex, animated: true)
    }
    
    open func scrollViewContentOffsetDidChange() {
        (segmentControl as? ProactiveSegmentControlType)?.updateHighlighterOffset(toMatchPageOffset: pageOffset)
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let min = 0 as CGFloat
        let max = CGFloat(numberOfItem - 1) * collectionView.bounds.width
        if scrollView.contentOffset.x < min {
            scrollView.contentOffset = .init(x: min, y: 0)
        }
        
        if scrollView.contentOffset.x > max {
            scrollView.contentOffset = .init(x: max, y: 0)
        }
    }
}

// MARK: - SegmentControlTypeDelegate

extension SegmentController: SegmentControlTypeDelegate {
    open func segmentControlDidSelect(itemAtIndex index: Int) {
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }
}

// MARK: - SegmentControlTypeDelegate

extension SegmentController: SegmentControlTypeDataSource {
    open var titles: [String] { return vcs.map { $0.title ?? "" } }
    open var numberOfItem: Int { return vcs.count }
}

// MARK: - ViewControllerCell

fileprivate class ViewControllerCell: UICollectionViewCell {
    func configure(with vc: UIViewController) {
        contentView.backgroundColor = .white
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            vc.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            vc.view.rightAnchor.constraint(equalTo: contentView.rightAnchor)
            ])
        contentView.layoutIfNeeded()
    }
}
