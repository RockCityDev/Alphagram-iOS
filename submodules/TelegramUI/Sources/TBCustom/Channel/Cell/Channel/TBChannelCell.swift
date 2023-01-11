






import UIKit
import SnapKit
import AuthorizationUI

class TBChannelCell : UICollectionViewCell, TBCell {
    let stackContentView = UIStackView()
    let userHeaderView = TBChannelUserHeader()
    let textContainerView = TBChannelTextView()
    let imageContainer = TBChannelImageContainerView()
    let statusView = TBChannelStausView()
    let actionBar = TBChannelActionBar()
    var channelItem: TBCollectionChannelItem = TBCollectionChannelItem()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    func setupView() {
        
        stackContentView.axis = .vertical
        stackContentView.alignment = .fill
        stackContentView.distribution = .equalSpacing
        stackContentView.spacing = 0
        
        contentView.addSubview(stackContentView)
        stackContentView.addArrangedSubview(userHeaderView)
        stackContentView.addArrangedSubview(textContainerView)
        stackContentView.addArrangedSubview(imageContainer)
        stackContentView.addArrangedSubview(statusView)
        stackContentView.addArrangedSubview(actionBar)
        
        self.batchMakeConstraints()
    }
    
    func batchMakeConstraints() {
        self.updateStackSubViewLayout(false, self.channelItem.layout)
    }
    
    
    func reloadCell<T>(data: T) {
        guard let item = data as? TBCollectionChannelItem else {
            return
        }
        self.channelItem = item
        self.updateStackSubViewLayout(true, self.channelItem.layout)
        userHeaderView.reload(item: item)
        textContainerView.reload(item: item)
        imageContainer.reload(item: item)
        statusView.reload(item: item)
        actionBar.reload(item: item)
    }
    
    
    func updateStackSubViewLayout(_ isUpdate: Bool, _ layout: TBCollectionChannelItemLayout) {
        if isUpdate {
            stackContentView.snp.makeConstraints { make in
                make.leading.trailing.top.equalTo(contentView)
            }
            userHeaderView.snp.updateConstraints { make in
                make.height.equalTo(layout.userHeader.height)
            }
            textContainerView.snp.updateConstraints { make in
                make.height.equalTo(layout.textContainer.height)
            }
            imageContainer.snp.updateConstraints { make in
                make.height.equalTo(layout.imageContainer.height)
            }
            statusView.snp.updateConstraints { make in
                make.height.equalTo(layout.statusView.height)
            }
            actionBar.snp.updateConstraints { make in
                make.height.equalTo(layout.actionBar.height)
            }
        }else{
            userHeaderView.snp.makeConstraints { make in
                make.height.equalTo(layout.userHeader.height)
            }
            
            textContainerView.snp.makeConstraints { make in
                make.height.equalTo(layout.textContainer.height)
            }
            
            imageContainer.snp.makeConstraints { make in
                make.height.equalTo(layout.imageContainer.height)
            }
            
            statusView.snp.makeConstraints { make in
                make.height.equalTo(layout.statusView.height)
            }
            
            actionBar.snp.makeConstraints { make in
                make.height.equalTo(layout.actionBar.height)
            }
        }
    }
}


