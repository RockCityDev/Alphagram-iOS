
import UIKit
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import WebKit

class NavNode: ASDisplayNode {
    private let context: AccountContext
    
    let backNode: ASButtonNode
    let titleNode: ASTextNode
    
    private var title = ""
    
    var backEvent: (()->Void)?
    
    init(context: AccountContext) {
        self.context = context
        self.backNode = ASButtonNode()
        self.titleNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.backNode.setImage(UIImage(named: "Chat/nav/btn_back_tittle_bar"), for: .normal)
        self.backNode.addTarget(self, action: #selector(backClickEvent(btn:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.backNode)
        self.addSubnode(self.titleNode)
    }
    
    @objc func backClickEvent(btn: UIButton) {
        self.backEvent?()
    }
    
    func updateTitle(_ title: String) {
        self.title = title
        self.titleNode.attributedText = NSAttributedString(string: title, font: Font.semibold(17.0), textColor: UIColor.black, paragraphAlignment: .center)
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.backNode, frame: CGRect(x: 12, y: size.height - 44 + 2, width: 40, height: 40))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 108, y: size.height - 44 + 12, width: size.width - 216, height: 20))
    }
    
}


public class TBWebviewController: ViewController {
    
    public let context: AccountContext
    
    private let nav: NavNode
    
    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.selectionGranularity = .character
        let mwebView = WKWebView(frame: .zero, configuration: configuration)
        return mwebView
    }()
    
    let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = UIColor(hexString: "#FFF7F8F9")!
        progress.progressTintColor = UIColor(hexString: "#FF4B5BFF")!
        return progress
    }()

    let webUrl: URL
    
    public init(context: AccountContext, webUrl: URL) {
        self.context = context
        self.nav = NavNode(context: self.context)
        self.webUrl = webUrl
        let presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData))
        self.navigationBar?.isHidden = true
        self.displayNode.backgroundColor = UIColor.white
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
   
   public override func displayNodeDidLoad() {
       super.displayNodeDidLoad()
       self.displayNode.addSubnode(self.nav)
       self.nav.backEvent = { [weak self] in
           guard let strongSelf = self else { return }
           if strongSelf.webView.canGoBack {
               strongSelf.webView.goBack()
           } else {
               if strongSelf.navigationController != nil {
                   strongSelf.navigationController?.popViewController(animated: true)
               } else {
                   strongSelf.dismiss(animated: true)
               }
           }
       }
       
       let bounds = UIScreen.main.bounds
       self.webView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
       self.view.addSubview(self.webView)
       self.webView.load(URLRequest(url: self.webUrl))

       webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
       webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
       self.view.addSubview(self.progressView)
   }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let topHeight = (layout.statusBarHeight ?? 20) + layout.safeInsets.top
        transition.updateFrame(node: self.nav, frame: CGRect(x: 0, y: 0, width: layout.size.width, height: topHeight))
        nav.updateLayout(size: CGSize(width: layout.size.width, height: topHeight), transition: transition)
        transition.updateFrame(view: self.webView, frame: CGRect(x: 0, y: topHeight, width: layout.size.width, height: layout.size.height - topHeight))
        transition.updateFrame(view: self.progressView, frame: CGRect(x: 0, y: topHeight, width: layout.size.width, height: 3))
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if keyPath == "estimatedProgress" && webView == webView {
            progressView.alpha = 1.0
            let animated = Float(webView.estimatedProgress) > progressView.progress
            progressView.setProgress(Float(webView.estimatedProgress), animated: animated)
            if webView.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.22, animations: {
                    self.progressView.alpha = 0.0
                }) { (finished) in
                    self.progressView.setProgress(0.0, animated: false)
                }
            }
        } else if keyPath == "title" && webView == webView {
            if let webviewTitle = webView.title {
                self.nav.updateTitle(webviewTitle)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc func tapEvent(tap: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }

}
