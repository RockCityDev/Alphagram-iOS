import UIKit
import SegementSlide
import JXSegmentedView
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import TBBusinessNetwork
import TBAccount
import TBWalletCore
import HandyJSON
import SwiftSignalKit
import SDWebImage
import MJRefresh
import TBWalletUI
import ProgressHUD
import TBLanguage
import TBWeb3Core

protocol TBNFTItem: NFTSettingConfig {
    func getNFTName() -> String
}

class TBNFTAvatarACell: UICollectionViewCell {
    
    let imgView: UIImageView
    let titleLabel: UILabel
    let subTitleLabel: UILabel
    let iconView: UIImageView
    let priceLabel: UILabel
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.imgView = UIImageView()
        self.imgView.contentMode = .scaleAspectFill
        self.imgView.layer.cornerRadius = 5
        self.imgView.clipsToBounds = true
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.titleLabel.textColor = .black
        
        self.subTitleLabel = UILabel()
        self.subTitleLabel.numberOfLines = 1
        self.subTitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        self.subTitleLabel.textColor = UIColor(rgb: 0x868E95)
        
        self.iconView = UIImageView(image: PresentationResourcesSettings.tb_icon_eth_nft_edit)
        self.iconView.contentMode = .scaleAspectFit
        self.iconView.isHidden = true
        
        self.priceLabel = UILabel()
        self.priceLabel.numberOfLines = 1
        self.priceLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        self.priceLabel.textColor = .black
        self.priceLabel.isHidden = true
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor(rgb: 0xE6E6E6).cgColor
        self.contentView.clipsToBounds = true
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.imgView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subTitleLabel)
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.priceLabel)
        
        self.imgView.snp.makeConstraints { make in
            make.top.leading.equalTo(11)
            make.centerX.equalTo(self.contentView)
            make.height.equalTo(self.imgView.snp.width)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(25)
            make.top.equalTo(self.imgView.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualTo(-11)
        }
        self.subTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(-11)
        }
        self.iconView.snp.makeConstraints { make in
            make.leading.equalTo(22)
            make.top.equalTo(self.subTitleLabel.snp.bottom).offset(5)
            make.width.height.equalTo(13)
        }
        self.priceLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.iconView.snp.trailing).offset(3)
            make.centerY.equalTo(self.iconView)
            make.trailing.lessThanOrEqualTo(-11)
        }
    }
    
    public func reloadCell(item: TBNFTItem) {
        let imgUrl = item.nftContractImage()
        if let url = URL(string: imgUrl) {
            self.imgView.sd_setImage(with: url)
        } else {
            self.imgView.image = nil
        }
        self.titleLabel.text = item.nftAssetName()
        self.subTitleLabel.text = item.getNFTName()
        self.priceLabel.text = item.nftPrice()
    }
}

class NFTController: UIViewController, SegementSlideContentScrollViewDelegate {
    
    private let collectionView: UICollectionView
    fileprivate var items = [TBNFTItem]()
    private var interactor: TBNFTInteractor?
    private var currentAddress: String?
    private var currentChain: TBWeb3ConfigEntry.Chain?
    
    @objc var scrollView: UIScrollView {
        get {
            return self.collectionView
        }
    }
    
    var nftAvatarSelected: ((TBNFTItem) -> ())?
    
    init() {
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(TBNFTAvatarACell.self, forCellWithReuseIdentifier: NSStringFromClass(TBNFTAvatarACell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        
        self.collectionView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [weak self] in
            self?.fetchFirstPage()
        })
        let mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.loadMorePage()
        })
        mj_footer.setTitle("", for: .noMoreData)
        mj_footer.setTitle("", for: .idle)
        
        self.collectionView.mj_footer = mj_footer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.collectionView.frame = self.view.bounds
    }
    
    func fetchFirstPage() {
        DispatchQueue.main.async {
            self.items = [TBNFTAssetItem]()
            self.collectionView.reloadData()
            self.collectionView.mj_header?.endRefreshing()
            self.collectionView.mj_footer?.resetNoMoreData()
        }
        guard let chain = self.currentChain, let address = self.currentAddress else {
            return
        }
        self.collectionView.mj_footer?.state = .idle
        switch chain.getChainType() {
        case .unkonw:
            self.items = [TBNFTAssetItem]()
            self.collectionView.reloadData()
            self.collectionView.mj_header?.endRefreshing()
            self.collectionView.mj_footer?.resetNoMoreData()
        case .TT:
            let _ = (TBRPCNetwork.getTTNFT(address: address) |> mapToSignal({ a in
                return TBRPCNetwork.getTTNFTPath(nfts: a)
            }) |> mapToSignal({ b in
                return TBRPCNetwork.getTTNFTDetails(nfts: b)
            })).start(next: {[weak self] c in
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    strongSelf.items = c
                    strongSelf.collectionView.reloadData()
                    strongSelf.collectionView.mj_header?.endRefreshing()
                    strongSelf.collectionView.mj_footer?.resetNoMoreData()
                }
            })
        case .OS:
            let _ = (TBOSNetwork.getAppsTokens(address: address) |> deliverOnMainQueue).start(next: { [weak self] tokens in
                guard let strongSelf = self else { return }
                let relTokens = tokens.filter({ $0.isNFT()})
                DispatchQueue.main.async {
                    strongSelf.items = relTokens
                    strongSelf.collectionView.reloadData()
                    strongSelf.collectionView.mj_header?.endRefreshing()
                    strongSelf.collectionView.mj_footer?.resetNoMoreData()
                }
            })
        case .Polygon:
            self.interactor = TBNFTInteractor(walletAddress: address, isEth: false)
            self.interactor?.refreshPageData(callBack: {[weak self] assetItems, hasMore in
                guard let strongSelf = self else { return }
                strongSelf.items = assetItems
                strongSelf.collectionView.reloadData()
                strongSelf.collectionView.mj_header?.endRefreshing()
                if hasMore {
                    strongSelf.collectionView.mj_footer?.resetNoMoreData()
                }
            })
        case .ETH:
            self.interactor = TBNFTInteractor(walletAddress: address, isEth: true)
            self.interactor?.refreshPageData(callBack: {[weak self] assetItems, hasMore in
                guard let strongSelf = self else { return }
                strongSelf.items = assetItems
                strongSelf.collectionView.reloadData()
                strongSelf.collectionView.mj_header?.endRefreshing()
                if hasMore {
                    strongSelf.collectionView.mj_footer?.resetNoMoreData()
                }
            })
        }
    }
    
    func loadMorePage() {
        guard let chain = self.currentChain else {
            self.collectionView.mj_footer?.endRefreshing()
            self.collectionView.mj_footer?.resetNoMoreData()
            return
        }
        switch chain.getChainType() {
        case .unkonw:
            self.collectionView.mj_footer?.endRefreshing()
            self.collectionView.mj_footer?.resetNoMoreData()
        case .Polygon, .ETH:
            self.interactor?.loadNextPageData(callBack: {[weak self] assetItems, hasMore in
                self?.items = assetItems
                self?.collectionView.reloadData()
                if hasMore {
                    self?.collectionView.mj_footer?.endRefreshing()
                }else{
                    self?.collectionView.mj_footer?.endRefreshingWithNoMoreData()
                }
            })
        case .OS:
            self.collectionView.mj_footer?.endRefreshing()
            self.collectionView.mj_footer?.resetNoMoreData()
        case .TT:
            self.collectionView.mj_footer?.endRefreshing()
            self.collectionView.mj_footer?.resetNoMoreData()
        }
    }
    
    func updateConfig(chain: TBWeb3ConfigEntry.Chain?, address: String?) {
        self.currentChain = chain
        self.currentAddress = address
        self.fetchFirstPage()
    }
}

extension NFTController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let item = self.safeItem(at: indexPath) {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TBNFTAvatarACell.self), for: indexPath) as? TBNFTAvatarACell {
                cell.reloadCell(item: item)
                return cell
            }
            
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
    }
}

extension NFTController {
    fileprivate func safeItem(at indexPath: IndexPath) -> TBNFTItem? {
        if indexPath.item < self.items.count {
            return self.items[indexPath.item]
        }else{
            return nil
        }
    }
}

extension NFTController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < self.items.count {
            let item = self.items[indexPath.row]
            self.nftAvatarSelected?(item)
        }
    }
}

extension NFTController : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 16.0 - 35 * 2.0) / 2.0
        let itemHeight = (itemWidth - 11 * 2.0) + 60.0
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
