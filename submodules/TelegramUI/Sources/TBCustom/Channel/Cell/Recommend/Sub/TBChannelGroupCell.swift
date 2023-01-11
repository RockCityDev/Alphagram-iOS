






import UIKit
import SnapKit
import SDWebImage
import AuthorizationUI

class TBChannelGroupCel : UICollectionViewCell, TBCell {
    
    let imgView = UIImageView()
    let titleLabel = UILabel()
    let subscribeTitleLabel = UILabel()
    let joinBtn = UIButton(type:.custom)
    
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
        titleLabel.text = "Solana"
        titleLabel.numberOfLines = 1
        
        subscribeTitleLabel.textColor = UIColor(rgb: 0x868686)
        subscribeTitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        subscribeTitleLabel.text = "10.5k "
        subscribeTitleLabel.numberOfLines = 1
        
        joinBtn.titleLabel?.textColor = UIColor(rgb: 0xFFFFFF)
        joinBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        joinBtn.setTitle("", for: .normal)
        joinBtn.backgroundColor = UIColor(rgb: 0x03BDFF)
        joinBtn.addTarget(self, action: #selector(self.tapJoinAction), for: .touchUpInside)
        joinBtn.layer.masksToBounds = true
        joinBtn.layer.cornerRadius = 5
        joinBtn.setContentHuggingPriority(.required, for: .horizontal)
        joinBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        joinBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() {
        
        contentView.addSubview(imgView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subscribeTitleLabel)
        contentView.addSubview(joinBtn)
        
        imgView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(8)
            make.width.height.equalTo(42)
        }
        
        joinBtn.snp.makeConstraints { make in
            make.centerY.equalTo(imgView)
            make.trailing.equalTo(-10)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(imgView.snp.centerY)
            make.leading.equalTo(imgView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(joinBtn).offset(-11)
        }
        
        subscribeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(imgView.snp.centerY)
            make.leading.equalTo(imgView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(joinBtn).offset(-11)
        }
    }
    
    @objc func tapJoinAction() {
        debugPrint("[TB]: tap ")
    }
    
    
    func reloadCell<T>(data: T) {
        
    }
    
    
}
