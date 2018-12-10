import Foundation

public protocol ScrollViewChainControllerChainable: AnyObject {
    var chainingScrollView: UIScrollView { get }
}

fileprivate extension ScrollViewChainControllerChainable {
    var contentHeight: CGFloat {
        return chainingScrollView.contentSize.height
    }
    
    var contentOffset: CGPoint {
        get { return chainingScrollView.contentOffset }
        set { chainingScrollView.contentOffset = newValue }
    }
}

/// Provides a container controller that chains two view controllers that conforms to `ScrollViewChainControllerChainable`.
///
/// ScrollViewChainController will disable and take over chainable scroll view's scroll behaviour.
open class ScrollViewChainController: UIViewController {
    public typealias ChainableVC = UIViewController & ScrollViewChainControllerChainable
    /// The main scroll view
    public var scrollView: NonScrollView!
    
    private let chainA: ChainableVC
    private let chainB: ChainableVC
    
    private var chainAHeight: CGFloat = 0
    private var chainBHeight: CGFloat = 0
    
    private var disposables = DisposableBag()
    
    public init(chainA: ChainableVC, chainB: ChainableVC) {
        self.chainA = chainA
        self.chainB = chainB
        super.init(nibName: nil, bundle: nil)
        
        addChild(chainA)
        addChild(chainB)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        chainA.chainingScrollView.isScrollEnabled = false
        chainB.chainingScrollView.isScrollEnabled = false

        let layout = NonScrollViewLayout(
            viewPlacers: [
                .init(view: chainA.view,
                      generateFrame: { [unowned self] ref in
                        
                        let offsetY = ref.offset.y
                        let y = max(0, self.chainAHeight - ref.size.height) - offsetY
                        let potentialOffsetY = min(ref.offset.y, max(0, self.chainAHeight - ref.size.height))
                        return CGRect(origin: .init(x: 0, y: min(y, 0)),
                                      size: CGSize(width: ref.size.width,
                                                   height: min(ref.size.height, self.chainAHeight + max(0, -potentialOffsetY))))
                        
                    }, updateView: { [unowned self] ref in
                        
                        self.chainA.contentOffset = CGPoint(
                            x: 0,
                            y: min(ref.offset.y, max(0, self.chainAHeight - ref.size.height)))
                        
                }),
                .init(view: chainB.view,
                      generateFrame: { [unowned self] ref in
                        
                        let chainAMaxY = self.chainA.view.frame.maxY - ref.offset.y
                        return CGRect(origin: .init(x: 0, y: max(0, chainAMaxY)),
                                      size: CGSize(width: ref.size.width,
                                                   height: ref.size.height))
                        
                    }, updateView: { [unowned self] ref in
                        
                        let offsetY = ref.offset.y
                        
                        if offsetY > self.chainAHeight {
                            self.chainB.contentOffset = ref.offset - .init(x: 0, y: max(0, self.chainAHeight))
                        } else {
                            self.chainB.contentOffset = .zero
                        }
                        
                })
            ],
            contentSizeGenerator: {
                [unowned self] ref in
                self.chainA.chainingScrollView.layoutIfNeeded()
                self.chainB.chainingScrollView.layoutIfNeeded()
                self.chainAHeight = self.chainA.contentHeight
                self.chainBHeight = self.chainB.contentHeight
                let height = self.chainAHeight + self.chainBHeight
                return CGSize(width: ref.size.width, height: height)
        })

        scrollView = {
            let it = NonScrollView(frame: .zero, layout: layout)
            if #available(iOS 11.0, *) {
                it.contentInsetAdjustmentBehavior = .never
            }
            it.alwaysBounceVertical = true
            it.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(it)
            NSLayoutConstraint.activate([
                it.topAnchor.constraint(equalTo: view.topAnchor),
                it.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                it.leftAnchor.constraint(equalTo: view.leftAnchor),
                it.rightAnchor.constraint(equalTo: view.rightAnchor)
                ])
            
            return it
        }()
        
        observeScrollViewContentSizeChange()
    }
    
    private func observeScrollViewContentSizeChange() {
        chainA.chainingScrollView.observe(\.contentSize) { [unowned self] _, _ in
            self.scrollView.invalidateLayout()
        } .addTo(disposables)
        
        chainB.chainingScrollView.observe(\.contentSize) { [unowned self] _, _ in
            self.scrollView.invalidateLayout()
        } .addTo(disposables)
    }
}
