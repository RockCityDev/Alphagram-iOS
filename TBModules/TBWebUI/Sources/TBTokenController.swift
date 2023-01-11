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


protocol TokenItem {
    
    func getIconUrl() -> String?
    func getTokenName() -> String
    func getTokenPrice() -> String
    func getBalance() -> String
    func getTotalAssets() -> String
}

class BitNode: UIView {
    
    private let nameNode: UILabel
    private let markPriceNode: UILabel
    private let countNode: UILabel
    private let totalNodel: UILabel
    
    override init(frame: CGRect) {
        self.nameNode = UILabel()
        self.markPriceNode = UILabel()
        self.countNode = UILabel()
        self.totalNodel = UILabel()
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.nameNode.textColor = UIColor.black
        self.nameNode.font = Font.medium(15)
        self.addSubview(self.nameNode)
        
        self.markPriceNode.textColor = UIColor(hexString: "#FF56565C")
        self.markPriceNode.font = Font.medium(13)
        self.addSubview(self.markPriceNode)
        
        self.countNode.textColor = UIColor.black
        self.countNode.font = Font.medium(15)
        self.countNode.textAlignment = .right
        self.addSubview(self.countNode)
        
        self.totalNodel.textColor = UIColor(hexString: "#FF56565C")
        self.totalNodel.font = Font.medium(13)
        self.totalNodel.textAlignment = .right
        self.addSubview(self.totalNodel)
        
        self.nameNode.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.leading.equalToSuperview()
            make.height.equalTo(20)
        }
        self.markPriceNode.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(37)
            make.leading.equalToSuperview()
            make.height.equalTo(18)
        }
        self.countNode.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.trailing.equalToSuperview()
            make.height.equalTo(18)
            make.leading.equalTo(self.nameNode.snp_trailingMargin).offset(20)
        }
        self.totalNodel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(37)
            make.trailing.equalToSuperview()
            make.height.equalTo(18)
            make.leading.equalTo(self.markPriceNode.snp_trailingMargin).offset(20)
        }
        
        self.countNode.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.countNode.setContentHuggingPriority(.required, for: .horizontal)
        self.totalNodel.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.totalNodel.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    func updateBit(token: TokenItem) {
        self.nameNode.text = token.getTokenName()
        self.markPriceNode.text = token.getTokenPrice()
        self.countNode.text = token.getBalance()
        self.totalNodel.text = token.getTotalAssets()
    }
}

class TokenControllerCell: UITableViewCell {

    private let iconImg = UIImageView()
    private let bitView = BitNode()
    private let accrowImg = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.contentView.addSubview(self.iconImg)
        self.contentView.addSubview(self.bitView)
        self.accrowImg.image = UIImage(named: "TBWebPage/icon_arrow_right_wallet_token")
        self.contentView.addSubview(self.accrowImg)
    
        self.iconImg.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
            make.leading.equalToSuperview().offset(27)
        }
        
        self.bitView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(92)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-47)
        }
        
        self.accrowImg.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.trailing.equalToSuperview().offset(-15)
        }
    }
    
    func updateBit(token: TokenItem) {
        if let icon = token.getIconUrl() {
            if icon.hasPrefix("http") {
                self.iconImg.sd_setImage(with: URL(string: icon), placeholderImage: UIImage())
            } else {
                self.iconImg.image = UIImage(named: icon)
            }
        } else {
            self.iconImg.image = nil
        }
        self.bitView.updateBit(token: token)
    }
}

class TokenController: UIViewController, SegementSlideContentScrollViewDelegate {
    
    private let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    
    @objc var scrollView: UIScrollView {
        get {
            return self.tableView
        }
    }
    
    private var tokens = [TokenItem]()
    
    private var currentAddress: String?
    private var currentChain: TBWeb3ConfigEntry.Chain?
    
    var balanceUsdChange: ((String)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.tableView.register(TokenControllerCell.self, forCellReuseIdentifier: String(describing: TokenControllerCell.self))
        self.tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.fetchAssets()
        })
    }
    
    func fetchAssets() {
        self.updatePage(by: [Assets]())
        guard let chain = self.currentChain, let address = self.currentAddress else {
            return
        }
        let appid = TBAccount.shared.systemCheckData.zapper
        switch chain.getChainType() {
        case .ETH:
            let _ = (TBZapperNetwork.getAppsBalances(appId: appid, addresses: [address]) |> deliverOnMainQueue).start(next: {[weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case let .success(tokens):
                    var assets = [Assets]()
                    if let tokenModels = JSONDeserializer<TokenModel>.deserializeModelArrayFrom(array: tokens) as? [TokenModel] {
                        assets = tokenModels.flatMap{ $0.products.flatMap{ $0.assets} }
                    }
                    strongSelf.tableView.mj_header?.endRefreshing()
                    strongSelf.updatePage(by: assets)
                case .failure(_, _):
                    strongSelf.tableView.mj_header?.endRefreshing()
                    strongSelf.updatePage(by: [Assets]())
                }
            })
        case .Polygon:
            let _ = (TBZapperNetwork.getAppsBalances(network: "polygon", appId: appid, addresses: [address]) |> deliverOnMainQueue).start(next: {[weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case let .success(tokens):
                    var assets = [Assets]()
                    if let tokenModels = JSONDeserializer<TokenModel>.deserializeModelArrayFrom(array: tokens) as? [TokenModel] {
                        assets = tokenModels.flatMap{ $0.products.flatMap{ $0.assets} }
                    }
                    strongSelf.tableView.mj_header?.endRefreshing()
                    strongSelf.updatePage(by: assets)
                case .failure(_, _):
                    strongSelf.tableView.mj_header?.endRefreshing()
                    strongSelf.updatePage(by: [Assets]())
                }
            })
        case .OS:
            Web3NetworkBalanceApi.fetchOasisBalance(address: address).start()
            let _ = combineLatest(TBOSNetwork.getAppsTokens(address: address),
                                  TBOSNetwork.getAppsBalances(address: address),
                                   TBOSNetwork.getTokensPrices()).start(next: { [weak self] tokens, balance, priceDic in
                guard let strongSelf = self else { return }
                var relTokens = tokens.filter({ !$0.isNFT()})
                if let b = balance {
                    var rose = TBOSToken()
                    rose.balance = b
                    rose.decimals = 18
                    rose.name = "oasis-network"
                    rose.symbol = "ROSE"
                    relTokens.insert(rose, at: 0)
                }
                for (index, token) in relTokens.enumerated() {
                    relTokens[index].price = priceDic[token.symbol] ?? "0"
                }
                strongSelf.tableView.mj_header?.endRefreshing()
                strongSelf.updatePage(by: relTokens)
            })
        case .TT:
            Web3NetworkBalanceApi.fetchTTBalance(address: address).start()
            let _ = (combineLatest(TBRPCNetwork.getAppsBalances(address: address), TBWeb3CurrencyPrice.shared.currencyPricePromise.get(),
                                   TBRPCNetwork.getTokensPrice())
                     |> take(1)).start(next: {[weak self] tokens, mPrices, tPrices in
                guard let strongSelf = self else { return }
                let mainP = mPrices.filter({$0.currencyId == "thunder-token"}).first?.price.usd ?? "0"
                var relTokens = tokens
                for (index, token) in relTokens.enumerated() {
                    var balance_usd = "0"
                    var price = "0"
                    if token.symbol == "TT" {
                        price = mainP
                    }
                    if let p = tPrices.filter({$0.symbol == token.symbol}).first?.price {
                        price = p
                    }
                    balance_usd = NSDecimalNumber(string: token.balance.decimalString()).multiplying(by: NSDecimalNumber(string: price.decimalString())).decimalValue.description
                    relTokens[index].price = price
                    relTokens[index].balance_usd = balance_usd
                }
                strongSelf.tableView.mj_header?.endRefreshing()
                strongSelf.updatePage(by: relTokens)
            })
        case .unkonw:
            break
        }
        
    }
    
    func updatePage(by tokens: [TokenItem]) {
        DispatchQueue.main.async {
            self.tokens = tokens
            self.tableView.reloadData()
            var totalBalanceUsd = "0"
            for token in tokens {
              totalBalanceUsd = NSDecimalNumber(string: token.getTotalAssets().decimalString()).adding(NSDecimalNumber(string: totalBalanceUsd.decimalString())).decimalValue.description
            }
            self.balanceUsdChange?(totalBalanceUsd.decimal(digits: 8))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = self.view.bounds
    }
    
    func updateConfig(chain: TBWeb3ConfigEntry.Chain?, address: String?) {
        self.currentChain = chain
        self.currentAddress = address
        self.fetchAssets()
    }
}

extension TokenController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tokens.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenControllerCell.self)) as? TokenControllerCell {
            if indexPath.row < self.tokens.count {
                let bit = self.tokens[indexPath.row]
                cell.updateBit(token: bit)
            } else {
                cell.isHidden = true
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
