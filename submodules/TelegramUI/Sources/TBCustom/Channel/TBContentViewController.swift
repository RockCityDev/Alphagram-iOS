






import UIKit
import Display
import MJRefresh
import AuthorizationUI

private enum TBChannelSectionType: Int {
    case recommend = 1
    case list
}

private enum TBChannelItemType: Int {
    case recommend
    case channel
}


class TBContentViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    let channelHeader: TBChannelHeader = TBChannelHeader()
    private let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: UICollectionViewFlowLayout())
    private var dataSourceArr : [TBCollectionSection] = []
    

//        fatalError("init(coder:) has not been implemented")

    

    override func loadView() {
        super.loadView()
        self.setupView()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    

    
    func setupView() {
        self.configHeader()
        self.configCollection()
        self.batchMakeConstraints()
        self.setupDataSource()
        self.collectionView.reloadData()
    }
    
    func configHeader() {
        
    }
    
    func configCollection() -> Void {
        self.collectionView.backgroundColor = UIColor(rgb: 0xF0F0F0);
        self.displayNode.view.addSubview(self.collectionView)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(TBChannelRecommendCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBChannelRecommendCell.self))
        self.collectionView.register(TBChannelCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBChannelCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        self.collectionView.alwaysBounceVertical = true
        
        MJRefreshNormalHeader {
            debugPrint("[TB]: ")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                self.collectionView.mj_header?.endRefreshing()
                debugPrint("[TB]: ")
            }
        }.autoChangeTransparency(true).link(to: collectionView)
        
        MJRefreshAutoNormalFooter{
            debugPrint("[TB]: ")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                self.collectionView.mj_footer?.endRefreshing()
                debugPrint("[TB]: ")
            }
        }.autoChangeTransparency(true).link(to: self.collectionView)

    }
    
    func batchMakeConstraints() {
        self.displayNode.view.addSubview(channelHeader)
        self.displayNode.view.addSubview(collectionView)
        channelHeader.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(0)
            make.height.equalTo(100)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(channelHeader.snp.bottom)
            make.leading.trailing.bottom.equalTo(0)
        }
    }
    
    
    
    func setupDataSource() ->Void {
        
        
        let recommendSection =  TBCollectionSection()
        recommendSection.sectionType = TBChannelSectionType.recommend.rawValue
        recommendSection.insets = UIEdgeInsets.zero
        recommendSection.minumLineSpace = 0
        recommendSection.minimumInteritemSpace = 0
        
        
        let recommendItem = TBCollectionItem()
        recommendItem.itemType = TBChannelItemType.recommend.rawValue
        recommendItem.cellClass = TBChannelRecommendCell.self
        recommendItem.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 86)
        recommendSection.items = [recommendItem]
        
        
        let listSection =  TBCollectionSection()
        listSection.sectionType = TBChannelSectionType.list.rawValue
        listSection.insets = UIEdgeInsets.zero
        listSection.minumLineSpace = 10
        listSection.minimumInteritemSpace = 0
        
        
        for _ in 1...20 {
            let channelItem = TBCollectionChannelItem()
            channelItem.itemType = TBChannelItemType.channel.rawValue
            channelItem.cellClass = TBChannelCell.self
            channelItem.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 0)
            channelItem.updateLayout()
            
            channelItem.reloadItem = {[weak self] aItem, isAnimation in
                guard let strongSelf = self else {
                    return
                }
                guard let indexPath = aItem.indexPath else {
                    strongSelf.collectionView.reloadData()
                    return
                }
                if isAnimation {
                    strongSelf.collectionView.reloadItems(at: [indexPath])
                }else{
                    strongSelf.collectionView.reloadData()
                }
            }
            listSection.items.append(channelItem)
        }
        
        self.dataSourceArr = [recommendSection, listSection]
        
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let item = TBCollectionSection.item(self.dataSourceArr, indexPath){
            item.indexPath = indexPath
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(item.cellClass), for: indexPath)
            if let aCell = cell as? TBCell {
                aCell.reloadCell(data: item)
            }
            return cell
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.items.count
        }
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSourceArr.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = TBCollectionSection.item(self.dataSourceArr, indexPath){
            return item.itemSize
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.insets
        }
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.minumLineSpace
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.minimumInteritemSpace
        }
        return 0
    }


    

}
