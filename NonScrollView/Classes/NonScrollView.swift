import UIKit

// MARK: - NonScrollViewScrollRecognizer

/// Treats `NonScrollView`'s `contentOffset` as touches.
public final class NonScrollViewScrollRecognizer {
    public var onChange: ((NonScrollViewScrollRecognizer)->Void)? = nil
    public var state: UIGestureRecognizer.State = .possible
    public var lastContentOffset: CGPoint = .zero
    public var contentOffset: CGPoint = .zero
    public var touches: Set<UITouch>?
    public var translation: CGPoint { return contentOffset - lastContentOffset }
    
    public func touchLocation(in view: UIView?) -> CGPoint? {
        return touches?.first?.location(in: view)
    }
    
    fileprivate func updateContentOffset(to offset: CGPoint) {
        lastContentOffset = contentOffset
        contentOffset = offset
        onChange?(self)
    }
}

// MARK: - NonScrollViewLayout

/// Provides information for NonScrollView to layout it's subviews.
public final class NonScrollViewLayout {
    public struct FrameOfReference {
        public let previousOffset: CGPoint
        public let offset: CGPoint
        public let size: CGSize
        public var translation: CGPoint { return offset - previousOffset }
    }
    
    /// Provides a view and the way to layout it, in frame of reference in coordinate of visible part of `NonScrollView`.
    public class ViewPlacer {
        public let view: UIView
        public let updateViewAndGenerateViewFrame: (FrameOfReference) -> CGRect
        
        /// Initialize a `ViewPlacer`.
        ///
        /// - parameter view: The view.
        /// - parameter updateViewAndGenerateFrame: Should return a frame in coordinate of visible part of `NonScrollView`.
        public init(view: UIView, updateViewAndGenerateFrame: @escaping (FrameOfReference) -> CGRect) {
            self.view = view
            self.updateViewAndGenerateViewFrame = updateViewAndGenerateFrame
        }
    }
    
    fileprivate let viewPlacers: [ViewPlacer]
    fileprivate let generateContentSize: (FrameOfReference) -> CGSize
    public init(viewPlacers: [ViewPlacer], contentSizeGenerator: @escaping (FrameOfReference) -> CGSize) {
        self.viewPlacers = viewPlacers
        self.generateContentSize = contentSizeGenerator
    }
}

// MARK: - NonScrollView

/// `NonScrollView` is not designed to scroll it's subviews directly like it's parent `UIScrollView`.
/// Instead, you need to provide a `layout` rule for it to work. When layout rules are not enough for your complicated layout,
/// you may want to checkout `recognizer` property to observe the contentOffset changes of `NonScrollView`.
/// You can compute the frames outside of this class and pass them back in through `layout`.
///
/// Check `HeaderSegmentController` for example.
public class NonScrollView: UIScrollView {
    /// When `NonScrollViewLayout` is not enough for your complicated layout,
    /// you may want to observe the change of `NonScrollView` through this property.
    public let recognizer = NonScrollViewScrollRecognizer()
    /// Provides views to add as subviews, and the ways to layout them according to current content offset.
    private let layout: NonScrollViewLayout
    
    override public var contentOffset: CGPoint {
        didSet { recognizer.updateContentOffset(to: contentOffset) }
    }
    
    public func invalidateLayout() {
        layoutMappedViews()
        contentSize = layout.generateContentSize(frameOfReference)
    }

    public init(frame: CGRect = .zero, layout: NonScrollViewLayout) {
        self.layout = layout
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    
    private var frameOfReference: NonScrollViewLayout.FrameOfReference {
        return .init(previousOffset: recognizer.lastContentOffset, offset: contentOffset, size: bounds.size)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutMappedViews()
    }
    
    private func layoutMappedViews() {
        for placer in layout.viewPlacers {
            if placer.view.superview != self {
                placer.view.removeFromSuperview()
                addSubview(placer.view)
            }
            let frameInVisible = placer.updateViewAndGenerateViewFrame(frameOfReference)
            let frame = CGRect(origin: frameInVisible.origin + contentOffset,
                               size: frameInVisible.size)
            placer.view.frame = frame
        }
    }
    
    // MARK: Recognizer Update
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        recognizer.state = .began
        recognizer.touches = touches
        super.touchesBegan(touches, with: event)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        recognizer.state = .changed
        recognizer.touches = touches
        super.touchesMoved(touches, with: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        recognizer.state = .ended
        recognizer.touches = touches
        super.touchesEnded(touches, with: event)
        resetRecognizerStateInNextRunLoop()
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        recognizer.state = .cancelled
        recognizer.touches = touches
        super.touchesCancelled(touches, with: event)
        resetRecognizerStateInNextRunLoop()
    }
    
    private func resetRecognizerStateInNextRunLoop() {
        DispatchQueue.main.async() {
            guard [.cancelled, .ended, .failed].contains(self.recognizer.state) else { return }
            self.recognizer.touches = nil
            self.recognizer.state = .possible
        }
    }
}
