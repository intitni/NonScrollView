import UIKit

final class ThreadSafe<A> {
    private var _value: A
    private let queue = DispatchQueue(label: "ThreadSafe")
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        get { return queue.sync { _value } }
        set { queue.sync { _value = newValue } }
    }
}

func ===<F: FloatingPoint>(lhs: F, rhs: F) -> Bool {
    if lhs == rhs { return true }
    var epsilon: F
    if lhs > rhs {
        epsilon = lhs * .ulpOfOne;
    } else {
        epsilon = rhs * .ulpOfOne;
    }
    
    return abs(lhs - rhs) < epsilon;
}

func !==<F: FloatingPoint>(lhs: F, rhs: F) -> Bool {
    return !(lhs === rhs)
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func -=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func ===(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x === rhs.x && lhs.y === rhs.y
    }
    
    static func !==(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return !(lhs === rhs)
    }
}

extension CGSize {
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        return .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    static func +=(lhs: inout CGSize, rhs: CGSize) {
        lhs = .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func -=(lhs: inout CGSize, rhs: CGSize) {
        lhs = .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    static func ===(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width === rhs.width && lhs.height === rhs.height
    }
    
    static func !==(lhs: CGSize, rhs: CGSize) -> Bool {
        return !(lhs === rhs)
    }
}

extension CGRect {
    static func +(lhs: CGRect, rhs: CGPoint) -> CGRect {
        return .init(origin: lhs.origin + rhs, size: lhs.size)
    }
    
    static func -(lhs: CGRect, rhs: CGPoint) -> CGRect {
        return .init(origin: lhs.origin - rhs, size: lhs.size)
    }
    
    static func +(lhs: CGRect, rhs: CGSize) -> CGRect {
        return .init(origin: lhs.origin, size: lhs.size + rhs)
    }
    
    static func -(lhs: CGRect, rhs: CGSize) -> CGRect {
        return .init(origin: lhs.origin, size: lhs.size - rhs)
    }
    
    static func +(lhs: CGRect, rhs: CGRect) -> CGRect {
        return .init(origin: lhs.origin + rhs.origin, size: lhs.size + rhs.size)
    }
    
    static func -(lhs: CGRect, rhs: CGRect) -> CGRect {
        return .init(origin: lhs.origin - rhs.origin, size: lhs.size - rhs.size)
    }
    
    static func +=(lhs: inout CGRect, rhs: CGPoint) {
        lhs = .init(origin: lhs.origin + rhs, size: lhs.size)
    }
    
    static func -=(lhs: inout CGRect, rhs: CGPoint) {
        lhs = .init(origin: lhs.origin - rhs, size: lhs.size)
    }
    
    static func +=(lhs: inout CGRect, rhs: CGSize) {
        lhs = .init(origin: lhs.origin, size: lhs.size + rhs)
    }
    
    static func -=(lhs: inout CGRect, rhs: CGSize) {
        lhs = .init(origin: lhs.origin, size: lhs.size - rhs)
    }
    
    static func +=(lhs: inout CGRect, rhs: CGRect) {
        lhs = .init(origin: lhs.origin + rhs.origin, size: lhs.size + rhs.size)
    }
    
    static func -=(lhs: inout CGRect, rhs: CGRect) {
        lhs = .init(origin: lhs.origin - rhs.origin, size: lhs.size - rhs.size)
    }
    
    static func ===(lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.size === rhs.size && lhs.origin === rhs.origin
    }
    
    static func !==(lhs: CGRect, rhs: CGRect) -> Bool {
        return !(lhs === rhs)
    }
}

class DisposableBag {
    var disposables: [NSKeyValueObservation] = []
    deinit { disposables.forEach { $0.invalidate() } }
}

extension NSKeyValueObservation {
    func addTo(_ disposableBag: DisposableBag) {
        disposableBag.disposables.append(self)
    }
}
