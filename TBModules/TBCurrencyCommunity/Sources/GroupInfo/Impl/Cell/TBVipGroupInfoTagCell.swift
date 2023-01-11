






import UIKit
import SnapKit
import TBWeb3Core
import TBDisplay
import TBLanguage

public class TBVipGroupInfoTagCell:UICollectionViewCell {
    
    private let topline: UIView
    private let titleLabel: UILabel
    private var tagsView: TBItemListLabelsContentView?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.topline = UIView()
        self.topline.backgroundColor = UIColor(rgb: 0xF6F6F6)
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x2F2F33)
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_join_tag_title)
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.topline)
        self.contentView.addSubview(self.titleLabel)
        self.topline.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(0)
            make.height.equalTo(1)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.topline.snp.bottom).offset(12)
            make.leading.equalTo(16)
            make.trailing.equalTo(16)
            make.height.equalTo(19)
        }
        
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry, tagsConfig: TBItemListLabelsContentLayoutConfig) {
        if self.tagsView == nil {
            let tagsView = TBItemListLabelsContentView(config: tagsConfig)
            self.contentView.addSubview(tagsView)
            tagsView.snp.makeConstraints { make in
                make.top.equalTo(self.titleLabel.snp.bottom).offset(0)
                make.leading.trailing.bottom.equalTo(self.contentView)
            }
            self.tagsView = tagsView
        }
        if let tagsView = self.tagsView {
            tagsView.reloadView(items: item.tags)
        }
    }

    
}

