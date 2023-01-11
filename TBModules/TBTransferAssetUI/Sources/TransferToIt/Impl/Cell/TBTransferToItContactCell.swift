






import UIKit
import SnapKit
import TBWeb3Core
import TBAccount
import TelegramCore
import AvatarNode
import AccountContext
import SwiftSignalKit

public class TBAvatarView: UIView {
    let imageView:UIImageView
    var avatarDisposable: Disposable?
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        self.imageView = UIImageView(image: TBAvatarView.placeHolderImage())
        self.imageView.backgroundColor = UIColor(rgb: 0x02ABFF)
        super.init(frame: frame)
        self.addSubview(self.imageView)
        self.backgroundColor = .clear
    }
    
    public func reloadAvatar(context:AccountContext, tgUser: TelegramUser? = nil, url: URL? = nil) {
        self.avatarDisposable?.dispose()
        if let tgUser = tgUser {
            self.updateAvatarBy(context: context, user: tgUser)
        }else {
            self.imageView.sd_setImage(with: url, placeholderImage: TBAvatarView.placeHolderImage())
        }
    }

    private func updateAvatarBy(context: AccountContext, user: TelegramUser) {
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 40,height: 40)) {
            self.avatarDisposable = (signal |> deliverOnMainQueue).start {[weak self] a in
                self?.updateAvaterImage(image: a?.0)
            }
        }else {
            self.updateAvaterImage(image: nil)
        }
    }
    
    private func updateAvaterImage(image: UIImage?) {
        if let image = image {
            self.imageView.image = image
        }else{
            self.imageView.image = TBAvatarView.placeHolderImage()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = self.bounds.height / 2.0
    }
    
    public class func placeHolderImage() -> UIImage? {
        return UIImage(bundleImageName: "TBWallet/TransferAsset/ic_avatar_placeholder")
    }
    
    deinit {
        self.avatarDisposable?.dispose()
    }
}

public class TBTransferToItContactCell:UICollectionViewCell {
    
    let avatar: TBAvatarView
    let titleLabel: UILabel
    let addressLabel: UILabel

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.avatar = TBAvatarView()

        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x1A1A1D)
        
        self.addressLabel = UILabel()
        self.addressLabel.numberOfLines = 1
        self.addressLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.addressLabel.textColor = UIColor(rgb: 0x1A1A1D, alpha: 0.5)
        self.addressLabel.lineBreakMode = .byTruncatingMiddle
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.avatar)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.addressLabel)
        
        self.avatar.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(0)
            make.width.height.equalTo(40)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.avatar)
            make.leading.equalTo(self.avatar.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(0)
        }
        
        self.addressLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self.avatar)
            make.leading.equalTo(self.titleLabel)
            make.trailing.lessThanOrEqualTo(0)
            make.width.lessThanOrEqualTo(88)
        }
    }
    
    func reloadCell(context:AccountContext, entry: TBVipContactListEntry) {
        self.avatar.reloadAvatar(context: context, tgUser: entry.tgUser)
        self.titleLabel.text = (entry.tgUser.firstName ?? "") + " " + (entry.tgUser.lastName ?? "")
        self.addressLabel.text = entry.tgInfo.wallet_info.first?.wallet_address ?? ""
    }

}

