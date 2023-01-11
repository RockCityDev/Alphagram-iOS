import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramCore
import Postbox
import TextFormat
import UrlEscaping
import TelegramUniversalVideoContent
import TextSelectionNode
import InvisibleInkDustNode
import Emoji
import AnimatedStickerNode
import TelegramAnimatedStickerNode
import SwiftSignalKit
import AccountContext
import YuvConversion
import AnimationCache
import LottieAnimationCache
import MultiAnimationRenderer
import EmojiTextAttachmentView
import TextNodeWithEntities
import TBLanguage
import TBWalletCore
import AccountContext
import AvatarNode





let TB_REDPACK_BUBBLE_TAP_NOTIFYCATION = "__tb_redpack_bubble_tap_niotification__"
let TB_Transfer_BUBBLE_TAP_NOTIFYCATION = "__tb_transfer_bubble_tap_niotification__"

let kBubbleHeightDefalt:CGFloat = 125
let kSelfBubbleGap : CGFloat = 19



let kBubbleLeftPadding = 12.0
let kBubbleRightPadiing = 12.0
let kCountAndSymbolPadding = 8.0

let kBubbleHeight = 70.0
let kBubbleBottom = 12.0

let kOrgBubbleWidth = 80.0
let kOrgBubblePadding = 6.0


class TB_TransAssetViewNode: ASDisplayNode {
    var backWhiteView :UIView?
    var bubbuleView :UIView?
    var bubbuleView_bottom :UIView?
    var bubbleSmallView :UIImageView?
    var headIcon :UIImageView?
    var nameLabel :UILabel?
    var desLabel :UILabel?
    var packIcon :UIImageView?
    var packLabel :UILabel?
    var timeLabel :UILabel?
    
    var messageText :String?
    var bgLayer1 :CAGradientLayer?


    
    override public init() {
        super.init()

    }
    
    @objc func readEvent(noti: Notification) {
        
        print("6666")
        print("6666")

        
        if let a = noti.userInfo as? Dictionary<String, Any>,
           let secretKey = a["secretKey"] as? String,
           let redPack = tb_decode_message_transferAsset(strToDecode: self.messageText ?? "") {
            
            if redPack.secretKey == secretKey {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                    self.bubbuleView?.alpha = 0.5
                    self.desLabel?.text = "😩"
                }
            }
        }
    }
    

    override open func didLoad() {
        

            NotificationCenter.default.addObserver(self, selector: #selector(readEvent(noti:)), name: NSNotification.Name.init(rawValue: _notify_set_redpack_readed_), object: nil)

        super.didLoad()
        
        self.backWhiteView = UIView(frame:CGRect(x: -111, y: 0, width: 214, height: kBubbleHeightDefalt))
        self.backWhiteView?.backgroundColor = UIColor.white
        
        self.bubbuleView = UIView(frame:CGRect(x: -111, y: 0, width: 214, height: kBubbleHeightDefalt))

        self.bgLayer1 = CAGradientLayer()
        self.bgLayer1?.colors = [UIColor(red: 1, green: 0.15, blue: 0.15, alpha: 1).cgColor, UIColor(red: 1, green: 0.31, blue: 0.31, alpha: 1).cgColor]
        self.bgLayer1?.locations = [0, 1]
        self.bgLayer1?.frame = self.bubbuleView!.bounds
        self.bgLayer1?.startPoint = CGPoint(x: 0.5, y: 0)
        self.bgLayer1?.endPoint = CGPoint(x: 0.91, y: 0.91)
        self.bubbuleView?.layer.addSublayer(self.bgLayer1!)

        self.view.addSubview(self.backWhiteView!)
        self.view.addSubview(self.bubbuleView!)
        
        let maskPath = UIBezierPath(roundedRect: self.bubbuleView!.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10.0, height: 10.0))

        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bubbuleView!.bounds
        maskLayer.path = maskPath.cgPath
        self.bubbuleView!.layer.mask = maskLayer
        
        
        let maskPath1 = UIBezierPath(roundedRect: self.bubbuleView!.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10.0, height: 10.0))
        let maskLayer1 = CAShapeLayer()
        maskLayer1.frame = self.backWhiteView!.bounds
        maskLayer1.path = maskPath1.cgPath
        self.backWhiteView!.layer.mask = maskLayer1

        
        
        self.bubbuleView_bottom = UIView(frame: CGRect(x: self.bubbuleView?.frame.origin.x ?? 0, y: self.bubbuleView?.frame.size.height ?? 0, width: 214, height: 32))
        self.bubbuleView_bottom?.backgroundColor = UIColor.white
        self.view.addSubview(self.bubbuleView_bottom!)
        
        let maskPath_bottom = UIBezierPath(roundedRect: self.bubbuleView_bottom!.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10.0, height: 10.0))
        let maskLayer_bottom = CAShapeLayer()
        maskLayer_bottom.frame = self.bubbuleView_bottom!.bounds;
        maskLayer_bottom.path = maskPath_bottom.cgPath;
        self.bubbuleView_bottom!.layer.mask = maskLayer_bottom;
        
        
        var startX = CGFloat(16.0) - 111
        var startY = CGFloat(14.0)
        
        self.headIcon = UIImageView(frame: CGRect(x: startX, y: startY, width: 40, height: 40))
        self.headIcon?.layer.cornerRadius = 20
        self.view.addSubview(self.headIcon!)
        
        startY = startY + (self.headIcon?.frame.size.height ?? 0) + 8.0
        
        self.nameLabel = UILabel(frame: CGRect(x: startX, y: startY, width: 144, height: 17))
        self.nameLabel?.textColor = UIColor.white
        self.nameLabel?.font = UIFont.systemFont(ofSize: 15)
        self.nameLabel?.textColor = UIColor(hexString: "#FFD4AC")
        self.view.addSubview(self.nameLabel!)
        
        startY = startY + (self.nameLabel?.frame.size.height ?? 0) + 4

        self.desLabel = UILabel(frame: CGRect(x: startX, y: startY, width: 244, height: 17))
        self.view.addSubview(self.desLabel!)
        self.desLabel?.text = "，！"
        self.desLabel?.textColor = UIColor.white
        self.desLabel?.font = UIFont.systemFont(ofSize: 12)

        
        startY = startY + (self.desLabel?.frame.size.height ?? 0) + 26
        self.packIcon = UIImageView(frame: CGRect(x: startX, y: startY, width: 16, height: 16))
        self.packIcon?.image = UIImage(named: "TBWallet/myredpack_small_icon")
        self.view.addSubview(self.packIcon!)
        
        startX = startX + (self.packIcon?.frame.size.width ?? 0)
        self.packLabel = UILabel(frame: CGRect(x: startX, y: startY, width: 180, height: 16))
        self.packLabel?.text = "Web3 "
        self.packLabel?.font = UIFont.systemFont(ofSize: 12)
        self.view.addSubview(self.packLabel!)
        
        startX = (self.bubbuleView?.frame.size.width ?? 0) - 4 - 66 - 40 - 40
        self.timeLabel = UILabel(frame: CGRect(x: startX, y: startY, width: 150, height: 14))
        self.timeLabel?.textColor = UIColor(hexString: "#A1AAB3")
        self.timeLabel?.font = UIFont.systemFont(ofSize: 12)
        self.timeLabel?.textAlignment = .right
        self.view.addSubview(self.timeLabel!)
        
        self.view.isUserInteractionEnabled = true
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(bubbleTouch))
        self.view.addGestureRecognizer(singleTap)
        
        startX = self.bubbuleView_bottom!.frame.origin.x + self.bubbuleView_bottom!.frame.size.width - 5
        startY = self.bubbuleView_bottom!.frame.origin.y + self.bubbuleView_bottom!.frame.size.height - 20
        
        self.bubbleSmallView = UIImageView(frame: CGRect(x: startX, y: startY, width: 12, height: 20))
        self.view.addSubview(self.bubbleSmallView!)
    }
    
    func reloadRedPackData(account:Account,fromPeerId:PeerId,message:Message,dateText:String,context: AccountContext) {
        
        
        let _ = context.account.viewTracker.peerView(account.peerId).start(next: {[weak self] peerView in
            let user = peerView.peers[peerView.peerId] as? TelegramUser
            
            guard let tmpUser = user else { return }
            let peer = EnginePeer(tmpUser)
            if let signal = peerAvatarImage(account: context.account,
                                            peerReference: PeerReference(peer._asPeer()),
                                            authorOfMessage: nil,
                                            representation: peer.smallProfileImage,
                                            displayDimensions: CGSize(width: 40,height: 40)) {
                
                let _ = signal.start {[weak self] a in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                        self?.headIcon?.image = a?.0
                    }
                }
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            
            if let userPeer = message.author as? TelegramUser {
                self.nameLabel?.text = (userPeer.lastName ?? "") + (userPeer.firstName ?? "")
            }
            self.timeLabel?.text = dateText
            self.bubbleSmallView?.image = UIImage(named: "TBWallet/icon_bubble_small_view_right")
            self.messageText = message.text
        }
        
        
        var isMessageFromMe = false
        if account.peerId.toInt64() == message.author?.id.toInt64() {
            isMessageFromMe = true
        }
        if isMessageFromMe {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {

                self.bubbuleView?.frame = CGRect(x: -111, y: 0, width: 214, height: kBubbleHeightDefalt - kSelfBubbleGap)
                self.backWhiteView?.frame = self.bubbuleView!.frame

                self.bubbuleView_bottom?.frame = CGRect(x: self.bubbuleView?.frame.origin.x ?? 0, y: self.bubbuleView?.frame.size.height ?? 0, width: 214, height: 32)
                self.bgLayer1?.frame = self.bubbuleView!.bounds

                var startX = CGFloat(16.0) - 111
                var startY = CGFloat(14.0)
                
                self.headIcon?.frame = CGRect(x: startX, y: startY, width: 40, height: 40)
                
                self.nameLabel?.isHidden = true
                
                startY = startY + (self.headIcon?.frame.size.height ?? 0) + 8.0
                self.desLabel?.frame = CGRect(x: startX, y: startY, width: 244, height: 17)
                self.desLabel?.text = ""

                startY = self.bubbuleView!.frame.size.height + self.bubbuleView!.frame.origin.y  + 8
                self.packIcon?.frame = CGRect(x: startX, y: startY, width: 16, height: 16)

                startX = startX + (self.packIcon?.frame.size.width ?? 0) + 3
                self.packLabel?.frame = CGRect(x: startX, y: startY, width: 180, height: 16)

                startX = self.bubbuleView!.frame.size.width + self.bubbuleView!.frame.origin.x - 150 - 10
                self.timeLabel?.frame = CGRect(x: startX, y: startY, width: 150, height: 14)

                startX = self.bubbuleView_bottom!.frame.origin.x + self.bubbuleView_bottom!.frame.size.width - 5
                startY = self.bubbuleView_bottom!.frame.origin.y + self.bubbuleView_bottom!.frame.size.height - 20

                self.bubbleSmallView?.frame = CGRect(x: startX, y: startY, width: 12, height: 20)
                self.bubbleSmallView?.image = UIImage(named: "TBWallet/icon_bubble_small_view_right")

                self.bubbuleView?.alpha = 1.0
            }
        }else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {

                var startX = CGFloat(0.0)
                var startY = CGFloat(0.0)
                
                self.bubbuleView?.frame = CGRect(x: startX, y: startY, width: 214, height: kBubbleHeightDefalt)
                self.backWhiteView?.frame = self.bubbuleView!.frame

                self.bubbuleView_bottom?.frame = CGRect(x: self.bubbuleView?.frame.origin.x ?? 0, y: (self.bubbuleView?.frame.size.height ?? 0) + startY, width: 214, height: 32)
                self.bgLayer1?.frame = self.bubbuleView!.bounds

                startY =  startY + 14
                startX = startX + 16
                
                self.headIcon?.frame = CGRect(x: startX, y: startY, width: 40, height: 40)

                startY = startY + (self.headIcon?.frame.size.height ?? 0) + 8.0
                self.nameLabel?.frame = CGRect(x: startX, y: startY, width: 144, height: 17)
                self.nameLabel?.isHidden = false

                startY = startY + (self.nameLabel?.frame.size.height ?? 0) + 4
                self.desLabel?.frame = CGRect(x: startX, y: startY, width: 244, height: 17)
                self.desLabel?.text = "，！"

                startY = self.bubbuleView!.frame.size.height + self.bubbuleView!.frame.origin.y + 7
                self.packIcon?.frame = CGRect(x: startX, y: startY, width: 16, height: 16)

                startX = startX + (self.packIcon?.frame.size.width ?? 0) + 3
                self.packLabel?.frame = CGRect(x: startX, y: startY, width: 180, height: 16)

                startX = self.bubbuleView!.frame.size.width + self.bubbuleView!.frame.origin.x - 150 - 10
                self.timeLabel?.frame = CGRect(x: startX, y: startY, width: 150, height: 14)

                startX = -5
                startY = self.bubbuleView_bottom!.frame.origin.y + self.bubbuleView_bottom!.frame.size.height - 20

                self.bubbleSmallView?.frame = CGRect(x: startX, y: startY, width: 12, height: 20)
                self.bubbleSmallView?.image = UIImage(named: "TBWallet/icon_bubble_small_view_left")
                
                
                
                
                
                if let redPack = tb_decode_message_transferAsset(strToDecode: self.messageText ?? "") {
                    if let key =  redPack.secretKey {
                        let hasGot = getRedPackReadStatus(secretKey: key, tgId: account.peerId.id.description)
                      
                        if hasGot {
                            self.bubbuleView?.alpha = 0.5
                            self.desLabel?.text = "😩"
                        }else {
                            self.bubbuleView?.alpha = 1.0
                        }
                    }
                }

                

            }
        }
    }
    
    @objc func bubbleTouch()  {
        print("bubbleTouch 3")

        if let text = self.messageText {
            print("bubbleTouch 4")

            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: TB_REDPACK_BUBBLE_TAP_NOTIFYCATION),
                                            object: self,
                                            userInfo: ["data":text])
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue:_notify_set_redpack_readed_ ), object: nil)
    }

}


class TB_RedpackViewNode : ASDisplayNode {
    public internal(set) var cachedLayout: TextNodeLayout?

    var toNameLabel:UILabel?
    var countLabel:UILabel?
    var tokenSymbolLabel:UILabel?
    var tokenDateLabel:UILabel?
    var backgroudView:UIView?
    var radiusSmallIconImageView:UIImageView?
    var radiusView: UIView? 

    var messageText:String?




    override public init() {
        super.init()
    }

    override open func didLoad() {
        super.didLoad()
        self.isExclusiveTouch = true
        self.view.addSubview( self.setupRedPackUI())
    }

    func setupRedPackUI() -> UIView {
        

        self.toNameLabel?.removeFromSuperview()
        self.countLabel?.removeFromSuperview()
        self.tokenSymbolLabel?.removeFromSuperview()
        self.tokenDateLabel?.removeFromSuperview()
        self.backgroudView?.removeFromSuperview()
        self.radiusSmallIconImageView?.removeFromSuperview()
        self.radiusView?.removeFromSuperview()




        self.backgroudView = UIView(frame: CGRect(x: 0, y: 0, width: 208, height: 22*4))
        self.backgroudView?.backgroundColor = UIColor.clear
        
        self.radiusView = UIView(frame: CGRect(x: 0, y: 0, width: 212, height: 80))
        self.radiusView?.layer.cornerRadius = 10;
        let gradientLayer = CAGradientLayer.init()
        gradientLayer.frame = radiusView!.bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.colors = [UIColor(hexString: "#01B4FF")!.cgColor,UIColor(hexString: "#8836DF")!.cgColor]
        self.radiusView?.layer.addSublayer(gradientLayer)
        self.backgroudView?.addSubview(self.radiusView!)

        
        self.radiusSmallIconImageView = UIImageView(image: UIImage(named:"Wallet/Shape01")!.withRenderingMode(.alwaysTemplate))
        self.radiusSmallIconImageView?.tintColor = UIColor(hexString: "#8836DF")

        self.radiusSmallIconImageView?.frame = CGRect(x: self.radiusView!.frame.origin.x + self.radiusView!.frame.size.width,
                                                     y: self.radiusView!.frame.origin.y + radiusView!.frame.size.height - 20,
                                                     width: 12,
                                                     height: 20)
        self.backgroudView?.addSubview(self.radiusSmallIconImageView!)

        
        self.toNameLabel = UILabel.init(frame: CGRect(x: 0, y: 10, width: 200, height: 14))
        self.toNameLabel?.font = UIFont.systemFont(ofSize: 12)
        self.toNameLabel?.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
        self.backgroudView?.addSubview(self.toNameLabel!)

        
        self.countLabel = UILabel.init(frame: CGRect(x: self.toNameLabel!.frame.origin.x,
                                                     y: self.toNameLabel!.frame.origin.y + self.toNameLabel!.frame.size.height,
                                                     width: 100,
                                                     height: 26))

        self.countLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        self.countLabel?.textColor = UIColor(hexString: "#FFFFFF")
        self.backgroudView?.addSubview(self.countLabel!)

        
        self.tokenSymbolLabel = UILabel.init(frame: CGRect(x: self.countLabel!.frame.origin.x + self.countLabel!.frame.size.width+8,
                                                           y: self.countLabel!.frame.origin.y + self.countLabel!.frame.size.height - 15,
                                                           width: 16,
                                                           height: 15))
        self.tokenSymbolLabel?.text = "TT"
        self.tokenSymbolLabel?.font = UIFont.systemFont(ofSize: 13)
        self.tokenSymbolLabel?.textColor = UIColor(red: 230/255, green: 253/255, blue: 255/255, alpha: 0.8)
        self.backgroudView?.addSubview(self.tokenSymbolLabel!)


        
        self.tokenDateLabel = UILabel.init(frame: CGRect(x: 0, y: 0, width: 116, height: 14))
        self.tokenDateLabel?.font = UIFont.systemFont(ofSize: 12)
        self.tokenDateLabel?.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
        self.backgroudView?.addSubview(self.tokenDateLabel!)



        self.backgroudView?.isUserInteractionEnabled = true
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(bubbleTouch))
        self.backgroudView?.addGestureRecognizer(singleTap)

        return self.backgroudView!
    }

    @objc func bubbleTouch()  {
        print("bubbleTouch 1")

        if let text = self.messageText {
            print("bubbleTouch 2")
            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: TB_Transfer_BUBBLE_TAP_NOTIFYCATION),
                                            object: self,
                                            userInfo: ["data":text])
        }
    }



    func reloadRedPackData(account:Account,chatWithUser:TelegramUser?,message:Message,dateText:String) {
        self.messageText = message.text

        var isMessageFromMe = false
        var transTipText = ""


        
        if account.peerId.toInt64() == message.author?.id.toInt64() {
            isMessageFromMe = true
        }



        
        if isMessageFromMe == false{
            transTipText = TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_toyoutransfer)
        }else {
            if let user = chatWithUser {
                let formatString = TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_towhotransfer)
                transTipText = String(format: formatString,((user.firstName ?? "") + (user.lastName ?? "")) )//  " " + (user.firstName ?? "") + (user.lastName ?? "") + " "
            }
        }

        let redPackData = tb_decode_redPack_message(strToDecode: message.text)


        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                self.view.addSubview( self.setupRedPackUI())

                self.toNameLabel?.text = transTipText
                self.countLabel?.text = redPackData?.count
                self.tokenSymbolLabel?.text = redPackData?.symbol
                self.tokenDateLabel?.text = dateText


                self.toNameLabel?.sizeToFit()
                self.tokenDateLabel?.sizeToFit()
                self.tokenSymbolLabel?.sizeToFit()

                
                var fullWidth = 106.0
                let contentLineWith = kBubbleLeftPadding + self.countLabel!.frame.size.width + kCountAndSymbolPadding + self.tokenSymbolLabel!.frame.size.width + kBubbleRightPadiing

                let nameContentLineWith = kBubbleLeftPadding + self.toNameLabel!.frame.size.width + 10.0 + (self.tokenDateLabel!.frame.size.width ) + kBubbleRightPadiing

                var contentWidth = contentLineWith

                if (nameContentLineWith > contentLineWith) {
                    contentWidth = nameContentLineWith
                }

                if contentWidth > fullWidth {
                    fullWidth = contentWidth
                }


                
                var startX = 0.0

                if isMessageFromMe {
                    startX = 0.0 - (fullWidth - kOrgBubbleWidth - kOrgBubblePadding * 2 - 11)
                }else {
                    startX = 0.0
                }

                self.backgroudView?.frame = CGRect(x: startX, y: 1, width: fullWidth, height: kBubbleHeight-2)

                self.radiusView?.frame = CGRect(x: 0,
                                                y: self.radiusView!.frame.origin.y,
                                                width: self.backgroudView!.frame.size.width,
                                                height: self.backgroudView!.frame.size.height)

                    
                if isMessageFromMe { 
                    self.radiusSmallIconImageView?.image =  UIImage(named:"Wallet/Shape01")?.withRenderingMode(.alwaysTemplate)
                    self.radiusSmallIconImageView?.tintColor = UIColor(hexString: "#8836DF")
                    self.radiusSmallIconImageView?.frame = CGRect(x: self.radiusView!.frame.origin.x + self.radiusView!.frame.size.width,
                                                                 y: self.radiusView!.frame.origin.y + self.radiusView!.frame.size.height - 10,
                                                                 width: 6,
                                                                 height: 10)
                }else { 
                    self.radiusSmallIconImageView?.image =  UIImage(named:"Wallet/Shape02")?.withRenderingMode(.alwaysTemplate)
                    self.radiusSmallIconImageView?.tintColor = UIColor(hexString: "#01B4FF")
                    self.radiusSmallIconImageView?.frame = CGRect(x: self.radiusView!.frame.origin.x - 6,
                                                                 y: self.radiusView!.frame.origin.y + self.radiusView!.frame.size.height - 10,
                                                                 width: 6,
                                                                 height: 10)

                }





                
                let symboleHeight = 15.0
                startX = fullWidth - kBubbleRightPadiing - self.tokenSymbolLabel!.frame.width
                var startY = kBubbleHeight - kBubbleBottom - symboleHeight

                self.tokenSymbolLabel?.frame = CGRect(x: startX, y: startY, width: self.tokenSymbolLabel!.frame.size.width, height: symboleHeight)

                
                let countLabelHeight = 22.0

                self.countLabel?.sizeToFit()

                startX = startX - kCountAndSymbolPadding - self.countLabel!.frame.size.width
                startY = kBubbleHeight - kBubbleBottom - countLabelHeight
                self.countLabel?.frame = CGRect(x: startX, y: startY, width: self.countLabel!.frame.size.width, height: countLabelHeight)


                
                let topPadding = 12.0
                startX = kBubbleLeftPadding
                self.toNameLabel?.frame = CGRect(x: startX, y: topPadding, width: 0, height: 16)
                self.toNameLabel?.sizeToFit()

                
                self.tokenDateLabel?.sizeToFit()
                startX = fullWidth - kBubbleRightPadiing - self.tokenDateLabel!.frame.size.width
                self.tokenDateLabel?.frame = CGRect(x: startX, y: topPadding, width: self.tokenDateLabel!.frame.size.width, height: 14.0)

                self.view.bringToFront()



            
            
            if isMessageFromMe {
                self.setCornerWithView(view: self.radiusView!,
                                       viewSize: self.radiusView!.frame.size,
                                       corners: UIRectCorner(rawValue: (UIRectCorner.topLeft.rawValue)|(UIRectCorner.topRight.rawValue)|(UIRectCorner.bottomLeft.rawValue)),
                                       radius: 10)
            }else {
                self.setCornerWithView(view: self.radiusView!,
                                       viewSize: self.radiusView!.frame.size,
                                       corners: UIRectCorner(rawValue: (UIRectCorner.topLeft.rawValue)|(UIRectCorner.topRight.rawValue)|(UIRectCorner.bottomRight.rawValue)),
                                       radius: 10)
            }

            self.view.frame = CGRect(x: 0, y: 0, width: self.radiusView?.frame.size.width ?? 0, height: self.radiusView?.frame.size.height ?? 0)
            self.messageText = message.text
        }
    }


    
    
    
    
    
    

    func setCornerWithView(view:UIView,viewSize:CGSize,corners:UIRectCorner,radius:CGFloat)  {
        var fr = CGRectZero
        fr.size = viewSize

        let round = UIBezierPath(roundedRect: fr, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let shape = CAShapeLayer()
        shape.path = round.cgPath
        view.layer.mask = shape
    }
}



private final class CachedChatMessageText {
    let text: String
    let inputEntities: [MessageTextEntity]?
    let entities: [MessageTextEntity]?

    init(text: String, inputEntities: [MessageTextEntity]?, entities: [MessageTextEntity]?) {
        self.text = text
        self.inputEntities = inputEntities
        self.entities = entities
    }

    func matches(text: String, inputEntities: [MessageTextEntity]?) -> Bool {
        if self.text != text {
            return false
        }
        if let current = self.inputEntities, let inputEntities = inputEntities {
            if current != inputEntities {
                return false
            }
        } else if (self.inputEntities != nil) != (inputEntities != nil) {
            return false
        }
        return true
    }
}

class TB_ChatMessageWalletBubbleContentNode: ChatMessageBubbleContentNode {
    let redPackNode : TB_RedpackViewNode
    let transAssetNode : TB_TransAssetViewNode


    private let textNode: TextNodeWithEntities
    private var spoilerTextNode: TextNodeWithEntities?
    private var dustNode: InvisibleInkDustNode?
    
    private let textAccessibilityOverlayNode: TextAccessibilityOverlayNode
    private let statusNode: ChatMessageDateAndStatusNode
    private var linkHighlightingNode: LinkHighlightingNode?
    private var textSelectionNode: TextSelectionNode?
    
    private var textHighlightingNodes: [LinkHighlightingNode] = []
    
    private var cachedChatMessageText: CachedChatMessageText?
    
    override var visibility: ListViewItemNodeVisibility {
        didSet {
            if oldValue != self.visibility {
                switch self.visibility {
                case .none:
                    self.textNode.visibilityRect = nil
                    self.spoilerTextNode?.visibilityRect = nil
                case let .visible(_, subRect):
                    var subRect = subRect
                    subRect.origin.x = 0.0
                    subRect.size.width = 10000.0
                    self.textNode.visibilityRect = subRect
                    self.spoilerTextNode?.visibilityRect = subRect
                }
            }
        }
    }
    
    required init() {
        self.textNode = TextNodeWithEntities()
        self.statusNode = ChatMessageDateAndStatusNode()
        
        self.textAccessibilityOverlayNode = TextAccessibilityOverlayNode()
        self.redPackNode = TB_RedpackViewNode()
        self.transAssetNode = TB_TransAssetViewNode()


        super.init()
        
        self.textNode.textNode.isUserInteractionEnabled = false
        self.textNode.textNode.contentMode = .topLeft
        self.textNode.textNode.contentsScale = UIScreenScale
        self.textNode.textNode.displaysAsynchronously = true
        self.addSubnode(self.textNode.textNode)
        self.addSubnode(self.textAccessibilityOverlayNode)
        self.addSubnode(redPackNode)
        self.addSubnode(self.transAssetNode)
        
        self.textAccessibilityOverlayNode.openUrl = { [weak self] url in
            self?.item?.controllerInteraction.openUrl(url, false, false, nil)
        }
        
        self.statusNode.reactionSelected = { [weak self] value in
            guard let strongSelf = self, let item = strongSelf.item else {
                return
            }
            item.controllerInteraction.updateMessageReaction(item.message, .reaction(value))
        }
        
        self.statusNode.openReactionPreview = { [weak self] gesture, sourceNode, value in
            guard let strongSelf = self, let item = strongSelf.item else {
                gesture?.cancel()
                return
            }
            
            item.controllerInteraction.openMessageReactionContextMenu(item.topMessage, sourceNode, gesture, value)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func asyncLayoutContent() -> (_ item: ChatMessageBubbleContentItem, _ layoutConstants: ChatMessageItemLayoutConstants, _ preparePosition: ChatMessageBubblePreparePosition, _ messageSelection: Bool?, _ constrainedSize: CGSize, _ avatarInset: CGFloat) -> (ChatMessageBubbleContentProperties, CGSize?, CGFloat, (CGSize, ChatMessageBubbleContentPosition) -> (CGFloat, (CGFloat) -> (CGSize, (ListViewItemUpdateAnimation, Bool, ListViewItemApply?) -> Void))) {
        let textLayout = TextNodeWithEntities.asyncLayout(self.textNode)
        let spoilerTextLayout = TextNodeWithEntities.asyncLayout(self.spoilerTextNode)
        let statusLayout = self.statusNode.asyncLayout()
        
        let currentCachedChatMessageText = self.cachedChatMessageText
        
        return { item, layoutConstants, _, _, _, _ in
            let contentProperties = ChatMessageBubbleContentProperties(hidesSimpleAuthorHeader: false, headerSpacing: 0.0, hidesBackground: .never, forceFullCorners: false, forceAlignment: .none)
            
            return (contentProperties, nil, CGFloat.greatestFiniteMagnitude, { constrainedSize, position in
                let message = item.message
                
                let incoming: Bool
                if let subject = item.associatedData.subject, case .forwardedMessages = subject {
                    incoming = false
                } else {
                    incoming = item.message.effectivelyIncoming(item.context.account.peerId)
                }
                

                var tbheight = 44.0
                                
                let dateFormat: MessageTimestampStatusFormat
                if let subject = item.associatedData.subject, case .forwardedMessages = subject {
                    dateFormat = .minimal
                } else {
                    dateFormat = .regular
                }
                let dateText = stringForMessageTimestampStatus(accountPeerId: item.context.account.peerId, message: item.message, dateTimeFormat: item.presentationData.dateTimeFormat, nameDisplayOrder: item.presentationData.nameDisplayOrder, strings: item.presentationData.strings, format: dateFormat)
                
                
                
                if simpleCheckTransAsset(str: item.message.text) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                        self.redPackNode.view.isHidden = true
                        self.transAssetNode.view.isHidden = false
                    }

                    if let peerId = item.message.author?.id {
                        self.transAssetNode.reloadRedPackData(account: item.context.account, fromPeerId: peerId, message: item.message, dateText: dateText,context:item.context)
                    }
                    tbheight = 130

                    if item.context.account.peerId.toInt64() == item.message.author?.id.toInt64() {
                        tbheight = tbheight - kSelfBubbleGap
                    }
                }else {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                        self.redPackNode.view.isHidden = false
                        self.transAssetNode.view.isHidden = true
                    }
                    var toUser:TelegramUser
                    for peer in item.message.peers {
                        let (_,peerData) = peer
                        if let user = peerData as? TelegramUser {
                            toUser = user
                            self.redPackNode.reloadRedPackData(account: item.context.account, chatWithUser: toUser, message: item.message,dateText: dateText)
                        }
                    }
                }

                
                
                let textConstrainedSize = CGSize(width: kOrgBubbleWidth, height: tbheight)

                
                var edited = false
                if item.attributes.updatingMedia != nil {
                    edited = true
                }
                var viewCount: Int?
                var dateReplies = 0
                var dateReactionsAndPeers = mergedMessageReactionsAndPeers(accountPeer: item.associatedData.accountPeer, message: item.topMessage)
                if item.message.isRestricted(platform: "ios", contentSettings: item.context.currentContentSettings.with { $0 }) {
                    dateReactionsAndPeers = ([], [])
                }
                
                for attribute in item.message.attributes {
                    if let attribute = attribute as? EditedMessageAttribute {
                        edited = !attribute.isHidden
                    } else if let attribute = attribute as? ViewCountMessageAttribute {
                        viewCount = attribute.count
                    } else if let attribute = attribute as? ReplyThreadMessageAttribute, case .peer = item.chatLocation {
                        if let channel = item.message.peers[item.message.id.peerId] as? TelegramChannel, case .group = channel.info {
                            dateReplies = Int(attribute.count)
                        }
                    }
                }
                
                
                let statusType: ChatMessageDateAndStatusType?
                var displayStatus = false
                switch position {
                case let .linear(_, neighbor):
                    if case .None = neighbor {
                        displayStatus = true
                    } else if case .Neighbour(true, _, _) = neighbor {
                        displayStatus = true
                    }
                default:
                    break
                }
                if displayStatus {
                    if incoming {
                        statusType = .BubbleIncoming
                    } else {
                        if message.flags.contains(.Failed) {
                            statusType = .BubbleOutgoing(.Failed)
                        } else if (message.flags.isSending && !message.isSentOrAcknowledged) || item.attributes.updatingMedia != nil {
                            statusType = .BubbleOutgoing(.Sending)
                        } else {
                            statusType = .BubbleOutgoing(.Sent(read: item.read))
                        }
                    }
                } else {
                    statusType = nil
                }
                
                let rawText: String
                var attributedText: NSAttributedString
                var messageEntities: [MessageTextEntity]?
                
                var mediaDuration: Double? = nil
                var isSeekableWebMedia = false
                var isUnsupportedMedia = false
                for media in item.message.media {
                    if let file = media as? TelegramMediaFile, let duration = file.duration {
                        mediaDuration = Double(duration)
                    }
                    if let webpage = media as? TelegramMediaWebpage, case let .Loaded(content) = webpage.content, webEmbedType(content: content).supportsSeeking {
                        isSeekableWebMedia = true
                    } else if media is TelegramMediaUnsupported {
                        isUnsupportedMedia = true
                    }
                }
                
                if isUnsupportedMedia {
                    rawText = item.presentationData.strings.Conversation_UnsupportedMediaPlaceholder
                    messageEntities = [MessageTextEntity(range: 0..<rawText.count, type: .Italic)]
                } else {
                    if let updatingMedia = item.attributes.updatingMedia {
                        rawText = updatingMedia.text
                    } else {
                        rawText = item.message.text
                    }
                    
                    for attribute in item.message.attributes {
                        if let attribute = attribute as? TextEntitiesMessageAttribute {
                            messageEntities = attribute.entities
                        } else if mediaDuration == nil, let attribute = attribute as? ReplyMessageAttribute {
                            if let replyMessage = item.message.associatedMessages[attribute.messageId] {
                                for media in replyMessage.media {
                                    if let file = media as? TelegramMediaFile, let duration = file.duration {
                                        mediaDuration = Double(duration)
                                    }
                                    if let webpage = media as? TelegramMediaWebpage, case let .Loaded(content) = webpage.content, webEmbedType(content: content).supportsSeeking {
                                        isSeekableWebMedia = true
                                    }
                                }
                            }
                        }
                    }
                    
                    if let updatingMedia = item.attributes.updatingMedia {
                        messageEntities = updatingMedia.entities?.entities ?? []
                    }
                }
                
                var entities: [MessageTextEntity]?
                
                var updatedCachedChatMessageText: CachedChatMessageText?
                if let cached = currentCachedChatMessageText, cached.matches(text: rawText, inputEntities: messageEntities) {
                    entities = cached.entities
                } else {
                    entities = messageEntities
                    
                    if entities == nil && (mediaDuration != nil || isSeekableWebMedia) {
                        entities = []
                    }
                    
                    if let entitiesValue = entities {
                        var enabledTypes: EnabledEntityTypes = .all
                        if mediaDuration != nil || isSeekableWebMedia {
                            enabledTypes.insert(.timecode)
                            if mediaDuration == nil {
                                mediaDuration = 60.0 * 60.0 * 24.0
                            }
                        }
                        if let result = addLocallyGeneratedEntities(rawText, enabledTypes: enabledTypes, entities: entitiesValue, mediaDuration: mediaDuration) {
                            entities = result
                        }
                    } else {
                        var generateEntities = false
                        for media in message.media {
                            if media is TelegramMediaImage || media is TelegramMediaFile {
                                generateEntities = true
                                break
                            }
                        }
                        if message.id.peerId.namespace == Namespaces.Peer.SecretChat {
                           generateEntities = true
                        }
                        if generateEntities {
                            let parsedEntities = generateTextEntities(rawText, enabledTypes: .all)
                            if !parsedEntities.isEmpty {
                                entities = parsedEntities
                            }
                        }
                    }
                    updatedCachedChatMessageText = CachedChatMessageText(text: rawText, inputEntities: messageEntities, entities: entities)
                }
                
                
                let messageTheme = incoming ? item.presentationData.theme.theme.chat.message.incoming : item.presentationData.theme.theme.chat.message.outgoing
                
                let textFont = item.presentationData.messageFont
                
                if let entities = entities {
                    attributedText = stringWithAppliedEntities(rawText, entities: entities, baseColor: messageTheme.primaryTextColor, linkColor: messageTheme.linkTextColor, baseFont: textFont, linkFont: textFont, boldFont: item.presentationData.messageBoldFont, italicFont: item.presentationData.messageItalicFont, boldItalicFont: item.presentationData.messageBoldItalicFont, fixedFont: item.presentationData.messageFixedFont, blockQuoteFont: item.presentationData.messageBlockQuoteFont, message: item.message)
                } else if !rawText.isEmpty {
                    attributedText = NSAttributedString(string: rawText, font: textFont, textColor: messageTheme.primaryTextColor)
                } else {
                    attributedText = NSAttributedString(string: " ", font: textFont, textColor: messageTheme.primaryTextColor)
                }
                
                if let entities = entities {
                    let updatedString = NSMutableAttributedString(attributedString: attributedText)
                    
                    for entity in entities.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
                        guard case let .CustomEmoji(_, fileId) = entity.type else {
                            continue
                        }
                        
                        let range = NSRange(location: entity.range.lowerBound, length: entity.range.upperBound - entity.range.lowerBound)
                        
                        let currentDict = updatedString.attributes(at: range.lowerBound, effectiveRange: nil)
                        var updatedAttributes: [NSAttributedString.Key: Any] = currentDict
                        updatedAttributes[NSAttributedString.Key.foregroundColor] = UIColor.clear.cgColor
                        updatedAttributes[ChatTextInputAttributes.customEmoji] = ChatTextInputTextCustomEmojiAttribute(interactivelySelectedFromPackId: nil, fileId: fileId, file: item.message.associatedMedia[MediaId(namespace: Namespaces.Media.CloudFile, id: fileId)] as? TelegramMediaFile)
                        
                        let insertString = NSAttributedString(string: updatedString.attributedSubstring(from: range).string, attributes: updatedAttributes)
                        updatedString.replaceCharacters(in: range, with: insertString)
                    }
                    attributedText = updatedString
                }
                
                let cutout: TextNodeCutout? = nil
                
                let textInsets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 5.0, right: 2.0)
                
                let (textLayout, textApply) = textLayout(TextNodeLayoutArguments(attributedString: attributedText, backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: textConstrainedSize, alignment: .natural, cutout: cutout, insets: textInsets, lineColor: messageTheme.accentControlColor))
                
                let spoilerTextLayoutAndApply: (TextNodeLayout, (TextNodeWithEntities.Arguments?) -> TextNodeWithEntities)?
                if !textLayout.spoilers.isEmpty {
                    spoilerTextLayoutAndApply = spoilerTextLayout(TextNodeLayoutArguments(attributedString: attributedText, backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: textConstrainedSize, alignment: .natural, cutout: cutout, insets: textInsets, lineColor: messageTheme.accentControlColor, displaySpoilers: true, displayEmbeddedItemsUnderSpoilers: true))
                } else {
                    spoilerTextLayoutAndApply = nil
                }
                
                var statusSuggestedWidthAndContinue: (CGFloat, (CGFloat) -> (CGSize, (ListViewItemUpdateAnimation) -> Void))?
                if let statusType = statusType {
                    var isReplyThread = false
                    if case .replyThread = item.chatLocation {
                        isReplyThread = true
                    }
                    
                    let trailingWidthToMeasure: CGFloat
                    if textLayout.hasRTL {
                        trailingWidthToMeasure = 10000.0
                    } else {
                        trailingWidthToMeasure = textLayout.trailingLineWidth
                    }
                    
                    let dateLayoutInput: ChatMessageDateAndStatusNode.LayoutInput
                    dateLayoutInput = .trailingContent(contentWidth: trailingWidthToMeasure, reactionSettings: ChatMessageDateAndStatusNode.TrailingReactionSettings(displayInline: shouldDisplayInlineDateReactions(message: item.message, isPremium: item.associatedData.isPremium, forceInline: item.associatedData.forceInlineReactions), preferAdditionalInset: false))
                    
                    statusSuggestedWidthAndContinue = statusLayout(ChatMessageDateAndStatusNode.Arguments(
                        context: item.context,
                        presentationData: item.presentationData,
                        edited: edited,
                        impressionCount: viewCount,
                        dateText: dateText,
                        type: statusType,
                        layoutInput: dateLayoutInput,
                        constrainedSize: textConstrainedSize,
                        availableReactions: item.associatedData.availableReactions,
                        reactions: dateReactionsAndPeers.reactions,
                        reactionPeers: dateReactionsAndPeers.peers,
                        displayAllReactionPeers: item.message.id.peerId.namespace == Namespaces.Peer.CloudUser,
                        replyCount: dateReplies,
                        isPinned: item.message.tags.contains(.pinned) && !item.associatedData.isInPinnedListMode && isReplyThread,
                        hasAutoremove: item.message.isSelfExpiring,
                        canViewReactionList: canViewMessageReactionList(message: item.message),
                        animationCache: item.controllerInteraction.presentationContext.animationCache,
                        animationRenderer: item.controllerInteraction.presentationContext.animationRenderer
                    ))
                }
                
                var textFrame = CGRect(origin: CGPoint(x: -textInsets.left, y: -textInsets.top), size: textLayout.size)
                var textFrameWithoutInsets = CGRect(origin: CGPoint(x: textFrame.origin.x + textInsets.left, y: textFrame.origin.y + textInsets.top), size: CGSize(width: textFrame.width - textInsets.left - textInsets.right, height: textFrame.height - textInsets.top - textInsets.bottom))
                
                textFrame = textFrame.offsetBy(dx: layoutConstants.text.bubbleInsets.left, dy: layoutConstants.text.bubbleInsets.top)
                textFrameWithoutInsets = textFrameWithoutInsets.offsetBy(dx: layoutConstants.text.bubbleInsets.left, dy: layoutConstants.text.bubbleInsets.top)

                var suggestedBoundingWidth: CGFloat = textFrameWithoutInsets.width
                if let statusSuggestedWidthAndContinue = statusSuggestedWidthAndContinue {
                    suggestedBoundingWidth = max(suggestedBoundingWidth, statusSuggestedWidthAndContinue.0)
                }
                let sideInsets = layoutConstants.text.bubbleInsets.left + layoutConstants.text.bubbleInsets.right
                suggestedBoundingWidth += sideInsets
                
                return (suggestedBoundingWidth, { boundingWidth in
                    var boundingSize: CGSize
                    
                    let statusSizeAndApply = statusSuggestedWidthAndContinue?.1(boundingWidth - sideInsets)
                    
                    boundingSize = textFrameWithoutInsets.size
                    if let statusSizeAndApply = statusSizeAndApply {
                        boundingSize.height += statusSizeAndApply.0.height
                    }
                    
                    boundingSize.width += layoutConstants.text.bubbleInsets.left + layoutConstants.text.bubbleInsets.right
                    boundingSize.height += layoutConstants.text.bubbleInsets.top + layoutConstants.text.bubbleInsets.bottom
                    
                    return (boundingSize, { [weak self] animation, synchronousLoads, _ in
                        if let strongSelf = self {
                            strongSelf.item = item
                            if let updatedCachedChatMessageText = updatedCachedChatMessageText {
                                strongSelf.cachedChatMessageText = updatedCachedChatMessageText
                            }
                            
                            let cachedLayout = strongSelf.textNode.textNode.cachedLayout
                            
                            if case .System = animation {
                                if let cachedLayout = cachedLayout {
                                    if !cachedLayout.areLinesEqual(to: textLayout) {
                                        if let textContents = strongSelf.textNode.textNode.contents {
                                            let fadeNode = ASDisplayNode()
                                            fadeNode.displaysAsynchronously = false
                                            fadeNode.contents = textContents
                                            fadeNode.frame = strongSelf.textNode.textNode.frame
                                            fadeNode.isLayerBacked = true
                                            strongSelf.addSubnode(fadeNode)
                                            fadeNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak fadeNode] _ in
                                                fadeNode?.removeFromSupernode()
                                            })
                                            strongSelf.textNode.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
                                        }
                                    }
                                }
                            }
                            
                            let _ = textApply(TextNodeWithEntities.Arguments(context: item.context, cache: item.controllerInteraction.presentationContext.animationCache, renderer: item.controllerInteraction.presentationContext.animationRenderer, placeholderColor: messageTheme.mediaPlaceholderColor, attemptSynchronous: synchronousLoads))
                            animation.animator.updateFrame(layer: strongSelf.textNode.textNode.layer, frame: textFrame, completion: nil)
                            
                            if let (_, spoilerTextApply) = spoilerTextLayoutAndApply {
                                let spoilerTextNode = spoilerTextApply(TextNodeWithEntities.Arguments(context: item.context, cache: item.controllerInteraction.presentationContext.animationCache, renderer: item.controllerInteraction.presentationContext.animationRenderer, placeholderColor: messageTheme.mediaPlaceholderColor, attemptSynchronous: synchronousLoads))
                                if strongSelf.spoilerTextNode == nil {
                                    spoilerTextNode.textNode.alpha = 0.0
                                    spoilerTextNode.textNode.isUserInteractionEnabled = false
                                    spoilerTextNode.textNode.contentMode = .topLeft
                                    spoilerTextNode.textNode.contentsScale = UIScreenScale
                                    spoilerTextNode.textNode.displaysAsynchronously = false
                                    strongSelf.insertSubnode(spoilerTextNode.textNode, aboveSubnode: strongSelf.textAccessibilityOverlayNode)
                                    
                                    strongSelf.spoilerTextNode = spoilerTextNode
                                }
                                
                                strongSelf.spoilerTextNode?.textNode.frame = textFrame
                                
                                let dustNode: InvisibleInkDustNode
                                if let current = strongSelf.dustNode {
                                    dustNode = current
                                } else {
                                    dustNode = InvisibleInkDustNode(textNode: spoilerTextNode.textNode)
                                    strongSelf.dustNode = dustNode
                                    strongSelf.insertSubnode(dustNode, aboveSubnode: spoilerTextNode.textNode)
                                }
                                dustNode.frame = textFrame.insetBy(dx: -3.0, dy: -3.0).offsetBy(dx: 0.0, dy: 3.0)
                                dustNode.update(size: dustNode.frame.size, color: messageTheme.secondaryTextColor, textColor: messageTheme.primaryTextColor, rects: textLayout.spoilers.map { $0.1.offsetBy(dx: 3.0, dy: 3.0).insetBy(dx: 1.0, dy: 1.0) }, wordRects: textLayout.spoilerWords.map { $0.1.offsetBy(dx: 3.0, dy: 3.0).insetBy(dx: 1.0, dy: 1.0) })
                            } else if let spoilerTextNode = strongSelf.spoilerTextNode {
                                strongSelf.spoilerTextNode = nil
                                spoilerTextNode.textNode.removeFromSupernode()
                                
                                if let dustNode = strongSelf.dustNode {
                                    strongSelf.dustNode = nil
                                    dustNode.removeFromSupernode()
                                }
                            }
                            
                            switch strongSelf.visibility {
                            case .none:
                                strongSelf.textNode.visibilityRect = nil
                                strongSelf.spoilerTextNode?.visibilityRect = nil
                            case let .visible(_, subRect):
                                var subRect = subRect
                                subRect.origin.x = 0.0
                                subRect.size.width = 10000.0
                                strongSelf.textNode.visibilityRect = subRect
                                strongSelf.spoilerTextNode?.visibilityRect = subRect
                            }
                            
                            if let textSelectionNode = strongSelf.textSelectionNode {
                                let shouldUpdateLayout = textSelectionNode.frame.size != textFrame.size
                                textSelectionNode.frame = textFrame
                                textSelectionNode.highlightAreaNode.frame = textFrame
                                if shouldUpdateLayout {
                                    textSelectionNode.updateLayout()
                                }
                            }
                            strongSelf.textAccessibilityOverlayNode.frame = textFrame
                            strongSelf.textAccessibilityOverlayNode.cachedLayout = textLayout
                    
                            
                            if let statusSizeAndApply = statusSizeAndApply {
                                animation.animator.updateFrame(layer: strongSelf.statusNode.layer, frame: CGRect(origin: CGPoint(x: textFrameWithoutInsets.minX, y: textFrameWithoutInsets.maxY), size: statusSizeAndApply.0), completion: nil)
                                if strongSelf.statusNode.supernode == nil {

                                    statusSizeAndApply.1(.None)
                                } else {
                                    statusSizeAndApply.1(animation)
                                }
                            } else if strongSelf.statusNode.supernode != nil {
                                strongSelf.statusNode.removeFromSupernode()
                            }
                            
                            if let forwardInfo = item.message.forwardInfo, forwardInfo.flags.contains(.isImported) {
                                strongSelf.statusNode.pressed = {
                                    guard let strongSelf = self else {
                                        return
                                    }
                                    item.controllerInteraction.displayImportedMessageTooltip(strongSelf.statusNode)
                                }
                            } else {
                                strongSelf.statusNode.pressed = nil
                            }
                        }
                    })
                })
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double) {
        self.textNode.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        self.statusNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.textNode.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        self.statusNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.textNode.textNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
        self.statusNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
    
    override func tapActionAtPoint(_ point: CGPoint, gesture: TapLongTapOrDoubleTapGesture, isEstimating: Bool) -> ChatMessageBubbleContentTapAction {
        let textNodeFrame = self.textNode.textNode.frame
        if let (index, attributes) = self.textNode.textNode.attributesAtPoint(CGPoint(x: point.x - textNodeFrame.minX, y: point.y - textNodeFrame.minY)) {
            if let _ = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.Spoiler)], !(self.dustNode?.isRevealed ?? true)  {
                return .none
            } else if let url = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)] as? String {
                var concealed = true
                if let (attributeText, fullText) = self.textNode.textNode.attributeSubstring(name: TelegramTextAttributes.URL, index: index) {
                    concealed = !doesUrlMatchText(url: url, text: attributeText, fullText: fullText)
                }
                return .url(url: url, concealed: concealed)
            } else if let peerMention = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerMention)] as? TelegramPeerMention {
                return .peerMention(peerMention.peerId, peerMention.mention)
            } else if let peerName = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerTextMention)] as? String {
                return .textMention(peerName)
            } else if let botCommand = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.BotCommand)] as? String {
                return .botCommand(botCommand)
            } else if let hashtag = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag)] as? TelegramHashtag {
                return .hashtag(hashtag.peerName, hashtag.hashtag)
            } else if let timecode = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.Timecode)] as? TelegramTimecode {
                return .timecode(timecode.time, timecode.text)
            } else if let bankCard = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.BankCard)] as? String {
                return .bankCard(bankCard)
            } else if let pre = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.Pre)] as? String {
                return .copy(pre)
            } else {
                if let item = self.item, item.message.text.count == 1, !item.presentationData.largeEmoji {
                    let (emoji, fitz) = item.message.text.basicEmoji
                    var emojiFile: TelegramMediaFile?
                    
                    emojiFile = item.associatedData.animatedEmojiStickers[emoji]?.first?.file
                    if emojiFile == nil {
                        emojiFile = item.associatedData.animatedEmojiStickers[emoji.strippedEmoji]?.first?.file
                    }
                    
                    if let emojiFile = emojiFile {
                        return .largeEmoji(emoji, fitz, emojiFile)
                    } else {
                        return .none
                    }
                } else {
                    return .none
                }
            }
        } else {
            if let _ = self.statusNode.hitTest(self.view.convert(point, to: self.statusNode.view), with: nil) {
                return .ignore
            }
            return .none
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let view = self.redPackNode.backgroudView,  view.frame.contains(point) && self.redPackNode.view.isHidden == false{
            return self.redPackNode.backgroudView
        }
        
        return self.transAssetNode.view

    }
    
    override func updateTouchesAtPoint(_ point: CGPoint?) {

    }
    
    override func peekPreviewContent(at point: CGPoint) -> (Message, ChatMessagePeekPreviewContent)? {
        if let item = self.item {
            let textNodeFrame = self.textNode.textNode.frame
            if let (index, attributes) = self.textNode.textNode.attributesAtPoint(CGPoint(x: point.x - textNodeFrame.minX, y: point.y - textNodeFrame.minY)) {
                if let value = attributes[NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)] as? String {
                    if let rects = self.textNode.textNode.attributeRects(name: TelegramTextAttributes.URL, at: index), !rects.isEmpty {
                        var rect = rects[0]
                        for i in 1 ..< rects.count {
                            rect = rect.union(rects[i])
                        }
                        var concealed = true
                        if let (attributeText, fullText) = self.textNode.textNode.attributeSubstring(name: TelegramTextAttributes.URL, index: index) {
                            concealed = !doesUrlMatchText(url: value, text: attributeText, fullText: fullText)
                        }
                        return (item.message, .url(self, rect, value, concealed))
                    }
                }
            }
        }
        return nil
    }
    
    override func updateSearchTextHighlightState(text: String?, messages: [MessageIndex]?) {
        guard let item = self.item else {
            return
        }
        let rectsSet: [[CGRect]]
        if let text = text, let messages = messages, !text.isEmpty, messages.contains(item.message.index) {
            rectsSet = self.textNode.textNode.textRangesRects(text: text)
        } else {
            rectsSet = []
        }
        for i in 0 ..< rectsSet.count {
            let rects = rectsSet[i]
            let textHighlightNode: LinkHighlightingNode
            if self.textHighlightingNodes.count < i {
                textHighlightNode = self.textHighlightingNodes[i]
            } else {
                textHighlightNode = LinkHighlightingNode(color: item.message.effectivelyIncoming(item.context.account.peerId) ? item.presentationData.theme.theme.chat.message.incoming.textHighlightColor : item.presentationData.theme.theme.chat.message.outgoing.textHighlightColor)
                self.textHighlightingNodes.append(textHighlightNode)
                self.insertSubnode(textHighlightNode, belowSubnode: self.textNode.textNode)
            }
            textHighlightNode.frame = self.textNode.textNode.frame
            textHighlightNode.updateRects(rects)
        }
        for i in (rectsSet.count ..< self.textHighlightingNodes.count).reversed() {
            self.textHighlightingNodes[i].removeFromSupernode()
            self.textHighlightingNodes.remove(at: i)
        }
    }
    
    override func willUpdateIsExtractedToContextPreview(_ value: Bool) {
        if !value {
            if let textSelectionNode = self.textSelectionNode {
                self.textSelectionNode = nil
                textSelectionNode.highlightAreaNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
                textSelectionNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak textSelectionNode] _ in
                    textSelectionNode?.highlightAreaNode.removeFromSupernode()
                    textSelectionNode?.removeFromSupernode()
                })
            }
        }
    }
    
    override func updateIsExtractedToContextPreview(_ value: Bool) {
        if value {
            if self.textSelectionNode == nil, let item = self.item, !item.associatedData.isCopyProtectionEnabled && !item.message.isCopyProtected(), let rootNode = item.controllerInteraction.chatControllerNode() {
                let selectionColor: UIColor
                let knobColor: UIColor
                if item.message.effectivelyIncoming(item.context.account.peerId) {
                    selectionColor = item.presentationData.theme.theme.chat.message.incoming.textSelectionColor
                    knobColor = item.presentationData.theme.theme.chat.message.incoming.textSelectionKnobColor
                } else {
                    selectionColor = item.presentationData.theme.theme.chat.message.outgoing.textSelectionColor
                    knobColor = item.presentationData.theme.theme.chat.message.outgoing.textSelectionKnobColor
                }
                
                let textSelectionNode = TextSelectionNode(theme: TextSelectionTheme(selection: selectionColor, knob: knobColor), strings: item.presentationData.strings, textNode: self.textNode.textNode, updateIsActive: { [weak self] value in
                    self?.updateIsTextSelectionActive?(value)
                }, present: { [weak self] c, a in
                    self?.item?.controllerInteraction.presentGlobalOverlayController(c, a)
                }, rootNode: rootNode, performAction: { [weak self] text, action in
                    guard let strongSelf = self, let item = strongSelf.item else {
                        return
                    }
                    item.controllerInteraction.performTextSelectionAction(item.message.stableId, text, action)
                })
                textSelectionNode.updateRange = { [weak self] selectionRange in
                    if let strongSelf = self, let dustNode = strongSelf.dustNode, !dustNode.isRevealed, let textLayout = strongSelf.textNode.textNode.cachedLayout, !textLayout.spoilers.isEmpty, let selectionRange = selectionRange {
                        for (spoilerRange, _) in textLayout.spoilers {
                            if let intersection = selectionRange.intersection(spoilerRange), intersection.length > 0 {
                                dustNode.update(revealed: true)
                                return
                            }
                        }
                    }
                }
                self.textSelectionNode = textSelectionNode
                self.addSubnode(textSelectionNode)
                self.insertSubnode(textSelectionNode.highlightAreaNode, belowSubnode: self.textNode.textNode)
                textSelectionNode.frame = self.textNode.textNode.frame
                textSelectionNode.highlightAreaNode.frame = self.textNode.textNode.frame
            }
        } else {
            if let textSelectionNode = self.textSelectionNode {
                self.textSelectionNode = nil
                self.updateIsTextSelectionActive?(false)
                textSelectionNode.highlightAreaNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
                textSelectionNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak textSelectionNode] _ in
                    textSelectionNode?.highlightAreaNode.removeFromSupernode()
                    textSelectionNode?.removeFromSupernode()
                })
            }
            
            if let dustNode = self.dustNode, dustNode.isRevealed {
                dustNode.update(revealed: false)
            }
        }
    }
    
    override func reactionTargetView(value: MessageReaction.Reaction) -> UIView? {
        if !self.statusNode.isHidden {
            return self.statusNode.reactionView(value: value)
        }
        return nil
    }
    
    override func getStatusNode() -> ASDisplayNode? {
        return self.statusNode
    }

    func animateFrom(sourceView: UIView, scrollOffset: CGFloat, widthDifference: CGFloat, transition: CombinedTransition) {
        self.view.addSubview(sourceView)

        sourceView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.1, removeOnCompletion: false, completion: { [weak sourceView] _ in
            sourceView?.removeFromSuperview()
        })
        self.textNode.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.08)

        let offset = CGPoint(
            x: sourceView.frame.minX - (self.textNode.textNode.frame.minX - 0.0),
            y: sourceView.frame.minY - (self.textNode.textNode.frame.minY - 3.0) - scrollOffset
        )

        transition.vertical.animatePositionAdditive(node: self.textNode.textNode, offset: offset)
        transition.updatePosition(layer: sourceView.layer, position: CGPoint(x: sourceView.layer.position.x - offset.x, y: sourceView.layer.position.y - offset.y))

        self.statusNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
        transition.horizontal.animatePositionAdditive(node: self.statusNode, offset: CGPoint(x: -widthDifference, y: 0.0))
    }
}

