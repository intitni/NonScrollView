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

open class ScrollViewChainController: UIViewController {
    public typealias ChainableVC = UIViewController & ScrollViewChainControllerChainable
    /// The main scroll view
    public var scrollView: NonScrollView!
    
    private let chainA: ChainableVC
    private let chainB: ChainableVC
    
    var chainAHeight: CGFloat = 0
    var chainBHeight: CGFloat = 0
    
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

        scrollView = {
            let layout = NonScrollViewLayout(
                viewPlacers: [
                    .init(view: chainA.view,
                          generateFrame: { [unowned self] ref in
                            let offsetY = ref.offset.y
                            let y = self.chainAHeight - offsetY - ref.size.height
                            return CGRect(origin: .init(x: 0, y: min(y, 0)), size: ref.size)
                        }, updateView: { [unowned self] ref in
                            self.chainA.contentOffset = CGPoint(x: 0,
                                                                y: min(ref.offset.y,
                                                                       self.chainAHeight - ref.size.height))
                        }),
                    .init(view: chainB.view,
                          generateFrame: { [unowned self] ref in
                            let offsetY = ref.offset.y
                        
                            if offsetY > self.chainAHeight {
                                return CGRect(
                                    origin: .init(x: 0, y: max(self.chainAHeight - offsetY, 0)),
                                    size: ref.size)
                            } else if offsetY > self.chainAHeight - ref.size.height {
                                return CGRect(
                                    origin: .init(x: 0, y: max(self.chainAHeight - offsetY, 0)),
                                    size: ref.size)
                            } else {
                                return CGRect(origin: .init(x: 0, y: ref.size.height), size: ref.size)
                            }
                        }, updateView: { [unowned self] ref in
                            let offsetY = ref.offset.y
                            
                            if offsetY > self.chainAHeight {
                                self.chainB.contentOffset = ref.offset - .init(x: 0, y: self.chainAHeight - ref.size.height)
                            } else if offsetY > self.chainAHeight - ref.size.height {
                                self.chainB.contentOffset = .zero
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
                    return CGSize(width: ref.size.width, height: height - ref.size.height)
                })
            
            let it = NonScrollView(frame: .zero, layout: layout)
            if #available(iOS 11.0, *) {
                it.contentInsetAdjustmentBehavior = .never
            }
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
