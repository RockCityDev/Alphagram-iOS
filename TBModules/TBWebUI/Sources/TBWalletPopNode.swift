import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import SnapKit
import TelegramPresentationData
import SDWebImage

public enum WalletAction {
    case disConnect
    case change
    case copy
    case view
}

public struct WalletPopSegment {
    let action: WalletAction
    let title: String
}

func popSegments() -> [WalletPopSegment] {
    return [WalletPopSegment(action: .disConnect, title: "Disconnect"),
            WalletPopSegment(action: .change, title: "Change"),
            WalletPopSegment(action: .copy, title: "Copy Address"),
            WalletPopSegment(action: .view, title: "View on Explorer")]
}

public class TBWalletPopNode: ASDisplayNode {
    private let preWidth: CGFloat
    private let preItemHeight: CGFloat
    private let titleNode: ASTextNode
    private let iconImageNode: ASImageNode
    private let addressNode: ASTextNode
    private let closeNode: ASButtonNode
    private let tableView: UITableView
    
    private var items = [WalletPopSegment]()
    
    public var closeEvent: (()->())?
    public var selectedSegmentEvent: ((WalletPopSegment) -> ())?
    
    public init(preWidth: CGFloat = UIScreen.main.bounds.width - 120, preItemHeight: CGFloat = 44) {
        self.preWidth = preWidth
        self.preItemHeight = preItemHeight
        self.titleNode = ASTextNode()
        self.iconImageNode = ASImageNode()
        self.addressNode = ASTextNode()
        self.closeNode = ASButtonNode()
        self.tableView = UITableView(frame: .zero, style: .plain)
        super.init()
        self.backgroundColor = UIColor.white
    }
    
    
    public override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.addSubnode(self.iconImageNode)
        self.addSubnode(self.addressNode)
        self.closeNode.addTarget(self, action: #selector(closeButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.closeNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.addSubnode(self.closeNode)
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.allowsSelection = true
        self.tableView.separatorStyle = .none
        self.tableView.register(TBWalletPopNodeCell.self, forCellReuseIdentifier: String(describing: TBWalletPopNodeCell.self))
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .never
        }
        self.view.addSubview(self.tableView)
    }
    
    public func updateSegment(address: String) -> CGSize {
        self.titleNode.attributedText = NSAttributedString(string: "Connected with MetaMask", font: Font.medium(13), textColor: UIColor(hexString: "#FF000000")!, paragraphAlignment: .center)
        self.iconImageNode.image = UIImage(named: "TBWebPage/icon_metamask_address")
        self.addressNode.attributedText = NSAttributedString(string: address, font: Font.semibold(17), textColor: UIColor(hexString: "#FF000000")!)
        self.items = popSegments()
        return CGSize(width: self.preWidth, height: 89 + CGFloat(items.count) * self.preItemHeight + 12)
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 20, y: 10, width: size.width - 40, height: 15))
        transition.updateFrame(node: self.iconImageNode, frame: CGRect(x: size.width / 2 - 80, y: 49, width: 24, height: 24))
        let addressSize = self.addressNode.updateLayout(CGSize(width: size.width, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.addressNode, frame: CGRect(x: size.width / 2 - 50, y: 53, width: addressSize.width, height: 18))
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: size.width - 36, y: 5, width: 24, height: 24))
        transition.updateFrame(view: self.tableView, frame: CGRect(x: 0, y: 89, width: size.width, height: size.height - 89 - 12))
    }
    
    func updateData() {
        self.tableView.reloadData()
    }
    
    @objc func closeButtonClick(sender: UIButton) {
        self.closeEvent?()
    }
}

extension TBWalletPopNode: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.preItemHeight
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.items.count > indexPath.row {
            let item = self.items[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TBWalletPopNodeCell.self)) as? TBWalletPopNodeCell {
                cell.updateItem(item)
                return cell
            }
        }
        return UITableViewCell()
    }
        
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.selectedSegmentEvent?(item)
    }
    
}

class TBWalletPopNodeCell: UITableViewCell {
    
    private let line: UIView = UIView()
    private let titleV: UILabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white
        self.contentView.addSubview(self.line)
        self.contentView.addSubview(self.titleV)
        self.layoutSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutSubview() {
        self.line.backgroundColor = UIColor(hexString: "#5C3C3C43")
        self.line.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        self.titleV.textColor = UIColor(hexString: "#FF4B5BFF")
        self.titleV.font = Font.regular(17)
        self.titleV.textAlignment = .center
        self.titleV.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.height.equalTo(19)
        }
    }
    
    func updateItem(_ item: WalletPopSegment) {
        self.titleV.text = item.title
    }
}
