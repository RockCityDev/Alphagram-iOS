import Foundation
import UIKit
import SwiftSignalKit
import AppBundle
import SwiftEntryKit
import SnapKit


class TBEntryMessageView: UIView {
    private let conentLabel: UILabel
    private let btn: UIButton
    public init(message: String?) {
        
        self.conentLabel = UILabel()
        self.conentLabel.textColor = UIColor(rgb: 0x56565C)
        self.conentLabel.font = .systemFont(ofSize: 18, weight: .medium)
        self.conentLabel.numberOfLines = 0
        self.conentLabel.textAlignment = .center
        self.conentLabel.text = message ?? ""
        
        self.btn = UIButton(type: .custom)
        self.btn.setAttributedTitle(NSAttributedString(string: "", font:.systemFont(ofSize: 15, weight: .medium), textColor: .white), for: .normal)
        self.btn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.btn.clipsToBounds = true
        self.btn.layer.cornerRadius = 20
        self.btn.isUserInteractionEnabled = false
        
        super.init(frame: .zero)
        
        self.addSubview(self.conentLabel)
        self.addSubview(self.btn)
        
        self.conentLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(46)
            make.leading.greaterThanOrEqualTo(10)
            make.centerX.equalToSuperview()
        }
        
        self.btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.conentLabel.snp.bottom).offset(30)
            make.leading.equalTo(40)
            make.height.equalTo(40)
            make.bottom.lessThanOrEqualTo(-22)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
