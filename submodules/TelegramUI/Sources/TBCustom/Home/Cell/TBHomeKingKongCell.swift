






import UIKit
import Display
import SnapKit
import Alamofire
import HandyJSON

class BasicTypes: HandyJSON {
    var int: Int = 2
    var doubleOptional: Double?
    var stringImplicitlyUnwrapped: String!

    required init() {}
    
   class func testToObject() ->Void {
        let jsonString = "{\"doubleOptional\":1.1,\"stringImplicitlyUnwrapped\":\"hello\",\"int\":1}"
        if let object = BasicTypes.deserialize(from: jsonString) {
            print(object.int)
            print(object.doubleOptional!)
            print(object.stringImplicitlyUnwrapped!)
        }
        
    }
}

class TBHomeKingKongCell: UICollectionViewCell {
    
    convenience required init(coder : NSCoder){
        self.init(frame:CGRect.zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.blue
        
        
        let centerView = UIView()
        centerView.backgroundColor = UIColor.red
        self.contentView.addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.center.equalTo(self.contentView)
        }
        
        
        AF.request("https://httpbin.org/get").response { response in
            debugPrint(response)
        }
        
        
        BasicTypes.testToObject()
        
    }
    
}
