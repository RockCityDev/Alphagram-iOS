
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SnapKit
import TBDisplay
import TBWeb3Core

class TBGroupLabelImplController: UIViewController {
    let context: AccountContext
    private let updateBlock: ([TBWeb3GroupInfoEntry.Tag]) -> Void
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private func _parentViewController() -> TBGroupLabelController {
        return self.parent as! TBGroupLabelController
    }
    private var layout: ContainerViewLayout?
    
    
    private let selectedTagsView: TBItemListLabelsContentView
    private var selectedTags = [TBWeb3GroupInfoEntry.Tag]()
    
    private let hotTitleLabel: UILabel
    
    
    private let hotTagsView: TBItemListLabelsContentView
    private var hotTags = [TBWeb3GroupInfoEntry.Tag]()
    

    init(context: AccountContext, initialLabels:[TBWeb3GroupInfoEntry.Tag], update:@escaping ([TBWeb3GroupInfoEntry.Tag]) -> Void){
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.selectedTagsView = TBItemListLabelsContentView(config: TBItemListLabelsContentLayoutConfig(viewType: .normal))
        
        self.hotTitleLabel = UILabel()
        self.hotTitleLabel.text = ""
        self.hotTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        self.hotTitleLabel.textColor = UIColor(rgb: 0x1A1A1D)
        self.hotTitleLabel.numberOfLines = 1
    
        self.hotTagsView = TBItemListLabelsContentView(config: TBItemListLabelsContentLayoutConfig(viewType: .special))
        self.updateBlock = update
        super.init(nibName: nil, bundle: nil)
        
        self.selectedTagsView.didSelectItemBlock = {[weak self] tag in
            if let strongSelf = self {
                strongSelf.selectedTags.removeAll { item in
                    return item == tag
                }
                strongSelf.reloadAllTagsView()
            }
        }
        self.hotTagsView.didSelectItemBlock = {[weak self] tag in
            if let strongSelf = self {
                if strongSelf.selectedTags.contains(tag){
                    strongSelf.selectedTags.removeAll { item in
                        return item == tag
                    }
                }else{
                    strongSelf.selectedTags.append(tag)
                }
                strongSelf.reloadAllTagsView()
            }
        }
        
        self.selectedTags = initialLabels
        self.reloadAllTagsView()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(rgb: 0xF0F1F4)
        self.view.addSubview(self.selectedTagsView)
        self.view.addSubview(self.hotTitleLabel)
        self.view.addSubview(self.hotTagsView)
        self.selectedTagsView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view)
            make.height.equalTo(0)
        }
        
        self.hotTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.top.equalTo(self.selectedTagsView.snp.bottom).offset(10)
        }
        
        self.hotTagsView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(self.hotTitleLabel.snp.bottom).offset(10)
            make.height.equalTo(0)
        }
        
        self.refreshHotTags()
        

    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition){
        self.layout = layout
        self.reloadAllTagsView()
    }
    
    private func refreshHotTags() {
        let _ = TBWeb3GroupInteractor().web3HotTagsSignal().start(next: {[weak self] tags in
            if let strongSelf = self {
                strongSelf.hotTags = tags
                strongSelf.reloadAllTagsView()
            }
        })
    }
    
    private func reloadAllTagsView() {
        
        guard let layout = self.layout else {
            return
        }
        
        self.hotTags = self.hotTags.map({ item in
            var item = item
            if self.selectedTags.contains(item){
                item.selected = true
            }else{
                item.selected = false
            }
            return item
        })
        
        self.selectedTagsView.reloadView(items: self.selectedTags)
        let selectedTagsViewSize = self.selectedTagsView.config.contentSize(items:self.selectedTags, maxWidth:layout.size.width)
        self.selectedTagsView.snp.updateConstraints { make in
            make.height.equalTo(selectedTagsViewSize.height)
        }
        
        self.hotTagsView.reloadView(items: self.hotTags)
        let hotTagsViewSize = self.hotTagsView.config.contentSize(items: self.hotTags, maxWidth: layout.size.width)
        self.hotTagsView.snp.updateConstraints { make in
            make.height.equalTo(hotTagsViewSize.height)
        }
        self.updateBlock(self.selectedTags)
    }

    deinit {
        self.presentationDataDisposable?.dispose()
    }
    

}







