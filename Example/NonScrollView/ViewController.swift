import UIKit
import NonScrollView



class ViewController: UIViewController {
    
    var obs: NSKeyValueObservation?
    var exampleObservations: [NSKeyValueObservation] = []
    let button: UIButton = UIButton(type: .custom)
    
    deinit { obs?.invalidate() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
        button.setTitle("BACK", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        exampleObservations.forEach { $0.invalidate() }
        exampleObservations.removeAll()
        
        super.viewDidAppear(animated)
        
        let alert = UIAlertController(title: "Choose Example", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "HeaderSegmentController", style: .default) {
            [unowned self] _ in self.showHeaderSegmentController()
        })
        alert.addAction(UIAlertAction(title: "ScrollViewChainController", style: .default) {
            [unowned self] _ in self.showScrollViewChain()
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func handleButtonTap() {
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController {
    
    private func addButtonToViewController(_ vc: UIViewController) -> Void {
        vc.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            button.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: 10)
            ])
    }
    
    private func addInfoView(_ infoView: UIStackView, to vc: UIViewController) {
        infoView.alignment = .trailing
        vc.view.addSubview(infoView)
        infoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: -10),
            infoView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 50)
            ])
    }
    
    private func showHeaderSegmentController() {
        let vc1 = TableViewController(numberOfItems: 20)
        vc1.view.backgroundColor = .green
        let vc2 = TableViewController(numberOfItems: 30)
        vc2.view.backgroundColor = .yellow
        let vc3 = UIViewController()
        vc3.view.backgroundColor = .blue
        let vc4 = TableViewController(numberOfItems: 2)
        vc4.view.backgroundColor = .orange
        let header = UIViewController()
        header.view.backgroundColor = .purple
        let headerLabel: UILabel = {
            let it = UILabel()
            header.view.addSubview(it)
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.centerXAnchor.constraint(equalTo: header.view.centerXAnchor),
                it.bottomAnchor.constraint(equalTo: header.view.bottomAnchor, constant: -10)
                ])
            return it
        }()
        
        obs = header.view.observe(\.frame) { view, _ in
            headerLabel.text = "\(view.frame.height)"
        }
        
        let v = HeaderSegmentController(
            headerVC: header,
            defaultHeaderHeight: 250,
            segmentControl: SegmentControl(frame: .zero),
            pages: [vc1, vc2, vc3, vc4])
        
        let _ = v.view
        let infoView = InfoView([
            InfoView.Element<UIScrollView, CGPoint>("scrollView offset", v.scrollView, \.contentOffset),
            InfoView.Element<UIScrollView, CGSize>("scrollView contentSize", v.scrollView, \.contentSize),
            InfoView.Element<UIScrollView, CGPoint>("vc1 offset", vc1.tableView, \.contentOffset),
            InfoView.Element<UIScrollView, CGPoint>("vc2 offset", vc2.tableView, \.contentOffset),
            InfoView.Element<UIScrollView, CGPoint>("vc4 offset", vc4.tableView, \.contentOffset)
            ])
        addInfoView(infoView, to: v)
        
        addButtonToViewController(v)
        
        present(v, animated: true, completion: nil)
    }
    
    private func showScrollViewChain() {
        let vc1 = TableViewController(numberOfItems: 5)
        vc1.view.backgroundColor = .green
        let vc2 = TableViewController(numberOfItems: 5)
        vc2.view.backgroundColor = .yellow
        vc2.view.alpha = 0.5
        
        let v = ScrollViewChainController(chainA: vc1, chainB: vc2)
        
        let _ = v.view
        let infoView = InfoView([
            InfoView.Element<UIScrollView, CGPoint>("scrollView offset", v.scrollView, \.contentOffset),
            InfoView.Element<UIScrollView, CGSize>("scrollView contentSize", v.scrollView, \.contentSize),
            InfoView.Element<UIScrollView, CGPoint>("vc1 offset", vc1.tableView, \.contentOffset),
            InfoView.Element<UIScrollView, CGPoint>("vc2 offset", vc2.tableView, \.contentOffset),
            ])
        addInfoView(infoView, to: v)
        
        addButtonToViewController(v)
        
        present(v, animated: true, completion: nil)
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
    
    init(_ elements: [UIView]) {
        super.init(frame: .zero)
        elements.forEach(addArrangedSubview)
        axis = .vertical
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TableViewController: UITableViewController {
    var numberOfItems: Int
    
    init(numberOfItems: Int) {
        self.numberOfItems = numberOfItems
        super.init(style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "c")
        tableView.estimatedRowHeight = 0
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = .zero
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "c", for: indexPath)
        cell.textLabel?.text = "ROW - \(indexPath.row) "
        cell.backgroundColor = view.backgroundColor
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let change = indexPath.row % 2 == 0 ? 1 : -1
        let old = numberOfItems
        numberOfItems += change
        numberOfItems = max(1, numberOfItems)
        
        let iterate: (Int, Int) -> AnyIterator<Int> = {
            var i = $0 - 1
            let end = $1
            return AnyIterator<Int> {
                i += 1
                if i > end { return nil }
                return i
            }
        }
        
        if change > 0 {
            let indices = iterate(old, old + change - 1).map { return IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indices, with: .fade)
        } else if change < 0 {
            let indices = iterate(old + change, old - 1).map { return IndexPath(row: $0, section: 0) }
            tableView.deleteRows(at: indices, with: .fade)
        }
    }
}

extension TableViewController: HeaderSegmentControllerSegmentPageHasScrollView {
    var segmentPageEmbedScrollView: UIScrollView { return tableView }
}

extension TableViewController: ScrollViewChainControllerChainable {
    var chainingScrollView: UIScrollView { return tableView }
}
