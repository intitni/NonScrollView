import UIKit

class InspectionViewController: UIViewController {
    let scale = 0.6 as CGFloat
    
    let coverLayer = CAShapeLayer()
    let inspecting: UIViewController
    
    init(inspecting: UIViewController, infoView: InfoView) {
        self.inspecting = inspecting
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .white
        addChild(inspecting)
        view.addSubview(inspecting.view)
        inspecting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inspecting.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inspecting.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            inspecting.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            inspecting.view.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        inspecting.view.transform = .init(scaleX: 0.6, y: 0.6)
        
        infoView.alignment = .trailing
        view.addSubview(infoView)
        infoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
            infoView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50)
            ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let path = UIBezierPath(rect: view.bounds)
        let offsetScale = (1 - scale) / 2
        path.append(UIBezierPath(rect: CGRect(x: offsetScale * view.bounds.width,
                                              y: offsetScale * view.bounds.height,
                                              width: scale * view.bounds.width,
                                              height: scale * view.bounds.height)))
        coverLayer.fillColor = UIColor.white.withAlphaComponent(0.8).cgColor
        coverLayer.path = path.cgPath
        coverLayer.fillRule = CAShapeLayerFillRule.evenOdd
        view.layer.addSublayer(coverLayer)
        coverLayer.zPosition = 99999
        
        traceSubviews(of: inspecting.view) { view in view.clipsToBounds = false }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func traceSubviews(of view: UIView, andDo block: (UIView)->Void) {
        block(view)
        for v in view.subviews {
            traceSubviews(of: v, andDo: block)
        }
    }
}

class InfoView: UIStackView {
    class Element<O: NSObject, V>: UILabel {
        var observation: NSKeyValueObservation?
        deinit { observation?.invalidate() }
        init(_ title: String, _ o: O, _ keyPath: KeyPath<O, V>) {
            super.init(frame: .zero)
            observation = o.observe(keyPath, options: [.initial, .new]) { [unowned self] obj, change in
                guard let v = change.newValue else {
                    self.text = "\(title): nil"
                    return
                }
                self.text = "\(title): \(v)"
            }
            font = .systemFont(ofSize: 10)
            textColor = .black
            textAlignment = .right
            backgroundColor = UIColor.white.withAlphaComponent(0.4)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class Title: UILabel {
        init(_ title: String) {
            super.init(frame: .zero)
            text = title
            font = .systemFont(ofSize: 10, weight: .medium)
            textColor = .black
            textAlignment = .right
            backgroundColor = UIColor.white.withAlphaComponent(0.4)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class Gap: UIView {
        init(height: CGFloat) {
            var f = CGRect.zero
            f.size.height = height
            super.init(frame: f)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize { return .init(width: UIView.noIntrinsicMetric, height: bounds.height) }
        override func layoutSubviews() {
            super.layoutSubviews()
            if intrinsicContentSize.height != bounds.height { invalidateIntrinsicContentSize() }
        }
    }
    
    init(_ elements: [UIView]) {
        super.init(frame: .zero)
        elements.forEach(addArrangedSubview)
        axis = .vertical
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
