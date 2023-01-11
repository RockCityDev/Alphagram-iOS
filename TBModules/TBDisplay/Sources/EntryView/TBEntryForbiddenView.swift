import Foundation
import UIKit
import SwiftSignalKit
import AppBundle
import SnapKit


public class TBEntryForbiddenView: UIView {
    
    fileprivate struct Config {
        let image: UIImage?
        let title: String
        let content: String
        let buttonName: String
    }
    
    public enum Status {
        case screen_shot
        fileprivate func content() -> Config{
            switch self {
            case .screen_shot:
                return Config(
                    image: UIImage(bundleImageName: "TBMyWallet/ic_forbidden_screenshot"),
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
    public var btnAction:(() -> Void)? {
        didSet {
            if let _ = self.btnAction {
                self.btn.isUserInteractionEnabled = true
            }else{
                self.btn.isUserInteractionEnabled = false
            }
        }
    }
    
    public init(status: Status) {
        
        self.iconView = UIImageView()
        
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        self.titleLabel.numberOfLines = 0
        self.titleLabel.textAlignment = .center
        
        self.contentLabel = UILabel()
        self.contentLabel.textColor = UIColor(rgb: 0x56565C)
        self.contentLabel.font = .systemFont(ofSize: 15, weight: .regular)
        self.contentLabel.numberOfLines = 0
        self.contentLabel.textAlignment = .center
        
        self.btn = UIButton(type: .custom)
        self.btn.backgroundColor = .clear
        self.btn.isUserInteractionEnabled = false
        
        super.init(frame: .zero)
        
        self.addSubview(self.iconView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.contentLabel)
        self.addSubview(self.btn)
        
        self.iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(20)
            make.width.height.equalTo(62)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.iconView.snp.bottom).offset(12)
            make.leading.greaterThanOrEqualTo(20)
        }
        
        self.contentLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(12)
            make.leading.greaterThanOrEqualTo(20)
        }
        
        self.btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.contentLabel.snp.bottom).offset(12)
            make.height.equalTo(40)
            make.leading.equalTo(20)
            make.bottom.equalTo(-20)
        }
        
        self.btn.addTarget(self, action: #selector(self.btnTapAction), for: .touchUpInside)
        
        let config = status.content()
        self.iconView.image = config.image
        self.titleLabel.text = config.title
        self.contentLabel.text = config.content
        self.btn.setAttributedTitle(NSAttributedString(string: config.buttonName, font:.systemFont(ofSize: 18, weight: .medium), textColor: UIColor(rgb: 0x3954D5)), for: .normal)
    }
    
    @objc private func btnTapAction() {
        self.btnAction?()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
