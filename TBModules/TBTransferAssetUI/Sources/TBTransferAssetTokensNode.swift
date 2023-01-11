
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData

public struct TbToken: TBTokenItem {
    public func tokenIcon() -> String {
        return "https://d3l1ioscvnrz88.cloudfront.net/system/web3/chain/chain_logo_ethereum.png"
    }
    public func tokenName() ->  String {
        return "USDC"
    }
    public func tokenMarketPrice() ->  String {
        return "344"
    }
    public func tokenCount() ->  String {
        return "333"
    }
    public func tokenTotal() ->  String {
        return "3000"
    }
}

public protocol TBTokenItem {
    func tokenIcon() -> String
    func tokenName() ->  String
    func tokenMarketPrice() ->  String
    func tokenCount() ->  String
    func tokenTotal() ->  String
}

class TBTransferAssetTokensNode: ASDisplayNode {
    private let context: AccountContext
    private let titleNode: ASTextNode
    private let closeNode: ASButtonNode
    private var tableView: UITableView?
    private var emptyNode: TBTokensEmptyNode?
    private let isEmpty: Bool
    private let preWidth: CGFloat
    private let itemHeight: CGFloat
    private let nodeHeight = 522
    
    private var items = [TBTokenItem]()
    
    public var closeEvent: (()->())?
    public var selectedSegmentEvent: ((TBTokenItem) -> ())?
    
    init(context: AccountContext, preWidth: CGFloat = UIScreen.main.bounds.width, itemHeight: CGFloat = 71, isEmpty: Bool = false) {
        self.context = context
        self.titleNode = ASTextNode()
        self.closeNode = ASButtonNode()
        self.isEmpty = isEmpty
        if isEmpty {
            self.emptyNode = TBTokensEmptyNode()
        } else {
            self.tableView = UITableView(frame: .zero, style: .plain)
        }
        self.preWidth = preWidth
        self.itemHeight = itemHeight
        super.init()
        self.backgroundColor = UIColor.white
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.closeNode.addTarget(self, action: #selector(closeButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.closeNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.addSubnode(self.closeNode)
        if self.isEmpty {
            self.addSubnode(self.emptyNode!)
        } else {
            self.tableView!.tableFooterView = UIView()
            self.tableView!.delegate = self
            self.tableView!.dataSource = self
            self.tableView!.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.tableView!.showsVerticalScrollIndicator = false
            self.tableView!.allowsSelection = true
            self.tableView!.register(TBTokenCell.self, forCellReuseIdentifier: String(describing: TBTokenCell.self))
            if #available(iOS 11.0, *) {
                self.tableView!.contentInsetAdjustmentBehavior = .never
            }
            self.view.addSubview(self.tableView!)
        }
    }
    
    public func updateSegment(title: String, items: [TBTokenItem]) -> CGSize {
        self.titleNode.attributedText = NSAttributedString(string: title, font: Font.medium(13), textColor: UIColor(hexString: "#FF000000")!, paragraphAlignment: .center)
        self.items = items
        return CGSize(width: self.preWidth, height: 522)
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 20, y: 16, width: size.width - 40, height: 15))
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: size.width - 36, y: 5, width: 24, height: 24))
        if self.isEmpty {
            transition.updateFrame(node: self.emptyNode!, frame: CGRect(x: 0, y: 50, width: size.width, height: size.height - 50 - 12))
            self.emptyNode!.update(size: CGSize(width: size.width, height: size.height - 50 - 12), transition: transition)
        } else {
            transition.updateFrame(view: self.tableView!, frame: CGRect(x: 0, y: 50, width: size.width, height: size.height - 50 - 12))
        }
    }
    
    public func updateData() {
        self.tableView?.reloadData()
    }
    
    @objc func closeButtonClick(sender: UIButton) {
        self.closeEvent?()
    }
    
    
}

extension TBTransferAssetTokensNode: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.itemHeight
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.items.count > indexPath.row {
            let item = self.items[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TBTokenCell.self)) as? TBTokenCell {
                cell.updateBit(token: item)
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

class BitNode: UIView {
    
    private let nameNode: UILabel
    private let markPriceNode: UILabel
    private let countNode: UILabel
    private let totalNodel: UILabel
    
    override init(frame: CGRect) {
        self.nameNode = UILabel()
        self.markPriceNode = UILabel()
        self.countNode = UILabel()
        self.totalNodel = UILabel()
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.nameNode.textColor = UIColor.black
        self.nameNode.font = Font.medium(15)
        self.addSubview(self.nameNode)
        
        self.markPriceNode.textColor = UIColor(hexString: "#FF56565C")
        self.markPriceNode.font = Font.medium(13)
        self.addSubview(self.markPriceNode)
        
        self.countNode.textColor = UIColor.black
        self.countNode.font = Font.medium(15)
        self.countNode.textAlignment = .right
        self.addSubview(self.countNode)
        
        self.totalNodel.textColor = UIColor(hexString: "#FF56565C")
        self.totalNodel.font = Font.medium(13)
        self.totalNodel.textAlignment = .right
        self.addSubview(self.totalNodel)
        
        self.nameNode.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.leading.equalToSuperview()
            make.height.equalTo(20)
        }
        self.markPriceNode.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(37)
            make.leading.equalToSuperview()
            make.height.equalTo(18)
        }
        self.countNode.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.trailing.equalToSuperview()
            make.height.equalTo(18)
            make.leading.equalTo(self.nameNode.snp_trailingMargin).offset(20)
        }
        self.totalNodel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(37)
            make.trailing.equalToSuperview()
            make.height.equalTo(18)
            make.leading.equalTo(self.markPriceNode.snp_trailingMargin).offset(20)
        }
        
        self.countNode.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.countNode.setContentHuggingPriority(.required, for: .horizontal)
        self.totalNodel.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.totalNodel.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    func updateBit(token: TBTokenItem) {
        self.nameNode.text = token.tokenName()
        self.markPriceNode.text = token.tokenMarketPrice()
        self.countNode.text = token.tokenCount()
        self.totalNodel.text = token.tokenTotal()
    }
}

class TBTokenCell: UITableViewCell {

    private let iconImg = UIImageView()
    private let bitView = BitNode()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.contentView.addSubview(self.iconImg)
        self.contentView.addSubview(self.bitView)
    
        self.iconImg.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
            make.leading.equalToSuperview().offset(27)
        }
        
        self.bitView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(84)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-27)
        }
    }
    
    func updateBit(token: TBTokenItem) {
        self.iconImg.sd_setImage(with: URL(string: token.tokenIcon()), placeholderImage: UIImage())
        self.bitView.updateBit(token: token)
    }
}

class TBTokensEmptyNode: ASDisplayNode {

    private let titleNode: ASTextNode
    private let title: String
    
    override init() {
        self.titleNode = ASTextNode()
        self.title = ""
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.titleNode.maximumNumberOfLines = 6
        self.addSubnode(self.titleNode)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.titleNode.attributedText = NSAttributedString(string: self.title, font: Font.medium(15), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .center)
        let titleSize = self.titleNode.updateLayout(CGSize(width: size.width - 66, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: (size.width - titleSize.width) / 2, y: 174, width: titleSize.width, height: titleSize.height))
    }
    
}

