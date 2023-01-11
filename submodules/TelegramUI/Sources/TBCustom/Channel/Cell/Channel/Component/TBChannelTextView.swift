






import UIKit

class TBChannelTextView: UIView {
    
    let textLabel = UILabel()
    let btn = UIButton(type: .custom)
    var cellItem = TBCollectionChannelItem()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    func setupView() {
        
        textLabel.numberOfLines = 0
        textLabel.text = "The ZTE Nubia Red Magic 6 Pro pairs the world’s fastest refresh rate with an ultra-responsive touch sampling rate of up to 500Hz touch response for the smoothest ///The ZTE Nubia Red Magic 6 Pro pairs the world’s fastest refresh rate with an ultra-responsive touch sampling rate of up to 500Hz touch response for the smoothest"
        textLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textLabel.textColor = UIColor(rgb: 0x000000)
        
        btn.setTitle("", for: .normal)
        btn.setTitle("", for: .selected)
        btn.setTitleColor(UIColor(rgb: 0x4E9AD4), for: .normal)
        btn.setTitleColor(UIColor(rgb: 0x4E9AD4), for: .selected)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .black)
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        btn.addTarget(self, action: #selector(self.tapBtnAction), for: .touchUpInside)
        btn.setContentHuggingPriority(.required, for: .vertical)
        btn.setContentCompressionResistancePriority(.required, for: .vertical)
        
        self.addSubview(textLabel)
        self.addSubview(btn)
        self.batchMakeConstraints()
    }
    
    func batchMakeConstraints() {
        textLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.leading.equalTo(16)
            make.top.equalTo(0)
        }
        
        btn.snp.makeConstraints { make in
            make.top.equalTo(textLabel.snp.bottom)
            make.leading.equalTo(textLabel)
            make.bottom.equalTo(0)
        }
    }
    
    func reload(item:TBCollectionChannelItem) {
       cellItem = item
        self.btn.isSelected = (cellItem.expandStatus.can && cellItem.expandStatus.isExpand) ? true : false
        self.btn.isHidden = cellItem.expandStatus.can ? false : true
    }
    
    @objc func tapBtnAction() {
        btn.isSelected = !btn.isSelected
        cellItem.expandStatus.isExpand = btn.isSelected
        cellItem.updateLayout()
    }

}
