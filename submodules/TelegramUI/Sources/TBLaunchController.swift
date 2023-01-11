
import UIKit
import Display
import AsyncDisplayKit
import AnimatedStickerNode
import TelegramAnimatedStickerNode

class TBLaunchController: ViewController {
    
    private var didFinished: (() -> Void)?
    private let emptyAnimationNode: AnimatedStickerNode
    private let titleImageMode: ASImageNode
    
    init(launch didFinished: @escaping () -> Void) {
        self.didFinished = didFinished
        self.emptyAnimationNode = DefaultAnimatedStickerNodeImpl()
        self.titleImageMode = ASImageNode()
        super.init(navigationBarPresentationData: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        let width = UIScreen.main.bounds.size.width

        self.displayNode.addSubnode(self.emptyAnimationNode)
        let height = CGFloat(1464) / CGFloat(1170) * width
        self.emptyAnimationNode.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: height))
        self.emptyAnimationNode.updateLayout(size: CGSize(width: width, height: height))
        self.emptyAnimationNode.setup(source: AnimatedStickerNodeLocalFileSource(name: "animation_logo_launch_page"), width: Int(width), height: Int(height), playbackMode: .once, mode: .direct(cachePathPrefix: nil))
        
        self.titleImageMode.image = UIImage(named: "image_txt_launch_page_t")
        let nHeight = CGFloat(976) / CGFloat(780) * width
        self.titleImageMode.frame = CGRect(x: 0, y: 0, width: width, height: nHeight)
        self.displayNode.addSubnode(self.titleImageMode)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.displayNode.backgroundColor = UIColor.white
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.emptyAnimationNode.alpha = 1.0
        self.emptyAnimationNode.visibility = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.didFinished?()
        }
    }
    
}
