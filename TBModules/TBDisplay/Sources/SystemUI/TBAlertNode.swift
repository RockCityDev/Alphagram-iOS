
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData

public class TBAlertNode: ASDisplayNode {
    
    private let preWidth: CGFloat
    private let titleNode: ASTextNode
    private let contentNode: ASTextNode
    private let buttonNode: ASButtonNode
    private let closeNode: ASButtonNode
    
    public var closeEvent: (()->())?
    public var buttonClickEvent: (()->())?
    
    public init(preWidth: CGFloat = UIScreen.main.bounds.width - 70) {
        self.preWidth = preWidth
        self.titleNode = ASTextNode()
        self.contentNode = ASTextNode()
        self.buttonNode = ASButtonNode()
        self.closeNode = ASButtonNode()
        super.init()
    }
    
    public override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.addSubnode(self.contentNode)
        self.buttonNode.addTarget(self, action: #selector(bottomButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.buttonNode)
        self.closeNode.addTarget(self, action: #selector(closeButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.closeNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.addSubnode(self.closeNode)
    }
    
    public func updateAlert(title: String, content: String, buttonTitle: String) -> CGSize {
        self.titleNode.attributedText = NSAttributedString(string: title, font: Font.bold(18), textColor: UIColor.black)
        self.contentNode.attributedText = NSAttributedString(string: content, font: Font.regular(15), textColor: UIColor(hexString: "#FF1A1A1D")!)
        let size = self.contentNode.updateLayout(CGSize(width: self.preWidth - 40, height: .greatestFiniteMagnitude))
        self.buttonNode.setTitle(buttonTitle, with: Font.regular(14), with: UIColor(hexString: "#FF02ABFF")!, for: .normal)
        return CGSize(width: self.preWidth, height: size.height + 130)
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 20, y: 30, width: size.width - 40, height: 22))
        transition.updateFrame(node: self.contentNode, frame: CGRect(x: 20, y: 70, width: size.width - 40, height: size.height - 130))
        transition.updateFrame(node: self.buttonNode, frame: CGRect(x: 20, y: size.height - 48, width: size.width - 40, height: 36))
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: size.width - 44, y: 22, width: 36, height: 36))
    }
    
    @objc func closeButtonClick(sender: UIButton) {
        self.closeEvent?()
    }
    
    @objc func bottomButtonClick(sender: UIButton) {
        self.buttonClickEvent?()
    }
}

