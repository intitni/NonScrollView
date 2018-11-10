import UIKit
import NonScrollView

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        let v = HeaderSegmentController(
            headerVC: header,
            defaultHeaderHeight: 150,
            segmentControl: SegmentControl(frame: .zero),
            pages: [vc1, vc2, vc3, vc4])
        
        present(v, animated: true, completion: nil)
    }
    
}

class TableViewController: UITableViewController, HeaderSegmentControllerSegmentPageHasScrollView {
    var segmentPageEmbedScrollView: UIScrollView { return tableView }
    
    let numberOfItems: Int
    
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
}
