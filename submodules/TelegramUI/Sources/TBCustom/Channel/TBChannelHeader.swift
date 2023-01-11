






import UIKit
import SnapKit

class TBChannelHeader : UIView {
    let iconView : UIImageView = UIImageView(image: UIImage(bundleImageName: "Chat List/EmptyMasterDetailIcon"))
    let titleView : UILabel = UILabel()
    let refreshView : UIImageView = UIImageView(image: UIImage(bundleImageName: "Chat List/EmptyMasterDetailIcon"))
    let lineView : UIView = UIView()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    func setupViews() -> Void {
        titleView.text = ""
        titleView.textColor = UIColor(rgb: 0x000000, alpha: 0.87)
        titleView.font = UIFont.systemFont(ofSize: 23, weight: UIFont.Weight.medium)
        lineView.backgroundColor = UIColor(rgb: 0xE6E6E6, alpha: 1)
        self.batchMakeConstraints()
    }
    
    func batchMakeConstraints() {
        
        self.addSubview(iconView)
        self.addSubview(titleView)
        self.addSubview(refreshView)
        self.addSubview(lineView)
        
        iconView.snp.remakeConstraints { make in
            make.width.height.equalTo(55)
            make.bottom.equalTo(0)
            make.leading.equalTo(8)
        }
        
        titleView.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(9)
            make.trailing.greaterThanOrEqualTo(refreshView.snp.leading)
        }
        
        refreshView.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.trailing.equalTo(-9)
            make.width.height.equalTo(30)
        }
        refreshView.isUserInteractionEnabled = true
        refreshView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.refreshAction)))
        
        lineView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(0);
            make.height.equalTo(1)
        }
        
    }
    
   @objc func refreshAction() {
        debugPrint("tb-tap refresh")
    }
}
