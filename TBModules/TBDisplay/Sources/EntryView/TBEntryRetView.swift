import Foundation
import UIKit
import SwiftSignalKit
import AppBundle
import SnapKit


public class TBEntryRetView: UIView {
    
    fileprivate struct Config {
        let image: UIImage?
        let title: String
        let content: String
        let buttonName: String
    }
    
    public enum Status {
        case import_wallet_success
        case import_wallet_failed
        fileprivate func content() -> Config{
            switch self {
            case .import_wallet_success:
                return Config(
                    image: UIImage(bundleImageName: "TBMyWallet/icon_success_dialog"),
                    title: "",
                    content: "",
                    buttonName: ""
                )
            case .import_wallet_failed:
                return Config(
                    image: UIImage(bundleImageName: "TBMyWallet/icon_fail_dialog"),
                    title: "",
                    content: "",
                    buttonName: ""
                )
            }
        }
    }
    
    private let iconView: UIImageView
    private let titleLabel: UILabel
    private let contentLabel: UILabel
    private let btn: UIButton
    public var btnAction:(() -> Void)?
    
    public init(status: Status) {
        
        self.iconView = UIImageView()
        
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor(rgb: 0x3954D5)
        self.titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        self.titleLabel.numberOfLines = 0
        self.titleLabel.textAlignment = .center
        
        self.contentLabel = UILabel()
        self.contentLabel.textColor = UIColor(rgb: 0x56565C)
        self.contentLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.contentLabel.numberOfLines = 0
        self.contentLabel.textAlignment = .center
        
        self.btn = UIButton(type: .custom)
        self.btn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.btn.clipsToBounds = true
        self.btn.layer.cornerRadius = 20
        
        super.init(frame: .zero)
        
        self.addSubview(self.iconView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.contentLabel)
        self.addSubview(self.btn)
        
        self.iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(self.snp.top)
            make.width.height.equalTo(54)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.iconView.snp.bottom).offset(15)
            make.leading.greaterThanOrEqualTo(10)
        }
        
        self.contentLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(6)
            make.leading.greaterThanOrEqualTo(10)
        }
        
        self.btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.contentLabel.snp.bottom).offset(28)
            make.height.equalTo(40)
            make.leading.equalTo(40)
            make.bottom.equalTo(-22)
        }
        
        self.btn.addTarget(self, action: #selector(self.btnTapAction), for: .touchUpInside)
        
        let config = status.content()
        self.iconView.image = config.image
        self.titleLabel.text = config.title
        self.contentLabel.text = config.content
        self.btn.setAttributedTitle(NSAttributedString(string: config.buttonName, font:.systemFont(ofSize: 15, weight: .medium), textColor: .white), for: .normal)
    }
    
    @objc private func btnTapAction() {
        self.btnAction?()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
