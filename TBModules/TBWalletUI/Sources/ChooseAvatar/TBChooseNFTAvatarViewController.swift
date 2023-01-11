






import Foundation
import Display
import AccountContext
import TelegramPresentationData
import AsyncDisplayKit
import SnapKit
import ProgressHUD
import TBLanguage
import MJRefresh
import TBOpenSea
import TBAccount
import SDWebImage
import TBWalletCore


 public class TBChooseNFTAvatarViewController:ViewController {
     private let context : AccountContext
     private let presentationData: PresentationData
     private let arguments: TBChooseNFTAvatarViewControllerArguments
     private let collectionView: UICollectionView
     private let interactor: TBChooseNFTAvatarInteractor
     private let walletConnect: TBWalletConnect
     fileprivate var items = [TBAssetItem]()
     
    
     public init(context: AccountContext, connect:TBWalletConnect, arguments:TBChooseNFTAvatarViewControllerArguments) {
         self.context = context
         self.walletConnect = connect
         self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
         self.arguments = arguments
         self.interactor = TBChooseNFTAvatarInteractor(walletAddress: self.walletConnect.getAccountId(), host: nil)
         let layout = UICollectionViewFlowLayout()
         self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        
         let baseNavigationBarPresentationData = NavigationBarPresentationData(presentationData: self.presentationData)
         
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
         
        
         self.title = TBLanguage.sharedInstance.localizable(TBLankey.setting_select_nft_avatar)
         self.tabBarItem.title = nil
         
     }
     
     public override func displayNodeDidLoad() {
         super.displayNodeDidLoad()
         self.displayNode.backgroundColor = .white
         
         self.view.addSubview(self.collectionView)
         
         self.collectionView.contentInsetAdjustmentBehavior = .never
         self.collectionView.delegate = self
         self.collectionView.dataSource = self
         self.collectionView.backgroundColor = .white
         self.collectionView.register(TBNFTAvatarCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBNFTAvatarCell.self))
         self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
         
         self.collectionView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [weak self] in
             self?.interactor.refreshPageData(callBack: {[weak self] assetItems, hasMore in
                 self?.items = assetItems
                 self?.collectionView.reloadData()
                 self?.collectionView.mj_header?.endRefreshing()
                 if hasMore {
                     self?.collectionView.mj_footer?.resetNoMoreData()
                 }
                 if assetItems.count == 0 {
                     if let navCtr = self?.navigationController as? NavigationController {
                        let _ = navCtr.popViewController(animated: true)
                         ProgressHUD.showFailed(TBLanguage.sharedInstance.localizable(TBLankey.setting_there_is_no_nft_in_wallet))
                     }
                 }
             })
         })
         
         let mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
             self?.interactor.loadNextPageData(callBack: {[weak self] assetItems, hasMore in
                 self?.items = assetItems
                 self?.collectionView.reloadData()
                 if hasMore {
                     self?.collectionView.mj_footer?.endRefreshing()
                 }else{
                     self?.collectionView.mj_footer?.endRefreshingWithNoMoreData()
                 }
                 
             })
         })
         mj_footer.setTitle("", for: .noMoreData)
         mj_footer.setTitle("", for: .idle)
         self.collectionView.mj_footer = mj_footer
         
         self.collectionView.mj_header?.beginRefreshing()
         
         self.collectionView.reloadData()
     }
     
     public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
         super.containerLayoutUpdated(layout, transition: transition)
         let y = (layout.statusBarHeight ?? 20) + 44
         self.collectionView.frame = CGRect(x: 0, y: y, width: layout.size.width, height: layout.size.height - y)
     }
    
     required init(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }

}

extension TBChooseNFTAvatarViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let item = self.safeItem(at: indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TBNFTAvatarCell.self), for: indexPath)
            if let cell:TBNFTAvatarCell = cell as? TBNFTAvatarCell {
                cell.reloadCell(item: item)
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}

extension TBChooseNFTAvatarViewController {
    fileprivate func safeItem(at indexPath: IndexPath) -> TBAssetItem? {
        if indexPath.item < self.items.count {
            return self.items[indexPath.item]
        }else{
            return nil
        }
    }
}

extension TBChooseNFTAvatarViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            if let url = URL(string: item.original_url) {
                ProgressHUD.show(TBLanguage.sharedInstance.localizable(TBLankey.setting_Downloading_original_image_please_wait))
                SDWebImageDownloader.shared.downloadImage(with: url) {[weak self] image, _, error, _ in
                    if let image = image {
                        if let navCtrl = self?.navigationController as? NavigationController {
                           let _ = navCtrl.popViewController(animated: true)
                            self?.arguments.didChooseOrignalImage(image, item)
                        }
                        ProgressHUD.dismiss()
                    }else if let error = error {
                        ProgressHUD.showError("\(error.localizedDescription)")
                    }
                }
               
            }
        }
    }
}

extension TBChooseNFTAvatarViewController : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 16.0 - 35 * 2.0) / 2.0
        let itemHeight = (itemWidth - 11 * 2.0) + 84.0
        return CGSize(width:CGFloat(floorf(Float(itemWidth))) , height: itemHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 9, left: 35, bottom: 9, right: 35)
    }
    
}

extension TBAssetItem: NFTSettingConfig {
    public func nftAssetName() -> String? {
        return self.asset_name
    }
    
    public func nftContract() -> String {
        return self.contract_address
    }
    
    public func nftContractImage() -> String {
        return self.original_url
    }
    
    public func nftTokenId() -> String {
        return self.token_id
    }
    
    public func nftPhotoId() -> String? {
        return self.nft_photo_id
    }
    
    public func nftChainId() -> String? {
        return self.nft_chain_id
    }
    
    public func nftPrice() -> String? {
        return self.presentPrice
    }
    
    public func nftTokenStandard() -> String? {
        return self.token_standard
    }
}
