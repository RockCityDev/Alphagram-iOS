
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SnapKit
import TBWeb3Core
import TBWalletCore
import TBDisplay
import SDWebImage
import TBLanguage

class TBVipGroupOrderPayAuthImplController: UIViewController {
    
    let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    func _parentViewController() -> TBVipGroupOrderPayAuthViewController {
        return self.parent as! TBVipGroupOrderPayAuthViewController
    }

    private let blurView: UIVisualEffectView
    private let contentView: UIView
    private let titleLabel: UILabel
    private let subtitleLabel: UILabel
    private let confirmImgView: UIImageView
    private let backButton: UIButton

    init(context: AccountContext) {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.blurView = UIVisualEffectView(effect:UIBlurEffect(style: .dark))
        
        self.backButton = UIButton(type: .custom)
        self.backButton.setImage(UIImage(bundleImageName: "Settings/wallet/tb_ic_back_white"), for: .normal)
        self.backButton.contentEdgeInsets = .zero
    
        self.contentView = UIView()
        self.contentView.backgroundColor = .clear
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        self.titleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.uplink_verification_title)
        self.titleLabel.textAlignment = .center
        
        self.subtitleLabel = UILabel()
        self.subtitleLabel.numberOfLines = 0
        self.subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        self.subtitleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        let format = TBLanguage.sharedInstance.localizable(TBLankey.uplink_verification_content)
        self.subtitleLabel.text = String(format: format, "30s")
        self.subtitleLabel.textAlignment = .center
        
        self.confirmImgView = UIImageView(image: UIImage(bundleImageName: "Settings/wallet/tb_auth_pay_confirm"))
        self.confirmImgView.clipsToBounds = true
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.backButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        self.view.addSubview(self.blurView)
        
        self.view.addSubview(self.backButton)
        self.view.addSubview(self.contentView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subtitleLabel)
        self.contentView.addSubview(self.confirmImgView)

        self.blurView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.backButton.snp.makeConstraints { make in
            make.top.equalTo(40)
            make.leading.equalTo(12)
            make.width.height.equalTo(24)
        }
        
        self.contentView.snp.makeConstraints { make in
            make.center.equalTo(self.view)
            make.leading.greaterThanOrEqualTo(40)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.contentView)
            make.top.greaterThanOrEqualTo(0)
            make.leading.greaterThanOrEqualTo(0)
        }
        
        self.subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.contentView)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
            make.leading.greaterThanOrEqualTo(0)
        }
        
        self.confirmImgView.snp.makeConstraints { make in
            make.centerX.equalTo(self.contentView)
            make.top.equalTo(self.subtitleLabel.snp.bottom).offset(24)
            make.width.height.equalTo(64)
            make.bottom.lessThanOrEqualTo(0)
        }
        self.creatTime()
    }
    
    private func creatTime() {
        var countDownNum = 30
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {[weak self] timer in
            if countDownNum == 0 {
                timer.invalidate()
            } else {
                countDownNum -= 1
            }
            let format = TBLanguage.sharedInstance.localizable(TBLankey.uplink_verification_content)
            self?.subtitleLabel.text = String(format: format, "\(countDownNum)s")
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition){
    }
    
    @objc func closeAction() {
        self._parentViewController().dismiss(animated: true)
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }

}
