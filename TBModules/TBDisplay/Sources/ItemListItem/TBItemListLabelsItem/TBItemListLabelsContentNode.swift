import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import TBAccount
import SnapKit
import SwiftUI
import TBWeb3Core

public class TBItemListLabelsContentNode: ASDisplayNode {
    public var contentView:TBItemListLabelsContentView?
    public let config:TBItemListLabelsContentLayoutConfig
    private var items = [TBWeb3GroupInfoEntry.Tag]()
    
    public init(config:TBItemListLabelsContentLayoutConfig) {
        self.config = config
       
        super.init()
    }

    public override func didLoad() {
        super.didLoad()
        self.contentView = TBItemListLabelsContentView(config: self.config)
        self.view.addSubview(self.contentView!)
        self.contentView!.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.contentView!.reloadView(items: self.items)
    }
    
    public func reloadView(items:[TBWeb3GroupInfoEntry.Tag]){
        self.items = items
        self.contentView?.reloadView(items: items)
    }
    
    public func deleteLabel(_ labelEntity: TBWeb3GroupInfoEntry.Tag, completion:@escaping ([TBWeb3GroupInfoEntry.Tag]) -> Void) {
        self.contentView?.deleteLabel(labelEntity, completion: completion)
    }
}

