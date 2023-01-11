
import Foundation
import UIKit
import SDWebImage
import AsyncDisplayKit
import SwiftSignalKit
import SnapKit


public enum TBbuttonViewType {
    case onlyTitle
    case titleLeft
    case titleRight
}

public protocol TBbuttonViewConfig {
    
    func configGradientColors() -> [CGColor]
    func configBorderWidth() -> CGFloat
    func configBorderColor() -> CGColor
    func configBorderRadius() -> CGFloat
    func configEnbale() -> Bool
    func configAlpha() -> CGFloat
    func configSpacing() -> CGFloat
    
    func iconSizeConfig() -> CGSize
    func titleFontConfig() -> UIFont
    func buttonTypeConfig() -> TBbuttonViewType
}

public struct TBBottonViewNormalConfig {
    let gradientColors: [CGColor]
    let borderWidth: CGFloat
    let borderColor:CGColor
    let borderRadius:CGFloat
    let enbale: Bool
    let alpha: CGFloat
    let iconSize: CGSize
    let titleFont: UIFont
    let buttonType: TBbuttonViewType
    let spacing: CGFloat
    
    public init(gradientColors: [CGColor],
                borderWidth: CGFloat,
                borderColor: CGColor,
                borderRadius: CGFloat,
                enbale: Bool,
                alpha: CGFloat,
                iconSize: CGSize,
                titleFont: UIFont,
                buttonType: TBbuttonViewType,
                spacing: CGFloat = 8) {
        self.gradientColors = gradientColors
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.borderRadius = borderRadius
        self.enbale = enbale
        self.alpha = alpha
        self.iconSize = iconSize
        self.titleFont = titleFont
        self.buttonType = buttonType
        self.spacing = spacing
    }
}

extension TBBottonViewNormalConfig: TBbuttonViewConfig {
    public func configGradientColors() -> [CGColor] {
        return self.gradientColors
    }
    
    public func configBorderWidth() -> CGFloat {
        return self.borderWidth
    }
    
    public func configBorderColor() -> CGColor {
        return self.borderColor
    }
    
    public func configBorderRadius() -> CGFloat {
        return self.borderRadius
    }
    
    public func configEnbale() -> Bool {
        return self.enbale
    }
    
    public func configSpacing() -> CGFloat {
        return self.spacing
    }
    
    public func configAlpha() -> CGFloat {
        return self.alpha
    }
    
    public func iconSizeConfig() -> CGSize {
        return self.iconSize
    }
    public func titleFontConfig() -> UIFont {
        return self.titleFont
    }
    
    public func buttonTypeConfig() -> TBbuttonViewType {
        return self.buttonType
    }
}

public class TBButtonView: UIView {
    
    public class Content: UIView {
        let stackView: UIStackView
        public let icon: UIImageView
        public let activityView: UIActivityIndicatorView
        public let titleLabel: UILabel
        
       public init(config: TBbuttonViewConfig) {
            self.stackView = UIStackView()
            self.stackView.alignment = .center
            self.stackView.spacing = config.configSpacing()
            self.stackView.axis = .horizontal
            
            
            self.icon = UIImageView()
            self.icon.frame = CGRect(origin: .zero, size: config.iconSizeConfig())
            
            self.activityView = UIActivityIndicatorView(style: .medium)
            
            self.titleLabel = UILabel()
            self.titleLabel.font = config.titleFontConfig()
            
           super.init(frame: .zero)
            
            self.addSubview(self.stackView)
            
            self.stackView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }
            
            self.stackView.addArrangedSubview(self.activityView)
            
            switch config.buttonTypeConfig() {
            case .onlyTitle:
                self.stackView.addArrangedSubview(self.titleLabel)
            case .titleRight:
                self.stackView.addArrangedSubview(self.icon)
                self.stackView.addArrangedSubview(self.titleLabel)
            case .titleLeft:
                self.stackView.addArrangedSubview(self.titleLabel)
                self.stackView.addArrangedSubview(self.icon)
            }
            self.activityView.isHidden = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    let gradientLayer: CAGradientLayer
    public let contentView: Content
    public var tapBlock:(() -> Void)?
    
    public init(config: TBbuttonViewConfig) {
        self.gradientLayer = CAGradientLayer()
        self.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        self.gradientLayer.locations = [0,1]
        self.contentView = Content(config: config)
        super.init(frame: .zero)
        self.clipsToBounds = true
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
        
        self.layer.insertSublayer(self.gradientLayer, at: 0)
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        self.reload(config: config)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.bounds
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reload(config: TBbuttonViewConfig) {
        self.gradientLayer.colors = config.configGradientColors()
        self.layer.cornerRadius = config.configBorderRadius()
        self.layer.borderColor = config.configBorderColor()
        self.layer.borderWidth = config.configBorderWidth()
        self.isUserInteractionEnabled = config.configEnbale()
        self.alpha = config.configAlpha()
    }
    
    @objc func tapAction() {
        self.tapBlock?()
    }
}
