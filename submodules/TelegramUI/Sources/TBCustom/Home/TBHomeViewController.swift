






import UIKit
import Display
import AccountContext
import AuthorizationUI

enum TBHomeSectionType: Int {
    case walletAsset = 1
    case kingKong
    case messageGroup
}

enum TBHomeItemType: Int {
    case asset = 1
    case tool
    case friend
    case atMe
    case notContact
    case messageGroup
}

class TBHomeViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    public let chatListController : ChatListController
    
    private var collectionView : UICollectionView?
    private var dataSourceArr : [TBCollectionSection] = []
    
    
    public init(aChatListController : ChatListController) {
        self.chatListController = aChatListController
        super.init(navigationBarPresentationData: nil)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        self.title = ""
        self.setupDataSource()
        self.setupCollection()
        self.collectionView?.reloadData()
    }
    
    override func displayNodeDidLoad () {
        super.displayNodeDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
     
    
    func setupCollection() -> Void {
        self.collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView?.backgroundColor = UIColor.red;
        self.displayNode.view.addSubview(self.collectionView!)
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        self.collectionView?.register(TBHomeWalletCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBHomeWalletCell.self))
        self.collectionView?.register(TBHomeKingKongCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBHomeKingKongCell.self))
        self.collectionView?.register(TBHomeMessageGroupCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBHomeMessageGroupCell.self))
    }
    
    func setupDataSource() ->Void {
        
        
        let assetSection =  TBCollectionSection()
        assetSection.sectionType = TBHomeSectionType.walletAsset.rawValue
        
        let assetItem = TBCollectionItem()
        assetItem.itemType = TBHomeItemType.asset.rawValue
        assetItem.cellClass = TBHomeWalletCell.self
        assetSection.items = [assetItem]
        
        
        let kingkongSection =  TBCollectionSection()
        kingkongSection.sectionType = TBHomeSectionType.kingKong.rawValue
        
        let toolItem = TBCollectionItem()
        toolItem.itemType = TBHomeItemType.tool.rawValue
        toolItem.cellClass = TBHomeKingKongCell.self
        
        let friendItem = TBCollectionItem()
        friendItem.itemType = TBHomeItemType.friend.rawValue
        friendItem.cellClass = TBHomeKingKongCell.self
        kingkongSection.items = [toolItem, friendItem]
        
        
        let messageGroupSection =  TBCollectionSection()
        messageGroupSection.sectionType = TBHomeSectionType.messageGroup.rawValue
        
        let messsageGroupItem = TBCollectionItem()
        messsageGroupItem.itemType = TBHomeItemType.messageGroup.rawValue
        messsageGroupItem.cellClass = TBHomeMessageGroupCell.self
        messageGroupSection.items = [messsageGroupItem]
        
        self.dataSourceArr = [assetSection, kingkongSection, messageGroupSection]
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = self.dataSourceArr[indexPath.section]
        let item = section.items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(item.cellClass), for: indexPath)
        if item.itemType == TBHomeItemType.messageGroup.rawValue {
            let messageGroupCell :TBHomeMessageGroupCell = cell as! TBHomeMessageGroupCell
            messageGroupCell.loadChatListControllerIfNeeded(aChatListContrller:self.chatListController, inController: self)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = self.dataSourceArr[section]
        return section.items.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSourceArr.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let section = self.dataSourceArr[indexPath.section]
        let item = section.items[indexPath.row]
        
        if item.itemType == TBHomeItemType.messageGroup.rawValue{
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        return CGSize(width: UIScreen.main.bounds.width, height: 56)
    }
    
    

}
