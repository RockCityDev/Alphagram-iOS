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
import TBDisplay

enum ActType {
    case sent
    case receive
}

struct Activity {
    let actTyoe: ActType
    let dateStr: String
    let title: String
    let status: String
    let bitCost: String
    let symbol: String
    let bitCostTotal: String?
}

protocol TBActivityItem {
    func getActTypeA() -> ActType
    func getDateStrA() -> String
    func getTitleA() -> String
    func getStatusA() -> String
    func getBitCostA() -> String
    func getSymbolA() -> String
    func getBitCostTotalA() -> String?
}

class ActivityNode: UIView {
    
    let titleLab: UILabel
    let statusLab: UILabel
    let costLab: UILabel
    let totalCostLab: UILabel
    
    private var priceDispoble: Disposable?
    
    override init(frame: CGRect) {
        self.titleLab = UILabel()
        self.statusLab = UILabel()
        self.costLab = UILabel()
        self.totalCostLab = UILabel()
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.titleLab.textColor = UIColor(hexString: "#FF1A1A1D")
        self.titleLab.font = Font.medium(16)
        self.addSubview(self.titleLab)
        
        self.statusLab.textColor = UIColor(hexString: "#FF44D320")
        self.statusLab.font = Font.regular(14)
        self.addSubview(self.statusLab)
        
        self.costLab.textColor = UIColor.black
        self.costLab.font = Font.medium(15)
        self.costLab.textAlignment = .right
        self.addSubview(self.costLab)
        
        self.totalCostLab.textColor = UIColor(hexString: "#FF56565C")
        self.totalCostLab.font = Font.medium(13)
        self.totalCostLab.textAlignment = .right
        self.addSubview(self.totalCostLab)
        
        self.titleLab.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.height.equalTo(21)
            make.width.lessThanOrEqualTo(175)
        }
        self.statusLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(25)
            make.leading.equalToSuperview()
            make.height.equalTo(20)
        }
        self.costLab.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(20)
            make.leading.equalTo(self.titleLab.snp_trailingMargin).offset(20)
        }
        self.totalCostLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(27)
            make.trailing.equalToSuperview()
            make.height.equalTo(18)
            make.leading.equalTo(self.statusLab.snp_trailingMargin).offset(20)
        }
        
        self.costLab.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.costLab.setContentHuggingPriority(.required, for: .horizontal)
        self.totalCostLab.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.totalCostLab.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    func updateBit(activity: TBActivityItem) {
        self.titleLab.text = activity.getTitleA()
        self.statusLab.text = activity.getStatusA()
        self.costLab.text = activity.getBitCostA()
        self.totalCostLab.text = activity.getBitCostTotalA()
    }
}

class ActivityControllerCell: UITableViewCell {

    private let dateLab = UILabel()
    private let iconImg = UIImageView()
    private let activityView = ActivityNode()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.dateLab.textColor = UIColor(hexString: "#FFABABAF")
        self.dateLab.font = Font.regular(14)
        self.contentView.addSubview(self.dateLab)
        self.contentView.addSubview(self.iconImg)
        self.contentView.addSubview(self.activityView)
        
        self.dateLab.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(13)
            make.height.equalTo(19)
        }
        
        self.iconImg.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(39)
            make.width.height.equalTo(36)
            make.leading.equalToSuperview().offset(16)
        }
        
        self.activityView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(64)
            make.top.bottom.equalToSuperview().offset(36)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    func updateBit(activity: TBActivityItem) {
        self.dateLab.text = activity.getDateStrA()
        self.activityView.updateBit(activity: activity)
        let imageStr: String
        switch activity.getActTypeA() {
        
        case .sent:
            imageStr = "TBWebPage/icon_sent_crypto"
        case .receive:
            imageStr = "TBWebPage/icon_received_crypto"
        }
        self.iconImg.image = UIImage(named: imageStr)
    }
}

struct EtherscanActivity: HandyJSON {
    var blockHash: String?
    var blockNumber: String?
    var from: String?
    var to: String?
    var gas: String?
    var gasPrice: String?
    var hash: String?
    var input: String?
    var nonce: String?
    var transactionIndex: String?
    var value: String = "0"
    var timeStamp: Double?
    var contractAddress: String?
    var tokenSymbol: String?
    var tokenDecimal: Int?
    var isError: String = "0"
    
    var txreceipt_status: String?
    var cumulativeGasUsed: String?
    var gasUsed: String?
    var confirmations: String?
    var methodId: String?
    var functionName: String?
    
    var currentAddress: String?
    var currentChainType: TBChainType = .unkonw
    var price: String = "0"
    
    func bitCostNum() -> String {
        let decimal = getMainCurrencyDecimalBy(type: self.currentChainType) ?? 0
        let bitCostStr = NSDecimalNumber(string: self.value.decimalString()).dividing(by: NSDecimalNumber(decimal: pow(10, decimal))).description
        return bitCostStr
    }
}

extension EtherscanActivity: TBActivityItem {
    func getActTypeA() -> ActType {
        let isReceived = (self.currentAddress ?? "").lowercased() == self.to
        return isReceived ? .receive : .sent
    }
    
    func getDateStrA() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm"
        return format.string(from:Date(timeIntervalSince1970: self.timeStamp ?? 0))
    }
    
    func getTitleA() -> String {
        let isReceived = (self.currentAddress ?? "").lowercased() == self.to
        if !isReceived {
            return "Send to " + (self.to ?? "")
        } else {
            return "Received from " + (self.from ?? "")
        }
    }
    
    func getStatusA() -> String {
        return self.isError == "0" ? "Confirmed" : "Fail" 
    }
    
    func getBitCostA() -> String {
        let bitCost = self.bitCostNum().decimal(digits: 5)
        let t1 = self.getActTypeA() == .sent ? "- " : "+ "
        let t2 = (bitCost.isEmpty || bitCost == "0") ? "0" : t1 + bitCost
        let t3 = self.getSymbolA().isEmpty ? t2 : t2 + " " + self.getSymbolA()
        return t3
    }
    
    func getSymbolA() -> String {
        return getMainCurrencySymbolBy(type: self.currentChainType) ?? ""
    }
    
    func getBitCostTotalA() -> String? {
        let relCostNum = NSDecimalNumber(string: self.bitCostNum().decimalString())
        let totalStr = relCostNum.multiplying(by: NSDecimalNumber(string: self.price)).description.decimal(digits: 8)
        if !totalStr.isEmpty {
            return  "$" + totalStr
        }
        return ""
    }
}

class ActivityController: UIViewController, SegementSlideContentScrollViewDelegate {
    
    private let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    private var page: Int = 1
    private var currentAddress: String?
    private let chainTypePromise: Promise<TBChainType> = Promise()
    private let pricePromise: ValuePromise<NSDecimalNumber> = ValuePromise(ignoreRepeated: false)
    private var currentChain: TBWeb3ConfigEntry.Chain? {
        didSet {
            if let chainType = currentChain?.getChainType() {
                self.chainTypePromise.set(.single(chainType))
            }
        }
    }
    @objc var scrollView: UIScrollView {
        get {
            return self.tableView
        }
    }
    
    private var activities = [TBActivityItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ActivityControllerCell.self, forCellReuseIdentifier: String(describing: ActivityControllerCell.self))
        self.tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.page = 1
            strongSelf.tableView.mj_footer?.state = .idle
            strongSelf.fetchActivities(page: strongSelf.page)
        })
        self.fetchActivities(page: self.page)
        
        let _ = (combineLatest(self.chainTypePromise.get(),
                               TBWeb3CurrencyPrice.shared.currencyPricePromise.get())
                 |> take(1)
                 |> deliverOnMainQueue).start(next: { [weak self] chainType, prices in
            guard let strongSelf = self else { return }
            let decimal = getMainCurrencyDecimalBy(type: chainType)
            let price = getPriceFor(type: chainType, in: prices)?.usd
            if let d = decimal, let p = price {
                let priceNum = NSDecimalNumber(string: p.decimalString())
                let relP = priceNum.dividing(by: NSDecimalNumber(value: d))
                strongSelf.pricePromise.set(relP)
            }
        })
    }
    
    private func cleanPage() {
        self.activities = [TBActivityItem]()
        self.tableView.reloadData()
        self.tableView.mj_header?.endRefreshing()
        self.tableView.mj_footer?.endRefreshing()
        self.tableView.mj_footer?.resetNoMoreData()
    }
    
    private func fetchActivities(page: Int) {
        if page == 1 {
            DispatchQueue.main.async { self.cleanPage() }
        }
        guard let chain = self.currentChain, let address = self.currentAddress else {
            DispatchQueue.main.async { self.cleanPage() }
            return
        }
        switch chain.getChainType() {
        case .unkonw:
            break
        case .ETH:
            let apikey = TBAccount.shared.systemCheckData.eth_api_key
            let _ = (combineLatest(self.pricePromise.get(),
                TBActivityInteractor.getTransactions(url: "https://api.etherscan.io/api?module=account&action=txlist&sort=asc", apikey: apikey, address: address, page: page, offset: 20)) |> take(1)).start(next: {[weak self] price, result in
                guard let strongSelf = self else { return }
                var activities = result
                for (index, _) in activities.enumerated() {
                    activities[index].currentAddress = address
                    activities[index].currentChainType = chain.getChainType()
                    activities[index].price = price.description
                }
                DispatchQueue.main.async {
                    strongSelf.dealWithActivity(in: page, activity: activities)
                }
            })
        case .Polygon:
            let apikey = TBAccount.shared.systemCheckData.polygon_api_key
            let _ = (combineLatest(self.pricePromise.get(),
                TBActivityInteractor.getTransactions(url: "https://api.polygonscan.com/api?module=account&action=txlist&sort=asc", apikey: apikey, address: address, page: page, offset: 20)
            ) |> take(1)).start(next: {[weak self] price, result in
                guard let strongSelf = self else { return }
                var activities = result
                for (index, _) in activities.enumerated() {
                    activities[index].currentAddress = address
                    activities[index].currentChainType = chain.getChainType()
                    activities[index].price = price.description
                }
                DispatchQueue.main.async {
                    strongSelf.dealWithActivity(in: page, activity: activities)
                }
            })
        case .OS:
            let _ = (combineLatest(self.pricePromise.get(),
                TBOSNetwork.getAppsActivity(address: address, page: page))
                     |> take(1)).start(next: {[weak self] price, result in
                guard let strongSelf = self else { return }
                var activities = result
                for (index, _) in activities.enumerated() {
                    activities[index].currentAddress = address
                    activities[index].price = price.description
                }
                DispatchQueue.main.async {
                    strongSelf.dealWithActivity(in: page, activity: activities)
                }
            })
        case .TT:
            let apikey = TBAccount.shared.systemCheckData.tt_api_key
            let _ = (combineLatest(self.pricePromise.get(), TBActivityInteractor.getTTActivity(address: address, apikey: apikey, page: page)) |> take(1)).start(next: {[weak self] price, result in
                guard let strongSelf = self else { return }
                var activities = result
                for (index, _) in activities.enumerated() {
                    activities[index].price = price.description
                }
                DispatchQueue.main.async {
                    strongSelf.dealWithActivity(in: page, activity: activities)
                }
            })
        }
    }
    
    func dealWithActivity(in page: Int, activity: [TBActivityItem]) {
        if page == 1 {
            self.tableView.mj_header?.endRefreshing()
            self.activities = activity
            self.addFooter()
        } else {
            if activity.count <= 0 {
                self.page = max(self.page - 1, 1)
                self.tableView.mj_footer?.endRefreshingWithNoMoreData()
            } else {
                self.activities.append(contentsOf: activity)
                self.tableView.mj_footer?.endRefreshing()
            }
        }
        self.tableView.reloadData()
    }
    
    func addFooter() {
        if self.tableView.mj_footer != nil {
            self.tableView.mj_footer?.state = .idle
            return
        }
        self.tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.page += 1
            strongSelf.fetchActivities(page: strongSelf.page)
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = self.view.bounds
    }
    
    func updateConfig(chain: TBWeb3ConfigEntry.Chain?, address: String?) {
        self.currentChain = chain
        self.currentAddress = address
        self.page = 1
        self.fetchActivities(page: self.page)
    }
}

extension ActivityController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ActivityControllerCell.self)) as? ActivityControllerCell {
            if indexPath.row < self.activities.count {
                let activity = self.activities[indexPath.row]
                cell.updateBit(activity: activity)
            }else {
                cell.isHidden = true
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 89.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
