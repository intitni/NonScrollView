import UIKit
import NonScrollView



class ViewController: UIViewController {
    
    var obs: NSKeyValueObservation?
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
        super.viewDidAppear(animated)
        
        let alert = UIAlertController(title: "Choose Type", message: nil, preferredStyle: .actionSheet)
        
        let addButtonToViewController: (UIViewController)->Void = { [unowned self] vc in
            vc.view.addSubview(self.button)
            self.button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.button.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 10),
                self.button.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: 10)
                ])
        }
        
        let headerSegmentControllerAction = UIAlertAction(title: "HeaderSegmentController", style: .default) {
            [unowned self] _ in
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
            
            self.obs = header.view.observe(\.frame) { view, _ in
                headerLabel.text = "\(view.frame.height)"
            }
            
            let v = HeaderSegmentController(
                headerVC: header,
                defaultHeaderHeight: 250,
                segmentControl: SegmentControl(frame: .zero),
                pages: [vc1, vc2, vc3, vc4])
            
            addButtonToViewController(v)
            
            self.present(v, animated: true, completion: nil)
        }
        
        let scrollViewChainControllerAction = UIAlertAction(title: "ScrollViewChainController", style: .default) {
            [unowned self] _ in
            let vc1 = TableViewController(numberOfItems: 20)
            vc1.view.backgroundColor = .green
            let vc2 = TableViewController(numberOfItems: 30)
            vc2.view.backgroundColor = .yellow
            
            let v = ScrollViewChainController(chainA: vc1, chainB: vc2)
            
            addButtonToViewController(v)
            
            self.present(v, animated: true, completion: nil)
        }
        
        alert.addAction(headerSegmentControllerAction)
        alert.addAction(scrollViewChainControllerAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func handleButtonTap() {
        dismiss(animated: true, completion: nil)
    }
}

class TableViewController: UITableViewController {
    var numberOfItems: Int
    
    init(numberOfItems: Int) {
        self.numberOfItems = numberOfItems
        super.init(style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "c")
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
        return CGFloat(indexPath.row % 4 + 2) * 30
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        numberOfItems += [-1, 1].randomElement()! * (3...5).randomElement()!
        tableView.reloadData()
    }
}

extension TableViewController: HeaderSegmentControllerSegmentPageHasScrollView {
    var segmentPageEmbedScrollView: UIScrollView { return tableView }
}

extension TableViewController: ScrollViewChainControllerChainable {
    var chainingScrollView: UIScrollView { return tableView }
}
