import Foundation
import UIKit
import SwiftSignalKit
import AppBundle
import SnapKit


public class TBEntryIndicatorView: UIView {
    
    public enum Status {
        case import_wallet_validating
        case import_wallet_building
        case import_wallet_importing
        case export_wallet_privateKey
        case creat_wallet_creating
        fileprivate func content() -> (String, String){
            switch self {
            case .import_wallet_validating:
                return("", " alphagram ")
            case .import_wallet_building: 
                return("", " alphagram ")
            case .import_wallet_importing:
                return("", " alphagram ")
            case .export_wallet_privateKey:
                return("", " ")
            case .creat_wallet_creating:
                return("", " ")
            }
        }
    }
    
    private let animationView: UIActivityIndicatorView
    private let statusLabel: UILabel
    private let desLabel: UILabel
    public init(status: Status) {
        
        self.animationView = UIActivityIndicatorView(style: .large)
        self.animationView.color = UIColor(rgb: 0x3954D5)
        self.animationView.startAnimating()
        
        self.statusLabel = UILabel()
        self.statusLabel.textColor = UIColor(rgb: 0x3954D5)
        self.statusLabel.font = .systemFont(ofSize: 18, weight: .bold)
        self.statusLabel.numberOfLines = 0
        self.statusLabel.textAlignment = .center
        
        self.desLabel = UILabel()
        self.desLabel.textColor = .white
        self.desLabel.font = .systemFont(ofSize: 13, weight: .bold)
        self.desLabel.numberOfLines = 0
        self.desLabel.textAlignment = .center
        
        super.init(frame: .zero)
        
        self.addSubview(self.animationView)
        self.addSubview(self.statusLabel)
        self.addSubview(self.desLabel)
        
        self.animationView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualTo(30)
            make.leading.greaterThanOrEqualTo(10)
            make.width.height.equalTo(44)
        }
        
        self.statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.animationView.snp.bottom).offset(20)
            make.leading.greaterThanOrEqualTo(10)
            make.bottom.lessThanOrEqualTo(-33)
        }
        
        self.desLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.snp.bottom).offset(22)
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width - 20)
           
        }
        self.updateStatus(status)
    }
    
    public func updateStatus(_ status: Status) {
        let (status, des) = status.content()
        self.statusLabel.text = status
        self.desLabel.text = des
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
