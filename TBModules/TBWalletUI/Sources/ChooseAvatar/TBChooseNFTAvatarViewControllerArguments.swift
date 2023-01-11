






import UIKit
import SnapKit

public class TBChooseNFTAvatarViewControllerArguments {
    
    let didChooseOrignalImage : (UIImage, TBAssetItem)->Void
    
    public init(didChooseOrignalImage:@escaping (UIImage, TBAssetItem)->Void) {
        self.didChooseOrignalImage = didChooseOrignalImage
    }
    
}

