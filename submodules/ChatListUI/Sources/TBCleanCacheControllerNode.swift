
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import SwiftSignalKit
import TBLanguage
import MJRefresh
import SnapKit
import SDWebImage


extension UIImage {
    class func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

func cacheColor(category: ItemCategory) -> UIColor {
    switch category {
    case .category(let category):
        switch category {
        case .image:
            return UIColor(hexString: "#FF2F83E3")!
        case .audio:
            return UIColor(hexString: "#FFA554E1")!
        case .video:
            return UIColor(hexString: "#FFE0B60C")!
        case .file:
            return UIColor(hexString: "#FF5DCB4C")!
        }
    case .other:
        return UIColor(hexString: "#FF5BA9EF")!
    }
}

private let lineWidth: CGFloat = 7.0
private let radius: CGFloat = 95.0

class TBCleanCacheHeaderNode: ASDisplayNode {
    private let context: AccountContext
    
    private let cacheLayerNode: ASDisplayNode
    private let topLab: UILabel
    private let bottomLab: UILabel
    private let progressLayer: CAShapeLayer
    private var cacheLayers: [CAShapeLayer]
    
    private let sizeStatusPromise: ValuePromise<CGSize>
    private let cacheItemsPromise: Promise<[CacheItem]>
    
    init(context: AccountContext) {
        self.context = context
        self.cacheLayerNode = ASDisplayNode()
        self.topLab = UILabel()
        self.bottomLab = UILabel()
        self.progressLayer = CAShapeLayer()
        self.cacheLayers = [CAShapeLayer]()
        self.sizeStatusPromise = ValuePromise<CGSize>()
        self.cacheItemsPromise = Promise<[CacheItem]>()
        super.init()
        let _ = (combineLatest(queue: .mainQueue(),
                               self.sizeStatusPromise.get(),
                               self.cacheItemsPromise.get())
                 |> deliverOnMainQueue).start {[weak self] size, cacheItems in
            guard let strongSelf = self else { return }
            let cacheItems = cacheItems.filter { item in
                return item.selected
            }.sorted(by: { s1, s2 in
                return s1.size < s2.size
            })
            let totalSize = cacheItems.reduce(0) { partialResult, cacheItem in
                return partialResult + cacheItem.size
            }
            
            let eachDegree = ceil(lineWidth / radius / 2.0 / CGFloat.pi * 180)
            
            let emptyCount = cacheItems.reduce(0) { partialResult, cacheItem in
                let degree = CGFloat(cacheItem.size) / CGFloat(totalSize) * 360
                return degree < eachDegree * 2 ? partialResult + 1 : partialResult
            }
            
            var startDegree: CGFloat = -90.0
            let relEndDegree = startDegree + 360
            var lastDegreeIsEmpty = false
            let totalDegree = 360 - (CGFloat(emptyCount) * 4 * eachDegree)
            for layer in strongSelf.cacheLayers {
                layer.removeFromSuperlayer()
            }
            for item in cacheItems {
                let cacheLayer = CAShapeLayer()
                let isEmptyDegree = CGFloat(item.size) / CGFloat(totalSize) * 360 < eachDegree * 2
                let cacheDegree: CGFloat = {
                    if isEmptyDegree {
                        return eachDegree
                    } else {
                        return floor(CGFloat(item.size) / CGFloat(totalSize) * totalDegree)
                    }
                }()
                startDegree = (lastDegreeIsEmpty || isEmptyDegree) ? startDegree + eachDegree * 3 : startDegree
                let endDegree = min(relEndDegree, cacheDegree + startDegree)
                let path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: startDegree / 180 * CGFloat.pi, endAngle: endDegree / 180 * CGFloat.pi, clockwise: true)
                startDegree = endDegree
                lastDegreeIsEmpty = isEmptyDegree
                path.append(path)
                cacheLayer.path = path.cgPath
                cacheLayer.lineWidth = lineWidth
                cacheLayer.lineCap = .round
                cacheLayer.fillColor = UIColor.clear.cgColor
                cacheLayer.strokeColor = cacheColor(category: item.category).cgColor
                strongSelf.cacheLayerNode.view.layer.addSublayer(cacheLayer)
                strongSelf.cacheLayers.append(cacheLayer)
            }

            let path = UIBezierPath(arcCenter: CGPoint(x: radius, y:radius), radius: radius, startAngle: startDegree, endAngle: startDegree + CGFloat.pi * 2, clockwise: true)
            strongSelf.progressLayer.path = path.cgPath
            if totalSize == 0 {
                strongSelf.progressLayer.isHidden = false
                strongSelf.progressLayer.strokeStart = 0
                strongSelf.progressLayer.strokeEnd = 1
            } else {
                strongSelf.progressLayer.isHidden = true
            }
        }

    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.cacheLayerNode)
        self.topLab.textAlignment = .center
        self.topLab.textColor = UIColor.black
        self.topLab.font = Font.medium(54)
        self.view.addSubview(self.topLab)
        self.bottomLab.textAlignment = .center
        self.bottomLab.textColor = UIColor.black
        self.bottomLab.font = Font.regular(16)
        self.view.addSubview(self.bottomLab)
        self.progressLayer.lineWidth = lineWidth
        self.progressLayer.fillColor = UIColor.clear.cgColor
        self.progressLayer.strokeColor = UIColor.gray.cgColor
        self.view.layer.addSublayer(self.progressLayer)
    }
    
    func updateLayout(by size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(view: self.topLab, frame: CGRect(x: (size.width - 150) / 2.0 , y: (size.height - 75) / 2.0, width: 150, height: 54))
        transition.updateFrame(view: self.bottomLab, frame: CGRect(x: (size.width - 150) / 2.0, y: (size.height - 75) / 2.0 + 59, width: 150, height: 16))
        transition.updateFrame(node: self.cacheLayerNode, frame: CGRect(x: (size.width - radius * 2) / 2.0, y: (size.height - radius * 2) / 2.0, width: radius * 2, height: radius * 2))
        transition.updateFrame(layer: self.progressLayer, frame: CGRect(x: (size.width - radius * 2) / 2.0, y: (size.height - radius * 2) / 2.0, width: radius * 2, height: radius * 2))
        self.sizeStatusPromise.set(size)
    }
    
    func update(by size: Int64) {
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        let text = dataSizeString(size, formatting: DataSizeStringFormatting(presentationData: presentationData))
        let textArr = text.components(separatedBy: " ")
        self.topLab.text = textArr.first
        self.bottomLab.text = textArr.last
    }
    
    func updateCacheItems(_ items: [CacheItem]) {
        self.cacheItemsPromise.set(.single(items))
    }
    
    func cleanProgress(_ progress: Float) {
        self.progressLayer.isHidden = false
        self.progressLayer.strokeStart = 0
        self.progressLayer.strokeEnd = CGFloat(progress)
    }
}
 
class TBCleanCacheItemNode: ASDisplayNode {
    
    private let selectedBtn: ASButtonNode
    private let titleNode: ASTextNode
    private let sizeLabel: UILabel
    private let line: ASDisplayNode
    
    private var cacheItem: CacheItem?
    var itemClick: ((CacheItem) -> Void)?
    var currentItem: CacheItem? {
        return self.cacheItem
    }
    override init() {
        self.selectedBtn = ASButtonNode()
        self.titleNode = ASTextNode()
        self.sizeLabel = UILabel()
        self.line = ASDisplayNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.selectedBtn.cornerRadius = 11
        self.selectedBtn.borderWidth = 3
        self.selectedBtn.clipsToBounds = true
        self.selectedBtn.setImage(UIImage(named: "List Menu/icon_check_checkbox_tools"), for: .normal)
        self.addSubnode(self.selectedBtn)
        self.addSubnode(self.titleNode)
        self.sizeLabel.textAlignment = .right
        self.sizeLabel.textColor = UIColor(hexString: "#FF3F96CE")!
        self.sizeLabel.font = Font.regular(16)
        self.view.addSubview(self.sizeLabel)
        self.line.backgroundColor = UIColor(hexString: "#FFF0F0F0")
        self.addSubnode(self.line)
        let tap = UITapGestureRecognizer(target: self, action: #selector(itemClickEvent))
        self.view.addGestureRecognizer(tap)
    }
    
    func updateLayout(by size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.selectedBtn, frame: CGRect(x: 26, y: (size.height - 22.0) / 2.0, width: 22, height: 22))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 65, y: (size.height - 22.0) / 2.0, width: 200, height: 22))
        transition.updateFrame(view: self.sizeLabel, frame: CGRect(x: size.width - 176, y: (size.height - 22.0) / 2.0, width: 150, height: 22))
        transition.updateFrame(node: self.line, frame: CGRect(x: 65, y: size.height - 1, width: size.width - 65, height: 1))
    }
    
    
    func updateNode(by item: CacheItem) {
        self.cacheItem = item
        self.selectedBtn.isSelected = item.selected
        self.titleNode.attributedText = NSAttributedString(string: item.title, font: Font.regular(16), textColor: UIColor(hexString: "#FF656565")!)
        self.sizeLabel.text = item.sizeText
        let color = cacheColor(category: item.category)
        self.selectedBtn.borderColor = color.cgColor
        self.selectedBtn.backgroundColor = item.selected ? color : UIColor.white
    }
    
    @objc func itemClickEvent() {
        if let item = self.cacheItem, let event = self.itemClick {
            event(item)
        }
    }
}


class TBCleanCacheControllerNode: ASDisplayNode {

    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let headerNode: TBCleanCacheHeaderNode
    private let scrollNode: ASScrollNode
    private let cleanButtonNode: ASButtonNode
    
    private let layoutPromise: Promise<ContainerViewLayout>
    private let cacheItemPromise: Promise<[TBCleanCacheItemNode]>
    
    private var items = [ItemCategory : TBCleanCacheItemNode]()
    
    var cleanAction: (() -> Signal<Float, NoError>)?
    
    init(context: AccountContext, presentationData: PresentationData, itemClickEvent: @escaping (CacheItem) -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.headerNode = TBCleanCacheHeaderNode(context: context)
        self.scrollNode = ASScrollNode()
        self.cleanButtonNode = ASButtonNode()
        self.layoutPromise = Promise<ContainerViewLayout>()
        self.cacheItemPromise = Promise<[TBCleanCacheItemNode]>()
        super.init()
        let _ = (combineLatest(queue: .mainQueue(),
                               self.layoutPromise.get(),
                               self.cacheItemPromise.get())
                 |> deliverOnMainQueue).start {[weak self] layout, itemNodes in
            let width = layout.size.width
            let transition = ContainedViewLayoutTransition.animated(duration: 0.3, curve: .easeInOut)
            self?.scrollNode.view.contentSize = CGSize(width: width, height: 52 * CGFloat(itemNodes.count))
            for (index, node) in itemNodes.enumerated() {
                if node.supernode == nil {
                    node.itemClick = itemClickEvent
                    self?.scrollNode.addSubnode(node)
                }
                node.updateLayout(by: CGSize(width: width, height: 52), transition: transition)
                transition.updateFrame(node: node, frame: CGRect(x: 0, y: CGFloat(index) * 52, width: width, height: 52))
            }
            let selectedSize = itemNodes.reduce(Int64(0), { partialResult, node in
                if let selected = node.currentItem?.selected, let size = node.currentItem?.size {
                    return selected ? partialResult + size : partialResult
                }
                return partialResult
            })
            let color = selectedSize > 0 ? UIColor(hexString: "#FF46BDFE") : UIColor.lightGray
            self?.cleanButtonNode.backgroundColor = color
            self?.cleanButtonNode.isEnabled = selectedSize > 0
            self?.headerNode.update(by: selectedSize)
        }
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.headerNode)
        self.scrollNode.scrollableDirections = [.up, .down]
        self.scrollNode.view.showsVerticalScrollIndicator = false
        self.scrollNode.view.showsHorizontalScrollIndicator = false
        self.addSubnode(self.scrollNode)
        self.cleanButtonNode.cornerRadius = 8
        self.cleanButtonNode.setTitle(TBLanguage.sharedInstance.localizable(TBLankey.commontools_oneclick_cleanup), with: Font.medium(16), with: UIColor.white, for: .normal)
        self.addSubnode(self.cleanButtonNode)
        self.cleanButtonNode.addTarget(self, action: #selector(cleanEvent), forControlEvents: .touchUpInside)
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.layoutPromise.set(.single(layout))
        let navH = (layout.statusBarHeight ?? 0) + 44
        self.headerNode.updateLayout(by: CGSize(width: 260, height: 260), transition: transition)
        transition.updateFrame(node: self.headerNode, frame: CGRect(x: (layout.size.width - 260) / 2.0, y: navH, width: 260, height: 260))
        transition.updateFrame(node: self.scrollNode, frame: CGRect(x: 0, y: navH + 260, width: layout.size.width, height: layout.size.height - 260 - navH - 118))
        transition.updateFrame(node: self.cleanButtonNode, frame: CGRect(x: 26, y: layout.size.height - 118, width: layout.size.width - 52, height: 43))
    }
    
    func updateCacheItems(_ items: [CacheItem]) {
        var nodes = [TBCleanCacheItemNode]()
        for item in items {
            if let node = self.items[item.category] {
                node.updateNode(by: item)
                nodes.append(node)
            } else {
                let node = TBCleanCacheItemNode()
                node.updateNode(by: item)
                self.items[item.category] = node
                nodes.append(node)
            }
        }
        self.headerNode.updateCacheItems(items)
        self.cacheItemPromise.set(.single(nodes))
    }

    @objc func cleanEvent() {
        let _ = self.cleanAction?().start(next: {[weak self] progress in
            self?.headerNode.cleanProgress(progress)
        })
    }
    
}
