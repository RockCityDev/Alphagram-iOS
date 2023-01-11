
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import SnapKit
import TelegramPresentationData
import SDWebImage

public protocol TBSegmentItem {
    func selectedIcon() -> String
    func unSelectedIcon() -> String
    func iconImage() -> String?
    func title() -> String
}

public class TBSegmentNode: ASDisplayNode {
    private let preWidth: CGFloat
    private let preItemHeight: CGFloat
    private let titleNode: ASTextNode
    private let closeNode: ASButtonNode
    private let tableView: UITableView
    
    private var items = [TBSegmentItem]()
    
    public var closeEvent: (()->())?
    public var selectedSegmentEvent: ((TBSegmentItem) -> ())?
    
    private var selectedIndex: Int = 0
    
    public init(preWidth: CGFloat = UIScreen.main.bounds.width - 70, preItemHeight: CGFloat = 56) {
        self.preWidth = preWidth
        self.preItemHeight = preItemHeight
        self.titleNode = ASTextNode()
        self.closeNode = ASButtonNode()
        self.tableView = UITableView(frame: .zero, style: .plain)
        super.init()
        self.backgroundColor = UIColor.white
    }
    
    
    public override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.closeNode.addTarget(self, action: #selector(closeButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.closeNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.addSubnode(self.closeNode)
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.allowsSelection = true
        self.tableView.register(TBSegmentItemCell.self, forCellReuseIdentifier: String(describing: TBSegmentItemCell.self))
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .never
        }
        self.view.addSubview(self.tableView)
    }
    
    public func updateSegment(title: String, items: [TBSegmentItem], selectedIndex: Int = 0) -> CGSize {
        self.titleNode.attributedText = NSAttributedString(string: title, font: Font.medium(13), textColor: UIColor(hexString: "#FF000000")!, paragraphAlignment: .center)
        self.items = items
        self.selectedIndex = selectedIndex
        return CGSize(width: self.preWidth, height: 30 + CGFloat(items.count) * self.preItemHeight + 12)
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 20, y: 10, width: size.width - 40, height: 15))
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: size.width - 36, y: 5, width: 24, height: 24))
        transition.updateFrame(view: self.tableView, frame: CGRect(x: 0, y: 30, width: size.width, height: size.height - 30 - 12))
    }
    
    public func updateData() {
        self.tableView.reloadData()
    }
    
    @objc func closeButtonClick(sender: UIButton) {
        self.closeEvent?()
    }
}

extension TBSegmentNode: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.preItemHeight
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.items.count > indexPath.row {
            let item = self.items[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TBSegmentItemCell.self)) as? TBSegmentItemCell {
                cell.updateItem(item, isSelected: indexPath.row == self.selectedIndex)
                return cell
            }
        }
        return UITableViewCell()
    }
        
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        self.updateData()
        let item = self.items[indexPath.row]
        self.selectedSegmentEvent?(item)
    }
    
}

class TBSegmentItemCell: UITableViewCell {
    
    private let selectedButton = UIButton(type: .custom)
    private let iconV = UIImageView()
    private let titleV: UILabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white
        self.contentView.addSubview(self.iconV)
        self.contentView.addSubview(self.titleV)
        self.contentView.addSubview(self.selectedButton)
        self.layoutSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutSubview() {
        self.selectedButton.isUserInteractionEnabled = false
        self.selectedButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        self.iconV.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(52)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        self.titleV.textColor = UIColor.black
        self.titleV.font = Font.medium(17)
        self.titleV.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(87)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(19)
        }
    }
    
    func updateItem(_ item: TBSegmentItem, isSelected: Bool) {
        self.selectedButton.setImage(UIImage(named: item.selectedIcon()), for: .selected)
        self.selectedButton.setImage(UIImage(named: item.unSelectedIcon()), for: .normal)
        self.selectedButton.isSelected = isSelected
        if let iconImage = item.iconImage(), let iconUrl = URL(string: iconImage) {
            self.iconV.sd_setImage(with: iconUrl)
        }
        self.titleV.text = item.title()
    }
}
