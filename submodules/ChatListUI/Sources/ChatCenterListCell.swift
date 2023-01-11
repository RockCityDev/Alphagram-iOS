import UIKit

class ChatCenterListCell: UITableViewCell {

    let itemNode = ChatListItemNode()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.itemNode.view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.itemNode.frame = self.bounds
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

class ChatCenterListHeaderView: UITableViewHeaderFooterView {
    
    let titleLabel: UILabel
    
    override init(reuseIdentifier: String?) {
        self.titleLabel = UILabel()
        
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor(rgb: 0xF7F8F9)
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(titleLabel)
        self.titleLabel.frame = CGRect(x: 16, y: 0, width: 280, height: 30)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
