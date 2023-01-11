import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AppBundle
import AccountContext
import PresentationDataUtils
import TBWeb3Core
import TBDisplay
import SDWebImage

extension UIImage {
    func supposedSizeWithFixWidth(_ fixWidth: CGFloat) -> CGSize {
        guard self.size.width > 0 else {
            return CGSize(width: fixWidth, height: self.size.height)
        }
        let h = self.size.height * (fixWidth / self.size.width)
        return CGSize(width: fixWidth, height: h)
    }
    func supposedSizeWithFixHeight(_ fixHeight: CGFloat) -> CGSize {
        guard self.size.height > 0 else {
            return CGSize(width: self.size.width, height: fixHeight)
        }
        let w = self.size.width * (fixHeight / self.size.height)
        return CGSize(width: w, height: fixHeight)
    }
}



public class TBInviteGroupInfoView: UIView {
    
    private let avatar: UIImageView
    private let logo: UIImageView
    private let titleLabel: UILabel
    private let infoLabel: UILabel
    private let desLabel: UILabel
    
    private let readyPromise = ValuePromise(false, ignoreRepeated: true)
    
    public init(groupInfo: TBWeb3GroupInfoEntry, width:CGFloat = 276) {
        
        self.avatar = UIImageView()
        self.avatar.contentMode = .scaleAspectFit
        
        self.logo = UIImageView(image: UIImage(bundleImageName: "TBWebPage/logo_alphagram"))
        self.logo.contentMode = .scaleAspectFit
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        self.titleLabel.textColor = .black
        
        self.infoLabel = UILabel()
        self.infoLabel.numberOfLines = 0
        self.infoLabel.font = .systemFont(ofSize: 13, weight: .regular)
        self.infoLabel.textColor = UIColor(rgb: 0x828283)
        
        self.desLabel = UILabel()
        self.desLabel.numberOfLines = 0
        self.desLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.desLabel.textColor = .black
        
        super.init(frame: .zero)
        
        
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
        self.layer.cornerRadius = 15
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.cgColor
        
        self.addSubview(self.avatar)
        self.avatar.addSubview(self.logo)
        self.addSubview(self.titleLabel)
        self.addSubview(self.infoLabel)
        self.addSubview(self.desLabel)
        
        self.avatar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.width.equalTo(width)
            make.height.equalTo(width)
        }
        self.logo.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(-12)
            make.width.height.equalTo(40)
        }
        
        self.titleLabel.preferredMaxLayoutWidth = width - 16 * 2
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.avatar.snp.bottom).offset(8)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
        }
        
        self.infoLabel.preferredMaxLayoutWidth = width - 16 * 2
        self.infoLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalTo(self.titleLabel)
        }
        
        self.desLabel.preferredMaxLayoutWidth = width - 16 * 2
        self.desLabel.snp.makeConstraints { make in
            make.top.equalTo(self.infoLabel.snp.bottom).offset(7)
            make.leading.trailing.equalTo(self.titleLabel)
            make.bottom.equalTo(-10)
        }
        
        self.titleLabel.text = groupInfo.title
        self.infoLabel.text = groupInfo.description
        self.desLabel.text = "\(groupInfo.title) ，"
        
        self.avatar.sd_setImage(with: URL(string: groupInfo.avatar), placeholderImage: UIImage(bundleImageName: "TBWallet/avatar"), completed: {
            image, _, _, _ in
                if let image = image {
                    self.avatar.snp.updateConstraints({ make in
                        make.height.equalTo(image.supposedSizeWithFixWidth(width).height)
                    })
                }
                self.readyPromise.set(true)
        })
    }
    
    
    private func readySignal() -> Signal<Bool, NoError> {
        return self.readyPromise.get() |> filter({$0==true}) |> take(1) |> deliverOnMainQueue
    }
    
    
    public func transformSignal() -> Signal<UIImage, NoError> {
        return (self.readySignal() |> mapToThrottled({ _ in
            return Signal { subscriber in
                Queue.mainQueue().async {
                    subscriber.putNext(TBInviteGroupInfoView.getViewScreenshot(view: self))
                    subscriber.putCompletion()
                }
                return EmptyDisposable
            }
        })) |> deliverOnMainQueue
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private static func getViewScreenshot(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let extractImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return extractImage!;

    }
    
}
