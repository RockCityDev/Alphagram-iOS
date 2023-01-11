



import UIKit
import CoreImage.CIFilterBuiltins
import Display
import AccountContext
import TelegramPresentationData
import SnapKit


class TBWalletHandshakeViewController: ViewController {
    let qrCodeImageView: UIImageView
    let code: String
    
    private let context : AccountContext
    private let presentationData: PresentationData
    
    public init(context: AccountContext, code: String) {
        self.context = context
        self.code = code
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let baseNavigationBarPresentationData = NavigationBarPresentationData(presentationData: self.presentationData)
        self.qrCodeImageView = UIImageView()
        self.qrCodeImageView.contentMode = .scaleAspectFit
        super.init(navigationBarPresentationData: NavigationBarPresentationData(
            theme: NavigationBarTheme(
                buttonColor: baseNavigationBarPresentationData.theme.buttonColor,
                disabledButtonColor: baseNavigationBarPresentationData.theme.disabledButtonColor,
                primaryTextColor: baseNavigationBarPresentationData.theme.primaryTextColor,
                backgroundColor: .clear,
                enableBackgroundBlur: false,
                separatorColor: .clear,
                badgeBackgroundColor: baseNavigationBarPresentationData.theme.badgeBackgroundColor,
                badgeStrokeColor: baseNavigationBarPresentationData.theme.badgeStrokeColor,
                badgeTextColor: baseNavigationBarPresentationData.theme.badgeTextColor
        ), strings: baseNavigationBarPresentationData.strings))
        self.title = ""
        self.tabBarItem.title = nil

    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.view.backgroundColor = UIColor.white
        
        let data = Data(code.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")

        let outputImage = filter.outputImage!
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
        let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent)!
        
        self.qrCodeImageView.image = UIImage(cgImage: cgImage)
        self.displayNode.view.addSubview(self.qrCodeImageView)
        self.qrCodeImageView.snp.makeConstraints { make in
            make.center.equalTo(self.displayNode.view)
            make.leading.equalTo(self.displayNode.view).offset(20)
            make.width.equalTo(self.qrCodeImageView.snp.height)
        }
    }
}
