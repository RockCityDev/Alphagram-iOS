







import UIKit

final class EKBackgroundView: EKStyleView {

    struct Style {
        let background: EKAttributes.BackgroundStyle
        let displayMode: EKAttributes.DisplayMode
    }
    
    
    private let visualEffectView: UIVisualEffectView
    private let imageView: UIImageView
    private let gradientView: GradientView
    
    
    init() {
        imageView = UIImageView()
        visualEffectView = UIVisualEffectView(effect: nil)
        gradientView = GradientView()
        super.init(frame: UIScreen.main.bounds)
        
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.fillSuperview()
        
        addSubview(visualEffectView)
        visualEffectView.fillSuperview()
        
        addSubview(gradientView)
        gradientView.fillSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    var style: Style! {
        didSet {
            guard let style = style else {
                return
            }
            var gradient: EKAttributes.BackgroundStyle.Gradient?
            var backgroundEffect: UIBlurEffect?
            var backgroundColor: UIColor = .clear
            var backgroundImage: UIImage?
            
            switch style.background {
            case .color(color: let color):
                backgroundColor = color.color(for: traitCollection,
                                              mode: style.displayMode)
            case .gradient(gradient: let value):
                gradient = value
            case .image(image: let image):
                backgroundImage = image
            case .visualEffect(style: let value):
                backgroundEffect = value.blurEffect(for: traitCollection,
                                                    mode: style.displayMode)
            case .clear:
                break
            }
        
            gradientView.style = GradientView.Style(gradient: gradient,
                                                    displayMode: style.displayMode)
            visualEffectView.effect = backgroundEffect
            layer.backgroundColor = backgroundColor.cgColor
            imageView.image = backgroundImage
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard let style = style else { return }
        switch style.background {
        case .color(color: let color):
            layer.backgroundColor = color.color(for: traitCollection,
                                                mode: style.displayMode).cgColor
        case .visualEffect(style: let value):
            visualEffectView.effect = value.blurEffect(for: traitCollection,
                                                       mode: style.displayMode)
        default:
            break
        }
    }
}
