import Foundation
import UIKit
import SDWebImage
import AsyncDisplayKit
import SwiftSignalKit

public enum TBSDImage {
    case image(UIImage?)
    case imageUrl(String, CGSize)
    
    public var size: CGSize {
        get {
            switch self {
            case .image(let image):
                return image?.size ?? .zero
            case .imageUrl(_, let size):
                return size
            }
        }
    }
    
}


public class TBSDImageNode: ASDisplayNode {
    public var image: TBSDImage? {
        didSet {
            self.safeReload(with: self.image)
        }
    }
    private var imageView: UIImageView?
    override init() {
        super.init()
    }

     public override func didLoad() {
        super.didLoad()
        self.imageView = UIImageView()
        self.view.addSubview(self.imageView!)
        self.imageView?.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.safeReload(with: self.image)
    }
    
     private func safeReload(with image:TBSDImage?) {
        Queue.mainQueue().async { [weak self] in
            if let icon = self?.image, let imageView = self?.imageView {
                switch icon {
                case .image(let image):
                    imageView.image = image
                case .imageUrl(let url, _):
                    imageView.sd_setImage(with: URL(string: url))
                }
            }else{
                self?.imageView?.image = nil
            }
        }
        
    }
}
