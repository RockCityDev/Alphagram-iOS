
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import AvatarNode
import TBDisplay
import Display
import Postbox
import TelegramCore

public enum PopConfig {
    
    public enum Status {
        case waitOpen
        case empty
        case invalid
    }
    
    public enum Source {
        case single
        case group
    }
    
    case sender(status: Status, source: Source)
    case receive(status: Status, source: Source)
    
    
    func statusValue() -> Status {
        switch self {
        case let .receive(status, _):
            return status
        case let .sender(status, _):
            return status
        }
    }
    
    func sourceValue() -> Source {
        switch self {
        case let .receive(_, source):
            return source
        case let .sender(_, source):
            return source
        }
    }
    
    public func changeStatus(status: Status) -> PopConfig {
        switch self {
        case let .sender(_, source):
            return .sender(status: status, source: source)
        case let .receive(_, source):
            return .receive(status: status, source: source)
        }
    }
}

public func transform(status: RedEnvelopeStatus) -> PopConfig.Status {
    switch formatedStatus(status: status.status) {
    case .online:
        return .waitOpen
    case .complete:
        return .empty
    default:
        return .invalid
    }
}

public func transformSource(status: RedEnvelopeStatus) -> PopConfig.Source {
    return status.source == 2 ? .single : .group
}

public enum EventType {
    case pop
    case detail
}

public func redEnvelopeEvent(config: PopConfig, isGet: Bool) -> EventType {
    switch config {
    case let .receive(status, _):
        return (status == .waitOpen || status == .empty) && isGet ? .detail : .pop
    case let .sender(status, source):
        switch source {
        case .single:
            return .detail
        case .group:
            return (status == .waitOpen && !isGet) ? .pop : .detail
        }
    }
}

func popViewHeight(by status: PopConfig.Status) -> CGFloat {
    if .waitOpen == status {
        return 444.0
    } else {
        return 418.0
    }
}

func popViewBgHeight(by status: PopConfig.Status) -> CGFloat {
    if .waitOpen == status {
        return 261.0
    } else {
        return 300.0
    }
}

func alertText(by status: PopConfig.Status) -> NSAttributedString {
    
    switch status {
    case .waitOpen:
        return NSAttributedString(string: "", font: Font.bold(15), textColor: UIColor(hexString: "#FFFFDBBA")!, paragraphAlignment: .center)
    case .invalid:
        let prefix = ""
        let suffix = "24"
        let rel = prefix + "\n" + suffix
        let attr = NSMutableAttributedString(string: rel)
        attr.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.white,
                            NSAttributedString.Key.font : Font.bold(15)
                           ], range: (rel as NSString).range(of: prefix))
        attr.addAttributes([NSAttributedString.Key.foregroundColor : UIColor(hexString: "#C4FFFFFF")!,
                            NSAttributedString.Key.font : Font.regular(12)
                           ], range: (rel as NSString).range(of: suffix))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attr.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: rel.count))
        return attr
    case .empty:
        return NSAttributedString(string: "\n", font: Font.bold(15), textColor: .white, paragraphAlignment: .center)
    }
}


class RedEnvelopeAlertNode: ASDisplayNode {
    private let context: AccountContext
    private let status: PopConfig.Status
    
    private let leftLine: ASDisplayNode
    private let titleNode: ASTextNode
    private let rightLine: ASDisplayNode
    
    init(context: AccountContext, status: PopConfig.Status) {
        self.context = context
        self.status = status
        
        self.leftLine = ASDisplayNode()
        self.titleNode = ASTextNode()
        self.rightLine = ASDisplayNode()
        
        super.init()
        
        self.titleNode.attributedText = alertText(by: status)
    }
    
    override func didLoad() {
        super.didLoad()
        
        let size = self.preSize()
        let titleSize = self.titleSize()
        self.addSubnode(self.titleNode)
        self.titleNode.frame = CGRect(origin: CGPoint(x: (size.width - titleSize.width) / 2.0, y: 0), size: titleSize)
        
        let lineWidth = (size.width - titleSize.width) / 2.0 - 10
        
        self.leftLine.backgroundColor = UIColor(hexString: "#FFF72828")
        self.addSubnode(self.leftLine)
        self.leftLine.frame = CGRect(x: 0, y: (size.height - 1) / 2.0, width: lineWidth, height: 1)
        
        self.rightLine.backgroundColor = UIColor(hexString: "#FFF72828")
        self.addSubnode(self.rightLine)
        self.rightLine.frame = CGRect(x: size.width - lineWidth, y: (size.height - 1) / 2.0, width: lineWidth, height: 1)
    }
    
    private func titleSize() -> CGSize {
        return self.titleNode.updateLayout(CGSize(width: 180.0, height: .greatestFiniteMagnitude))
    }
    
    func preSize() -> CGSize {
        return CGSize(width: 220.0, height: self.titleSize().height)
    }
}


class RedEnvelopePopNode: ASDisplayNode {
    
    private let context: AccountContext
    private let popConfig: PopConfig
    private let fromUserId: String
    
    private let containNode: ASDisplayNode
    private let topBgNode: ASImageNode
    private let avatarNode: ASImageNode
    private let nameNode: ASTextNode
    
    private let alertNode: RedEnvelopeAlertNode
    private let openRpNode: ASButtonNode
    
    private let openDetailNode: TBButtonView
    private let closeNode: ASButtonNode
    
    var closeEvent: (()->())?
    var openRPEventHandle: (()->())?
    var openDetailEventHandle: (()->())?
    
    init(context: AccountContext, popConfig: PopConfig, fromUserId: String) {
        self.context = context
        self.popConfig = popConfig
        self.fromUserId = fromUserId
        
        self.containNode = ASDisplayNode()
        self.topBgNode = ASImageNode()
        self.avatarNode = ASImageNode()
        self.nameNode = ASTextNode()
        
        self.alertNode = RedEnvelopeAlertNode(context: context, status: self.popConfig.statusValue())
        self.openRpNode = ASButtonNode()
        
        let config = TBBottonViewNormalConfig(gradientColors: [UIColor.clear.cgColor, UIColor.clear.cgColor], borderWidth: 1, borderColor: UIColor(hexString: "#73FFFFFF")!.cgColor, borderRadius: 18, enbale: true, alpha: 1, iconSize: CGSize(width: 16, height: 36), titleFont: Font.medium(13), buttonType: .titleLeft, spacing: 0)
        self.openDetailNode = TBButtonView(config: config)
        self.closeNode = ASButtonNode()
        super.init()
        
        let peerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: PeerId.Id._internalFromInt64Value(NSDecimalNumber(string: self.fromUserId).int64Value))
        let _ = context.account.viewTracker.peerView(peerId).start(next: {[weak self] peerView in
            let user = peerView.peers[peerView.peerId] as? TelegramUser
            self?.updateNameBy(user)
            self?.updateAvatarBy(user)
        })
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.containNode.cornerRadius = 12
        self.containNode.layer.masksToBounds = true
        self.containNode.backgroundColor = UIColor(hexString: "#FFEA3030")
        self.addSubnode(self.containNode)
        
        self.topBgNode.image = UIImage(named: "TBRedEnvelope/red_pop_bg_img")?.resizableImage(withCapInsets: UIEdgeInsets.zero)
        self.containNode.addSubnode(self.topBgNode)
        
        self.avatarNode.cornerRadius = 32
        self.avatarNode.borderColor = UIColor.white.cgColor
        self.avatarNode.borderWidth = 4
        self.avatarNode.backgroundColor = UIColor.lightGray
        self.containNode.addSubnode(self.avatarNode)
        
        self.containNode.addSubnode(self.nameNode)
        
        self.containNode.addSubnode(self.alertNode)
        
        self.openRpNode.setImage(UIImage(named: "TBRedEnvelope/red_pop_open_img"), for: .normal)
        self.containNode.addSubnode(self.openRpNode)
        self.openRpNode.addTarget(self, action: #selector(self.openRpButtonClick), forControlEvents: .touchUpInside)
        
        self.openDetailNode.contentView.icon.image = UIImage(named: "TBRedEnvelope/red_pop_arrow")
        self.openDetailNode.contentView.titleLabel.text = ""
        self.openDetailNode.contentView.titleLabel.textColor = UIColor.white
        self.containNode.view.addSubview(self.openDetailNode)
        self.openDetailNode.tapBlock = {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.openDetailEventHandle?()
        }
        
        self.closeNode.setImage(UIImage(named: "TBRedEnvelope/red_pop_close_img"), for: .normal)
        self.addSubnode(self.closeNode)
        self.closeNode.addTarget(self, action: #selector(self.closeButtonClick), forControlEvents: .touchUpInside)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.containNode, frame: CGRect(x: 0, y: 0, width: size.width, height: size.height - 60))
        transition.updateFrame(node: self.topBgNode, frame: CGRect(x: 0, y: 0, width: size.width, height: popViewBgHeight(by: self.popConfig.statusValue())))
        transition.updateFrame(node: self.avatarNode, frame: CGRect(x: (size.width - 64) / 2, y: 33, width: 64, height: 64))
        transition.updateFrame(node: self.nameNode, frame: CGRect(x: 16, y: 109, width: size.width - 32, height: 20))
        transition.updateFrame(node: self.alertNode, frame: CGRect(origin: CGPoint(x: 36, y: 177), size: self.alertNode.preSize()))
        
        if self.popConfig.statusValue() == .waitOpen {
            transition.updateFrame(node: self.openRpNode, frame: CGRect(x: 100, y: 214, width: 92, height: 92))
            self.openRpNode.isHidden = false
        } else {
            self.openRpNode.isHidden = true
        }
        
        switch self.popConfig.sourceValue() {
        case .single:
            self.openDetailNode.isHidden = true
        case .group:
            if case let .sender(status, _) = self.popConfig {
                self.openDetailNode.isHidden = status != .waitOpen
                transition.updateFrame(view: self.openDetailNode, frame: CGRect(x: (size.width - 140) / 2, y: 329.0, width: 140, height: 36))
                break
            }
            if case let .receive(status, _) = popConfig {
                self.openDetailNode.isHidden = false
                let y = status == .waitOpen ? 329.0 : 245.0
                transition.updateFrame(view: self.openDetailNode, frame: CGRect(x: (size.width - 140) / 2, y: y, width: 140, height: 36))
            }
        }
        
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: (size.width - 42) / 2, y: size.height - 60, width: 42, height: 60))
    }
    
    private func updateNameBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let name: String = {
            if let name = user.username {
                return name
            }
            var text = ""
            if let firstName = user.firstName {
                text.append("\(firstName) ")
            }
            if let lastName = user.lastName {
                text.append("\(lastName)")
            }
            return text
        }()
        let text = ": " + (name.isEmpty ? "***" : name)
        self.nameNode.attributedText = NSAttributedString(string: text, font: Font.bold(15), textColor: .white, paragraphAlignment: .center)
    }
    
    private func updateAvatarBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 60, height: 60)) {
            let _ = signal.start {[weak self] a in
                self?.avatarNode.image = a?.0
            }
        }else {
            self.avatarNode.image = nil
        }
    }
    
    @objc func closeButtonClick() {
        self.closeEvent?()
    }
    
    @objc func openRpButtonClick() {
        self.openRPEventHandle?()
    }
}


public class RedEnvelopePopController: TBPopController {
    private var currentConfig: PopConfig
    private let fromUserId: String
    public var openRPEventHandle: (()->())?
    public var openDetailEventHandle: (()->())?
    
    public init(context: AccountContext, fromTgUserId: String, popConfig: PopConfig) {
        self.currentConfig = popConfig
        self.fromUserId = fromTgUserId
        super.init(context: context, backgroundColor: UIColor(hexString: "#CC000000")!, canCloseByTouches: false)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        let screenSize = UIScreen.main.bounds.size
        let nodeHeight = popViewHeight(by: self.currentConfig.statusValue())
        let node = RedEnvelopePopNode(context: context, popConfig: self.currentConfig, fromUserId: self.fromUserId)
        node.closeEvent = { [weak self] in
            self?.dismiss()
        }
        node.openRPEventHandle = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.openRPEventHandle?()
        }
        node.openDetailEventHandle = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.openDetailEventHandle?()
        }
        self.setContentNode(node, frame: CGRect(x: (screenSize.width - 292.0) / 2.0, y: (screenSize.height - nodeHeight) / 2.0 + 40, width: 292.0, height: nodeHeight))
    }
    
    public func replacePopConfig(popConfig: PopConfig) {
        self.currentConfig = popConfig
        let screenSize = UIScreen.main.bounds.size
        let nodeHeight = popViewHeight(by: popConfig.statusValue())
        let node = RedEnvelopePopNode(context: context, popConfig: popConfig, fromUserId: self.fromUserId)
        node.closeEvent = { [weak self] in
            self?.dismiss()
        }
        node.openRPEventHandle = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.openRPEventHandle?()
        }
        node.openDetailEventHandle = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.openDetailEventHandle?()
        }
        let frame = CGRect(x: (screenSize.width - 292.0) / 2.0, y: (screenSize.height - nodeHeight) / 2.0 + 40, width: 292.0, height: nodeHeight)
        let transition = ContainedViewLayoutTransition.animated(duration: 0.23, curve: .linear)
        self.replaceContentNode(node, frame: frame, transition: transition)
        node.update(size: frame.size, transition: transition)
    }
    
    public override func pop(from controller: ViewController, transition: ContainedViewLayoutTransition = .animated(duration: 0.23, curve: .easeInOut)) {
        super.pop(from: controller, transition: transition)
        if let item = self.contentItem, let node = item.node as? RedEnvelopePopNode {
            node.update(size: node.frame.size, transition: transition)
        }
    }
}
