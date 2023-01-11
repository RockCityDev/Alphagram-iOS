






import UIKit
import SnapKit
import TBWeb3Core
import SDWebImage

public class TBTransferToItListPlaceholderCell: UICollectionViewCell {

    let placeHolderView: UIImageView
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.placeHolderView = UIImageView()
        self.placeHolderView.contentMode = .scaleAspectFit
        self.placeHolderView.clipsToBounds = true
        self.placeHolderView.image = UIImage(bundleImageName: "TBWallet/TransferAsset/ic_transfer_list_placeholder")
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.placeHolderView)
        self.placeHolderView.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.centerY.equalTo(self.contentView)
            make.height.equalTo(40)
            make.width.equalTo(250)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}

