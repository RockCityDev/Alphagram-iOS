






import UIKit
import SnapKit
import AuthorizationUI

class TBChannelExploreGroupCell : UICollectionViewCell, TBCell {
    let imgView = UIImageView()
    let titleLabel = UILabel()
    let subscribeTitleLabel = UILabel()
    let showAllBtn = UIButton(type:.custom)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor.white
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.borderColor = UIColor(rgb: 0xE6E6E6).cgColor
        self.contentView.layer.borderWidth = 1
        self.setupView()
    }
    
    func setupView() {
        
        imgView.layer.cornerRadius = 21
        imgView.layer.masksToBounds = true
        imgView.sd_setImage(with: URL(string: "https://cdn.pixabay.com/photo/2022/07/21/02/46/wedding-7335258_1280.jpg"))
    
        titleLabel.textColor = UIColor(rgb: 0x000000)
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.text = ""
        titleLabel.numberOfLines = 1
        
        subscribeTitleLabel.textColor = UIColor(rgb: 0x868686)
        subscribeTitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        subscribeTitleLabel.text = ""
        subscribeTitleLabel.numberOfLines = 1
        
        showAllBtn.titleLabel?.textColor = UIColor(rgb: 0xFFFFFF)
        showAllBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        showAllBtn.setTitle("", for: .normal)
        showAllBtn.backgroundColor = UIColor(rgb: 0x03BDFF)
        showAllBtn.addTarget(self, action: #selector(self.tapShowAllAction), for: .touchUpInside)
        showAllBtn.layer.masksToBounds = true
        showAllBtn.layer.cornerRadius = 5
        showAllBtn.setContentHuggingPriority(.required, for: .horizontal)
        showAllBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        showAllBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() {
        
        contentView.addSubview(imgView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subscribeTitleLabel)
        contentView.addSubview(showAllBtn)
        
        imgView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(8)
            make.width.height.equalTo(42)
        }
        
        showAllBtn.snp.makeConstraints { make in
            make.centerY.equalTo(imgView)
            make.trailing.equalTo(-10)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(imgView.snp.centerY)
            make.leading.equalTo(imgView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(showAllBtn).offset(-11)
        }
        
        subscribeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(imgView.snp.centerY)
            make.leading.equalTo(imgView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(showAllBtn).offset(-11)
        }
    }
    
    @objc func tapShowAllAction() {
        debugPrint("[TB]: tap ")
    }
    
    
    func reloadCell<T>(data: T) {
        
    }
}
