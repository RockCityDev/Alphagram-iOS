






import UIKit

class TBChannelUserHeader: UIView {
    
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let timeLabel = UILabel()
    let moreBtn = UIButton(type: .custom)
   
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    func setupView() {
        iconView.contentMode = .scaleAspectFill
        iconView.sd_setImage(with: URL(string: "https://cdn.pixabay.com/photo/2022/07/21/02/46/wedding-7335258_1280.jpg"))
        iconView.layer.masksToBounds = true
        iconView.layer.cornerRadius = 18
        
        moreBtn.setImage(UIImage(bundleImageName: "TabBar/btn_index_navagation_on"), for: .normal)
        moreBtn.addTarget(self, action: #selector(self.tapMoreAction), for: .touchUpInside)
        
        nameLabel.text = "Channel Name"
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        nameLabel.textColor = UIColor(rgb: 0x46BDFE)
        nameLabel.numberOfLines = 1
        
        timeLabel.text = "06/21 03:35"
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = UIColor(rgb: 0x868686)
        timeLabel.numberOfLines = 1
        
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(timeLabel)
        self.addSubview(moreBtn)
        self.batchMakeConstraints()
    }
    
    func batchMakeConstraints() {
        iconView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(16)
            make.width.height.equalTo(36)
        }
        
        moreBtn.snp.makeConstraints { make in
            make.trailing.equalTo(-12)
            make.centerY.equalTo(self)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.bottom.equalTo(iconView.snp.centerY)
            make.trailing.lessThanOrEqualTo(moreBtn.snp.leading).offset(-12)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(iconView.snp.centerY)
            make.trailing.lessThanOrEqualTo(moreBtn.snp.leading).offset(-12)
        }
        
    }
    
    @objc func tapMoreAction() {
        debugPrint("[TB]: tapMoreAction")
    }
    
    func reload(item:TBCollectionChannelItem) {
        
    }

}
