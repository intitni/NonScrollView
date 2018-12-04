import UIKit
import NonScrollView

class SegmentControl: UIControl, PassiveSegmentControlType, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var panelHeight: CGFloat { return 44 }
    let identifier = "cell"
    
    weak var delegate: SegmentControlTypeDelegate? = nil
    weak var dataSource: SegmentControlTypeDataSource? = nil
    
    var collectionView: UICollectionView!
    var highlightedIndex = 0
    
    var highlighter: UIView!
    
    var leftConstraintOfHighlighter: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        collectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            let it = UICollectionView(frame: frame, collectionViewLayout: layout)
            it.dataSource = self
            it.delegate = self
            it.register(UICollectionViewCell.self, forCellWithReuseIdentifier: identifier)
            addSubview(it)
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.topAnchor.constraint(equalTo: topAnchor),
                it.bottomAnchor.constraint(equalTo: bottomAnchor),
                it.leftAnchor.constraint(equalTo: leftAnchor),
                it.rightAnchor.constraint(equalTo: rightAnchor)
                ])
            return it
        }()
        
        highlighter = {
            let it = UIView()
            addSubview(it)
            it.translatesAutoresizingMaskIntoConstraints = false
            it.backgroundColor = .darkGray
            leftConstraintOfHighlighter = it.leftAnchor.constraint(equalTo: leftAnchor, constant: 0)
            NSLayoutConstraint.activate([
                it.bottomAnchor.constraint(equalTo: bottomAnchor),
                leftConstraintOfHighlighter,
                it.widthAnchor.constraint(equalToConstant: 20),
                it.heightAnchor.constraint(equalToConstant: 10)
                ])
            return it
        }()
    }
    
    func highlightItem(atIndex index: Int, animated: Bool) {
        highlightedIndex = index
        leftConstraintOfHighlighter.constant = max(bounds.width / CGFloat(dataSource?.numberOfItem ?? 0), 100) * CGFloat(index)
        collectionView.reloadData()
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: max(bounds.width / CGFloat(dataSource?.numberOfItem ?? 0), 100), height: panelHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.segmentControlDidSelect(itemAtIndex: indexPath.row)
        highlightItem(atIndex: indexPath.row, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        cell.contentView.backgroundColor = .cyan
        if indexPath.row == highlightedIndex { cell.contentView.backgroundColor = .brown }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfItem ?? 0
    }
}
