






import UIKit
import SnapKit
import TelegramPresentationData
import SDWebImage

public class TBNFTAvatarCell:UICollectionViewCell {
    
    let imgView: UIImageView
    let titleLabel: UILabel
    let subTitleLabel: UILabel
    let iconView: UIImageView
    let priceLabel: UILabel
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.imgView = UIImageView()
        self.imgView.contentMode = .scaleAspectFill
        self.imgView.layer.cornerRadius = 5
        self.imgView.clipsToBounds = true
        //self.imgView.sd_setImage(with: URL(string: "https://cdn.pixabay.com/photo/2014/12/16/22/25/woman-570883_1280.jpg")!)
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.titleLabel.textColor = .black
        //self.titleLabel.text = "Phanta Bear"
        
        self.subTitleLabel = UILabel()
        self.subTitleLabel.numberOfLines = 1
        self.subTitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        self.subTitleLabel.textColor = UIColor(rgb: 0x868E95)
        //self.subTitleLabel.text = "Phanta Bear #001"
        
        self.iconView = UIImageView(image: PresentationResourcesSettings.tb_icon_eth_nft_edit)
        self.iconView.contentMode = .scaleAspectFit
        
        self.priceLabel = UILabel()
        self.priceLabel.numberOfLines = 1
        self.priceLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        self.priceLabel.textColor = .black
        //self.priceLabel.text = "154.07"
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor(rgb: 0xE6E6E6).cgColor
        self.contentView.clipsToBounds = true
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.imgView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subTitleLabel)
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.priceLabel)
        
        self.imgView.snp.makeConstraints { make in
            make.top.leading.equalTo(11)
            make.centerX.equalTo(self.contentView)
            make.height.equalTo(self.imgView.snp.width)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(25)
            make.top.equalTo(self.imgView.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualTo(-11)
        }
        self.subTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(-11)
        }
        self.iconView.snp.makeConstraints { make in
            make.leading.equalTo(22)
            make.top.equalTo(self.subTitleLabel.snp.bottom).offset(5)
            make.width.height.equalTo(13)
        }
        self.priceLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.iconView.snp.trailing).offset(3)
            make.centerY.equalTo(self.iconView)
            make.trailing.lessThanOrEqualTo(-11)
        }
    }
    
    public func reloadCell(item: TBAssetItem) {
        if let url = URL(string: item.thumb_url) {
            self.imgView.sd_setImage(with: url)
        }
        self.titleLabel.text = item.asset_name
        self.subTitleLabel.text = item.nft_name
        self.priceLabel.text = item.presentPrice
    }

    
}

