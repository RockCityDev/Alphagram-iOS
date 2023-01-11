






import UIKit
import SnapKit
import TBWeb3Core
import TBAccount
import TelegramCore
import SwiftSignalKit
import AccountContext
import Postbox

fileprivate enum InOut: Int, Equatable{
    case `in` 
    case out 
}

extension TBUserTransferListEntity.Item {
    fileprivate func inOut() -> InOut {
       let myTgUserId = TBAccount.shared.loginData.user.tg_user_id
       if self.payment_tg_user_id == String(myTgUserId) {
           return .out
       }else{
           return .in
       }
    }
    
    func relativeWalletAddress() -> String {
        if self.inOut() == .in {
            return self.payment_account
        }else{
            return self.receipt_account
        }
    }
    
     func relativeTgUserId() -> String? {
        switch self.inOut() {
        case .in:
            return self.payment_tg_user_id.isEmpty ? nil : self.payment_tg_user_id
        case .out:
            return self.receipt_tg_user_id.isEmpty ? nil : self.receipt_tg_user_id
        }
    }
    
    func paymentInt64TgUserId() -> Int64? {
        if let paymentTgUserId = Int64(self.payment_tg_user_id), paymentTgUserId > 0{
            return paymentTgUserId
        }else{
            return nil
        }
    }
    
    func receiptInt64TgUserId() -> Int64? {
        if let receiptTgUserId = Int64(self.receipt_tg_user_id), receiptTgUserId > 0{
            return receiptTgUserId
        }else{
            return nil
        }
    }
    func relativeInt64TgUserId() -> Int64? {
        if let relativeTgUserId = Int64(self.relativeTgUserId() ?? ""), relativeTgUserId > 0 {
            return relativeTgUserId
        }
        return nil
    }
    
    func int64tgUserIdSet() -> Set<Int64> {
        var ret = Set<Int64>()
        if let id = self.paymentInt64TgUserId(){
            ret.insert(id)
        }
        if let id = self.receiptInt64TgUserId(){
            ret.insert(id)
        }
        return ret
    }
}

public class TBTransferToItRencentTransactionCell:UICollectionViewCell {
    
    let avatar: TBAvatarView
    let titleLabel: UILabel
    let addressLabel: UILabel
    let amountLabel: UILabel
    let inoutIcon: UIImageView
    var releativeUserDisposable: Disposable?
    var releativeTgUser: TelegramUser?
    
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
        
        self.amountLabel = UILabel()
        self.amountLabel.numberOfLines = 1
        self.amountLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.amountLabel.textColor = UIColor(rgb: 0x1A1A1D, alpha: 0.5)
        
        self.inoutIcon = UIImageView()
        self.inoutIcon.contentMode = .scaleAspectFit
    
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.avatar)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.addressLabel)
        self.contentView.addSubview(self.amountLabel)
        self.contentView.addSubview(self.inoutIcon)
        
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
        
        self.inoutIcon.snp.makeConstraints { make in
            make.centerY.trailing.equalTo(self.contentView)
            make.width.height.equalTo(13)
        }
        
        self.amountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.trailing.equalTo(self.inoutIcon.snp.leading).offset(-2)
            make.leading.greaterThanOrEqualTo(self.addressLabel.snp.trailing).offset(2)
        }
    }
    
    func reloadCell(item: TBUserTransferListEntity.Item, context: AccountContext) {
        self.releativeUserDisposable?.dispose()

        self.titleLabel.isHidden = true
        self.addressLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(self.titleLabel)
            make.trailing.lessThanOrEqualTo(0)
            make.width.lessThanOrEqualTo(88)
        }
        
        self.addressLabel.text = item.inOut()  == InOut.in ? item.payment_account : item.receipt_account
        self.amountLabel.text = (item.inOut() == InOut.in ? "+" : "-") + item.amount + item.currency_name
       
        if let relativeId =  item.relativeInt64TgUserId() {
            let relativePeerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: PeerId.Id._internalFromInt64Value(relativeId))
            self.releativeUserDisposable = (context.engine.data.subscribe(
                TelegramEngine.EngineData.Item.Peer.Peer(id: relativePeerId)
            ) |> deliverOnMainQueue).start(next: { [weak self] data in
                if let tgUser = data?._asPeer() as? TelegramUser{
                    self?.releativeTgUser = tgUser
                    self?.titleLabel.text = (tgUser.firstName ?? "") + " " + (tgUser.lastName ?? "")
                    self?.avatar.reloadAvatar(context: context, tgUser: tgUser)
                    if let strongSelf = self {
                        strongSelf.addressLabel.snp.remakeConstraints { make in
                            make.bottom.equalTo(strongSelf.avatar)
                            make.leading.equalTo(strongSelf.titleLabel)
                            make.trailing.lessThanOrEqualTo(0)
                            make.width.lessThanOrEqualTo(88)
                        }
                    }
                    self?.titleLabel.isHidden = false
                }else{
                    self?.avatar.reloadAvatar(context: context)
                    self?.releativeTgUser = nil
                }
            })
        }else{
            self.avatar.reloadAvatar(context: context)
        }
    }
    
    deinit {
        self.releativeUserDisposable?.dispose()
    }
    
}

