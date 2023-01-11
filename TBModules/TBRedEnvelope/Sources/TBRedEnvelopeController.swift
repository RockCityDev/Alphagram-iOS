import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AnimationCache
import MultiAnimationRenderer
import AccountContext
import TBWeb3Core
import TBAccount
import AvatarNode
import TBLanguage
import TBWalletCore
import TBDisplay
import ProgressHUD

enum GasfeeType {
    case none
    case gas(num: Int, price: String, symbol: String)
}

private enum ResetType {
    case all
    case network
    case currency
}

private enum RedayType {
    case success
    case fault
}

struct TBTransferAssetOrder {
    
    public var fromAddress: String = ""
    public var toAddress: String = ""
    
    public var network: String = ""
    public var icon: String = ""
    public var decimals: Int = 0
    public var symbol: String = ""
    public var address: String?
    public var balance: String = ""
    public var amount: String = ""
    public var price: String = ""
    public var chainId: String = ""
    public var currencyId: String = ""
    
}

struct RedEnvelopeCreate {
    
    let amount: String
    
    let num: String
    
    let chain_id: String
    let chain_name: String
    let currency_id: String
    let currency_name: String
    
    let payment_account: String
    
    let gas_amount: String
    
    let source: String
    
    
    let currency_price: String
}

private enum State: Equatable {
    case inital
    case unReady(chainType: TBChainType)
    case reday(readType: RedayType)
    
    static func == (lhs: State, rhs: State) -> Bool {
        switch lhs {
        case .inital:
            if case .inital = rhs {
                return true
            } else {
                return false
            }
        case .unReady(let lct):
            if case let .unReady(rct) = rhs {
                return lct == rct
            } else {
                return false
            }
        case .reday(let lct):
            if case let .reday(rct) = rhs {
                return lct == rct
            } else {
                return false
            }
        }
    }
}

public class TBRedEnvelopeController: ViewController {
    
    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private var redEnvelopeNode: TBRedEnvelopeControllerNode {
        return super.displayNode as! TBRedEnvelopeControllerNode
    }
    
    private let toPeerId: PeerId
    private let isPersonnal: Bool
    
    private var chainConfig: TBWeb3ConfigEntry?
    private var rpConfig: RedEnvelopeConfig = .emptyConfig
    private var wallets = [TBWallet]()
    private var currentWallet: TBWallet?
    private var currentChain: TBWeb3ConfigEntry.Chain?
    private var fromAddress: String = "0x352e40B46ec304B929bfC492d9FD7fA2B2E33356"
    private var rpCreate: RedEnvelopeCreate?
    
    private let stateValue: Atomic<State>
    private let statePromise: ValuePromise<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let rNumberPromise = ValuePromise<Int>(ignoreRepeated: true)
    
    public var sendRedPackEvent: ((String) -> ())?
    
    public init(context: AccountContext, toPeerId: PeerId, chain: TBWeb3ConfigEntry.Chain? = nil) {
        self.context = context
        self.toPeerId = toPeerId
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        if  toPeerId.namespace == Namespaces.Peer.CloudChannel || toPeerId.namespace == Namespaces.Peer.CloudGroup {
            self.isPersonnal = false
        } else {
            self.isPersonnal = true
        }
        self.rNumberPromise.set( self.isPersonnal ? 1 : 0)
        
        let initalState = State.inital
        let stateValue = Atomic(value: initalState)
        let statePromise = ValuePromise(initalState, ignoreRepeated: true)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify{ f($0) })
        }
        
        self.stateValue = stateValue
        self.statePromise = statePromise
        self.updateState = updateState
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.displayNavigationBar = false
        let walletSignal = TBWalletWrapper.getAllWalletsSignal(context: context, password: "")
                            |> filter({!$0.isEmpty})
        let web3ConfigSignal = TBWeb3Config.shared.configSignal
                                |> take(1)
        let _ = (combineLatest(walletSignal,
                               web3ConfigSignal,
                               TBRedEnvelopeInteractor.fetchRedEnvelopeConfig())
                 |> deliverOnMainQueue).start(next: {[weak self] ws, config, rpConfig in
            if let strongSelf = self, let config = config {
                strongSelf.wallets = ws
                strongSelf.chainConfig = config
                strongSelf.rpConfig = rpConfig
                if let curW = strongSelf.currentWallet, ws.contains(curW) {
                    
                } else {
                    strongSelf.currentWallet = ws.first
                    if let c = chain {
                        strongSelf.currentChain = c
                    } else {
                        strongSelf.currentChain = config.chainType.first
                    }
                    strongSelf.updateState { _ in
                        return .inital
                    }
                    strongSelf.selectedWallet(strongSelf.currentWallet)
                }
            }
        })
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.stateDisposable?.dispose()
    }

     override public func loadDisplayNode() {
         self.displayNode = TBRedEnvelopeControllerNode(context: self.context, presentationData: self.presentationData, isPersonnal: self.isPersonnal)
         self.displayNodeDidLoad()
     }
    
    override public func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: { [weak self] state in
            guard let strongSelf = self else { return }
            switch state {
            case .inital:
                strongSelf.resetPage(by: .all)
            case .unReady(_):
                strongSelf.redEnvelopeNode.navNode.updateWallet(by: strongSelf.currentWallet ?? UnClearNetworkItem())
                strongSelf.redEnvelopeNode.updateNetwork(strongSelf.currentChain)
                strongSelf.resetPage(by: .currency)
            case .reday(let type):
                switch type {
                case .success:
                    strongSelf.updateTokens()
                case .fault:
                    strongSelf.resetPage(by: .currency)
                }
            }
        })
        
        self.redEnvelopeNode.navNode.closeEvent = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        self.redEnvelopeNode.sendEvent = { [weak self] in
            guard let strongSelf = self, let curChain = strongSelf.currentChain, let wallet = strongSelf.currentWallet, let c = strongSelf.rpCreate else { return }
            strongSelf.redEnvelopeNode.endEdit()
            ProgressHUD.show("Start")
            if case let .mine(wm) = wallet, let param = strongSelf.currentParamType(by: curChain.getChainType()) {
                Task {
                    if let hash = await TBMyWallet.transaction(toAddress: strongSelf.rpConfig.address, chainInfo: param, account: wm, password: "", value: NSDecimalNumber(string: c.gas_amount).adding(NSDecimalNumber(string: c.amount)).description).hash {
                        let _ = (TBRedEnvelopeInteractor.ceateRedEnvelop(tx_hash: hash,
                                                                amount: c.amount,
                                                                num: c.num,
                                                                chain_id: c.chain_id,
                                                                chain_name: c.chain_name,
                                                                currency_id: c.currency_id,
                                                                currency_name: c.currency_name,
                                                                payment_account: c.payment_account,
                                                                gas_amount: c.gas_amount,
                                                                source: c.source)
                                 |> deliverOnMainQueue).start(next: { result in
                            guard let strongSelf = self else { return }
                            if result.isError() {
                                ProgressHUD.showError("Fault")
                            } else {
                                strongSelf.jumpToVerify(result: result)
                            }
                        })
                    } else {
                        ProgressHUD.showError("Fault")
                    }
                }
                return
            }
            if case let .connect(connect) = wallet, let order = strongSelf.currentOrder(by: curChain.getChainType()) {
                var chainType: String = ""
                switch order.network.uppercased() {
                case "ETHEREUM":
                    chainType = ETHChain
                case "POLYGON":
                    chainType = PolygonChain
                case "THUNDERCORE":
                    chainType = TTChain
                case "OASIS":
                    chainType = OasisChain
                default:
                    chainType = ""
                }
                let value = NSDecimalNumber(string: order.amount.decimalString()).multiplying(by: NSDecimalNumber(decimal: pow(10, order.decimals))).toBase(16)
                connect.TBWallet_SendTransaction(from: order.fromAddress, to: order.toAddress, chainType: chainType, value: value, contractAddress: order.address ?? "") { hash in
                    if hash.count > 0 {
                        let _ = TBRedEnvelopeInteractor.ceateRedEnvelop(tx_hash: hash,
                                                                amount: c.amount,
                                                                num: c.num,
                                                                chain_id: c.chain_id,
                                                                chain_name: c.chain_name,
                                                                currency_id: c.currency_id,
                                                                currency_name: c.currency_name,
                                                                payment_account: c.payment_account,
                                                                gas_amount: c.gas_amount,
                                                                source: c.source).start(next: { result in
                            guard let strongSelf = self else { return }
                            if result.isError() {
                                ProgressHUD.showError("Fault")
                            } else {
                                strongSelf.jumpToVerify(result: result)
                            }
                        })
                    } else {
                        ProgressHUD.showError("Fault")
                    }
                }
                return
            }
        }
        
        self.redEnvelopeNode.networkNode.titleClickEvent = { [weak self] in
            self?.redEnvelopeNode.endEdit()
            guard let strongSelf = self,
                let config = strongSelf.chainConfig,
                let currentChain = strongSelf.currentChain,
                let index = config.chainType.firstIndex(of: currentChain) else { return }
            let popVc = TBPopController(context: strongSelf.context, canCloseByTouches: true)
            let node = TBSegmentNode()
            let size = node.updateSegment(title: "Networks", items: config.chainType, selectedIndex: index)
            node.cornerRadius = 12
            node.backgroundColor = UIColor.white
            node.closeEvent = {[weak popVc] in
                popVc?.dismiss(animated: true)
            }
            node.selectedSegmentEvent = {[weak popVc, weak self] chain in
                self?.selectedNetwork(chain as! TBWeb3ConfigEntry.Chain)
                popVc?.dismiss(animated: true)
            }
            let screenSize = UIScreen.main.bounds.size
            popVc.setContentNode(node, frame: CGRect(origin: CGPoint(x: (screenSize.width - size.width) / 2, y: (screenSize.height - size.height) / 2), size: size))
            popVc.pop(from: strongSelf, transition: .immediate)
            DispatchQueue.main.async {
                node.updateLayout(size: size)
                node.updateData()
            }
        }
        
        self.redEnvelopeNode.currencyNode.currencyClickEvent = { [weak self] in
            self?.redEnvelopeNode.endEdit()
            guard let strongSelf = self else { return }
            let items: [TBTokenItem] = strongSelf.getCurrentTokens() ?? [TbToken]()
            let popVc = TBPopController(context: strongSelf.context)
            let node = TBRedEnvelopeTokensNode(context: strongSelf.context, isEmpty: items.count == 0)
            let size = node.updateSegment(title: "Selecte a token", items: items)
            node.cornerRadius = 12
            node.backgroundColor = UIColor.white
            node.closeEvent = {[weak popVc] in
                popVc?.dismiss(animated: true)
            }
            node.selectedSegmentEvent = {[weak popVc, weak self] token in
                self?.selectedToken(token: token)
                popVc?.dismiss(animated: true)
            }
            let screenSize = UIScreen.main.bounds.size
            popVc.setContentNode(node, frame: CGRect(origin: CGPoint(x: (screenSize.width - size.width) / 2, y: screenSize.height - size.height + 12), size: size))
            popVc.pop(from: strongSelf, transition: .immediate)
            DispatchQueue.main.async {
                node.updateLayout(size: size)
                node.updateData()
            }
        }
        
        let _ = (combineLatest(self.redEnvelopeNode.currencyNode.bitInputPromise.get(),
                               self.rNumberPromise.get())
                 |> deliverOnMainQueue).start(next: { [weak self] bitCount, rNumber in
            guard let strongSelf = self, let chain = strongSelf.currentChain else { return }
            var balanceNum: NSDecimalNumber?
            var priceNum: NSDecimalNumber?
            var symbol: String?
            var config: RedEnvelopeConfig.Currency?
            switch chain.getChainType() {
            case .unkonw:
                break
            case .ETH:
                if let curretToken = strongSelf.curEthToken {
                    balanceNum = NSDecimalNumber(string: curretToken.tokenCount().decimalString())
                    priceNum = NSDecimalNumber(string: curretToken.tokenMarketPrice().decimalString())
                    symbol = curretToken.getTitle()
                    config = strongSelf.currencyConfig(chainName: chain.name, currencyName: curretToken.getTitle())
                }
            case .TT:
                if let curretToken = strongSelf.curTTToken {
                    balanceNum = NSDecimalNumber(string: curretToken.tokenCount().decimalString())
                    priceNum = NSDecimalNumber(string: curretToken.tokenMarketPrice().decimalString())
                    symbol = curretToken.getTitle()
                    config = strongSelf.currencyConfig(chainName: chain.name, currencyName: curretToken.getTitle())
                }
            case .OS:
                if let curretToken = strongSelf.curOsToken {
                    balanceNum = NSDecimalNumber(string: curretToken.tokenCount().decimalString())
                    priceNum = NSDecimalNumber(string: curretToken.tokenMarketPrice().decimalString())
                    symbol = curretToken.getTitle()
                    config = strongSelf.currencyConfig(chainName: chain.name, currencyName: curretToken.getTitle())
                }
            case .Polygon:
                if let curretToken = strongSelf.curPolygonToken {
                    balanceNum = NSDecimalNumber(string: curretToken.tokenCount().decimalString())
                    priceNum = NSDecimalNumber(string: curretToken.tokenMarketPrice().decimalString())
                    symbol = curretToken.getTitle()
                    config = strongSelf.currencyConfig(chainName: chain.name, currencyName: curretToken.getTitle())
                }
            }
            if let c = config, !c.max_num.isEmpty, !c.min_price.isEmpty {
                if rNumber > 0 && NSDecimalNumber(string: bitCount.decimalString()).compare(NSNumber(value: 0)) == .orderedDescending {
                    if NSDecimalNumber(string: c.max_num.decimalString()).compare(NSNumber(value: rNumber)) == .orderedAscending {
                        ProgressHUD.showError("")
                        strongSelf.redEnvelopeNode.gasFeeNode.updateGas(by: .none)
                        strongSelf.redEnvelopeNode.updateSumTokens("")
                        strongSelf.redEnvelopeNode.updateFromBalance(by: .none)
                        strongSelf.updateNextButtonStatus(useAble: false)
                        return
                    }
                    if NSDecimalNumber(string: bitCount.decimalString()).dividing(by: NSDecimalNumber(value: rNumber)).compare(NSDecimalNumber(string: c.min_price.decimalString())) == .orderedAscending {
                        ProgressHUD.showError("")
                        strongSelf.redEnvelopeNode.gasFeeNode.updateGas(by: .none)
                        strongSelf.redEnvelopeNode.updateSumTokens("")
                        strongSelf.redEnvelopeNode.updateFromBalance(by: .none)
                        strongSelf.updateNextButtonStatus(useAble: false)
                        return
                    }
                }
            } else {
                strongSelf.redEnvelopeNode.gasFeeNode.updateGas(by: .none)
                strongSelf.redEnvelopeNode.updateSumTokens("")
                strongSelf.redEnvelopeNode.updateFromBalance(by: .none)
                strongSelf.updateNextButtonStatus(useAble: false)
                return
            }
            let gasfee = config?.gas_price
            
            if let gas = gasfee, !gas.isEmpty, let s = symbol, rNumber > 0 {
                strongSelf.redEnvelopeNode.gasFeeNode.updateGas(by: GasfeeType.gas(num: rNumber, price: gas, symbol: s))
            } else {
                strongSelf.redEnvelopeNode.gasFeeNode.updateGas(by: .none)
            }
            
            if let s = symbol, bitCount.count > 0 {
                strongSelf.redEnvelopeNode.updateSumTokens(bitCount + s)
            } else {
                strongSelf.redEnvelopeNode.updateSumTokens("")
            }
            
            let inputNumber = NSDecimalNumber(string: bitCount.decimalString())
            if let gas = gasfee,
               !gas.isEmpty,
               let balance = balanceNum,
               let price = priceNum,
               gas.count > 0,
               rNumber > 0,
               inputNumber.compare(NSDecimalNumber(string: "0")) == .orderedDescending
            {
                let gas_amount_num = NSDecimalNumber(string: "\(rNumber)").multiplying(by: NSDecimalNumber(string: gas.decimalString()))
                let totalNum = gas_amount_num.adding(inputNumber)
                if balance.compare(NSDecimalNumber(string: "0")) != .orderedDescending || balance.compare(totalNum) == .orderedAscending {
                    strongSelf.redEnvelopeNode.updateFromBalance(by: .lackOfBalance)
                    strongSelf.updateNextButtonStatus(useAble: false)
                } else {
                    let totalP = price.multiplying(by: totalNum).decimalValue.description
                    strongSelf.redEnvelopeNode.updateFromBalance(by: .input(value: "$\(totalP)"))
                    strongSelf.rpCreate = RedEnvelopeCreate(amount: bitCount, num: "\(rNumber)", chain_id: "\(chain.id)", chain_name: chain.name, currency_id: "\(config!.id)", currency_name: "\(config!.name)", payment_account: strongSelf.fromAddress, gas_amount: gas_amount_num.description, source: strongSelf.isPersonnal ? "2" : "1", currency_price: price.description)
                    strongSelf.updateNextButtonStatus(useAble: true)
                }
            } else {
                strongSelf.redEnvelopeNode.updateFromBalance(by: .none)
                strongSelf.updateNextButtonStatus(useAble: false)
            }
        })
        
        self.redEnvelopeNode.navNode.walletNode.titleClickEvent = { [weak self] in
            guard let strongSelf = self, let wallet = strongSelf.currentWallet else { return }
            let params = TBMyWalletListController.Params(initialWallets: strongSelf.wallets, initialSelectWallet: wallet, selectWallet: {[weak self] wallet in
                guard let strongSelf = self else {return}
                strongSelf.currentWallet = wallet
                strongSelf.updateState { _ in
                    return .inital
                }
                strongSelf.selectedWallet(wallet)
            })
            let walletListController = TBMyWalletListController(context: strongSelf.context, params: params)
            strongSelf.present(walletListController, in: .window(.root))
        }
        
        let _ = self.redEnvelopeNode.redEnvelopAmountNode.amountInputPromise.get().start(next: {[weak self] text in
            guard let strongSelf = self, !strongSelf.isPersonnal else { return }
            let rNumber = Int(text) ?? 0
            strongSelf.rNumberPromise.set(rNumber)
        })
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        if let height = layout.inputHeight, height > 0 { return }
        self.redEnvelopeNode.update(layout: layout, transition: transition)
    }
    
    
    func selectedWallet(_ wallet: TBWallet?) {
        if let wallet = wallet, let chain = self.currentChain {
            self.fromAddress = wallet.walletAddress()
            self.selectedNetwork(chain, forceUpdate: true)
            self.redEnvelopeNode.navNode.updateWallet(by: wallet)
        } else {
            self.resetPage(by: .all)
        }
    }
    
    func updateTokens() {
        guard let chain = self.currentChain else { return }
        switch chain.getChainType() {
        case .ETH:
            if let assets = self.ethAssets, assets.count > 0 {
                self.updateEthCurrency(by: assets.first!)
            }
        case .TT:
            if let assets = self.ttAssets, assets.count > 0 {
                self.updateTTCurrency(by: assets.first!)
            }
        case .Polygon:
            if let assets = self.polygonAssets, assets.count > 0 {
                self.updatePolygonCurrency(by: assets.first!)
            }
        case .OS:
            if let assets = self.osAssets, assets.count > 0 {
                self.updateOsCurrency(by: assets.first!)
            }
        default:
            self.redEnvelopeNode.updateBalance(by: .unowned)
            return
        }
    }
    
    
    func selectedNetwork(_ chain: TBWeb3ConfigEntry.Chain, forceUpdate: Bool = false) {
        let state = self.stateValue.with({$0})
        if case .unReady(_) = state {
            return
        }
        if !forceUpdate {
            if let currentChain = self.currentChain, chain == currentChain { return }
        }
        self.currentChain = chain
        self.updateState { _ in
            return .unReady(chainType: chain.getChainType())
        }
        switch chain.getChainType() {
        case .ETH:
            if let assets = self.ethAssets, assets.count > 0 {
                self.updateState { _ in
                    return .reday(readType: .success)
                }
            } else {
                self.fetchEthereumBalance()
            }
        case .TT:
            if let assets = self.ttAssets, assets.count > 0 {
                self.updateState { _ in
                    return .reday(readType: .success)
                }
            } else {
                self.fetchThunderCoreBalance()
            }
        case .Polygon:
            if let assets = self.polygonAssets, assets.count > 0 {
                self.updateState { _ in
                    return .reday(readType: .success)
                }
            } else {
                self.fetchPolygonBalance()
            }
        case .OS:
            if let assets = self.osAssets, assets.count > 0 {
                self.updateState { _ in
                    return .reday(readType: .success)
                }
            } else {
                self.fetchOasisBalance()
            }
        default:
            self.redEnvelopeNode.updateBalance(by: .unowned)
            return
        }
    }
    
    
    func getCurrentTokens() -> [TBTokenItem]? {
        guard let curChain = self.currentChain else { return nil }
        switch curChain.getChainType() {
        case .ETH:
            return self.ethAssets
        case .TT:
            return self.ttAssets
        case .Polygon:
            return self.polygonAssets
        case .OS:
            return self.osAssets
        default:
            return nil
        }
    }
    
    func selectedToken(token: TBTokenItem) {
        guard let curChain = self.currentChain else { return }
        self.redEnvelopeNode.cleanInput()
        switch curChain.getChainType() {
        case .ETH:
            if let eth = token as? AssetsItem {
                self.updateEthCurrency(by: eth)
                return
            }
        case .TT:
            if let tt = token as? TTOSAssetsItem {
                self.updateTTCurrency(by: tt)
                return
            }
        case .Polygon:
            if let polygon = token as? AssetsItem {
                self.updatePolygonCurrency(by: polygon)
                return
            }
        case .OS:
            if let oasis = token as? TTOSAssetsItem {
                self.updateOsCurrency(by: oasis)
                return
            }
        default:
            break
        }
        
    }
    
    
    func updateNextButtonStatus(useAble: Bool) {
        self.redEnvelopeNode.updateSendButtonStatus(useAble: useAble)
    }
    
    
    private var ethAssets: [AssetsItem]?
    private func fetchEthereumBalance() {
        let appid = TBAccount.shared.systemCheckData.zapper
        let _ = TBZapperNetworkBalance.getAppsBalances(appId: appid, type: .Eth, addresses: [self.fromAddress]).start(next: {[weak self] result in
            guard let strongSelf = self else { return }
            if case let .success(tokens) = result,
                let dic = tokens.first,
                let token = TBZapperToken.deserialize(from: dic),
                let assets = token.products?.first?.assets, assets.count > 0 {
                strongSelf.ethAssets = assets
                strongSelf.updateState { _ in
                    return .reday(readType: .success)
                }
            } else {
                strongSelf.updateState { _ in
                    return .reday(readType: .fault)
                }
            }
        })
    }
    
    private var curEthToken: AssetsItem?
    private func updateEthCurrency(by asset: AssetsItem) {
        self.curEthToken = asset
        self.redEnvelopeNode.currencyNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUSD)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.getTitle(), balanceUSD)
        self.redEnvelopeNode.updateBalance(by: .valid(value: value))
    }
    
    private func ethOrder() -> TBTransferAssetOrder? {
        guard let curToken = self.curEthToken, let c = self.rpCreate else { return nil }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.rpConfig.address
        order.network = curToken.network
        order.icon = curToken.getIconName()
        order.decimals = curToken.decimals
        order.symbol = curToken.symbol
        order.address = (curToken.address == "0x0000000000000000000000000000000000000000") ? nil : curToken.address
        order.balance = curToken.balance
        order.chainId = "1"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 1}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        order.amount = NSDecimalNumber(string: c.amount).adding(NSDecimalNumber(string: c.gas_amount)).description
        order.price = NSDecimalNumber(string: order.amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.price.decimalString())).decimalValue.description
        return order
    }
    
    private func ethParamType() -> TBWCParamType? {
        guard let chain = self.currentChain, let curToken = self.curEthToken else { return nil }
        let currencyType = NativeCurrencyType(decimals: curToken.decimals, symbol: curToken.symbol, icon: curToken.getIconName())
        let paramType = TBWCParamType(chainId: NSDecimalNumber(value: chain.id).toBase(16).description, chainName: chain.name, rpcUrls: [chain.rpc_url], nativeCurrency: currencyType)
        return paramType
    }
    
    
    private var ttAssets: [TTOSAssetsItem]?
    private func fetchThunderCoreBalance() {
        guard let config = self.chainConfig,
                let coinId = config.chainType.filter({$0.id == 108}).first?.currency.first?.coin_id
        else {
            self.updateState { _ in
                return .reday(readType: .fault)
            }
            return
        }
        let appid = TBAccount.shared.systemCheckData.tt_api_key
        let currency = config.chainType.filter({$0.id == 108}).first!.currency.first!
        let _ = combineLatest(TBTTNetworkBalance.getAppsBalances(appId: appid, address: self.fromAddress), TBRedEnvelopeInteractor.fetchCurrencyPrice(by: coinId)).start(next: {[weak self] balance, price in
            guard let strongSelf = self else { return }
            var assest = TTOSAssetsItem()
            assest.id = currency.id
            assest.coin_id = currency.coin_id
            assest.decimal = currency.decimal
            assest.symbol = currency.name
            assest.is_main_currency = currency.is_main_currency
            assest.icon = currency.icon
            assest.price = price.usd
            assest.network = "ThunderCore"
            let balanceNum = NSDecimalNumber(string: balance.decimalString()).dividing(by: NSDecimalNumber(decimal: pow(10, currency.decimal)))
            assest.balance = strongSelf.formatnumber(by: balanceNum, maxFractionDigits: 10)
            let balanceUSD = balanceNum.multiplying(by: NSDecimalNumber(string: price.usd))
            assest.balanceUSD = strongSelf.formatnumber(by: balanceUSD, maxFractionDigits: 3)
            strongSelf.ttAssets = [assest]
            strongSelf.updateState { _ in
                return .reday(readType: .success)
            }
        })
    }
    
    private var curTTToken: TTOSAssetsItem?
    private func updateTTCurrency(by asset: TTOSAssetsItem) {
        self.curTTToken = asset
        
        self.redEnvelopeNode.currencyNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUSD)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.getTitle(), balanceUSD)
        self.redEnvelopeNode.updateBalance(by: .valid(value: value))
    }
    
    private func ttOrder() -> TBTransferAssetOrder? {
        guard let curToken = self.curTTToken, let c = self.rpCreate else { return nil }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.rpConfig.address
        order.network = curToken.network
        order.icon = curToken.getIconName()
        order.decimals = curToken.decimal
        order.symbol = curToken.symbol
        order.address = nil
        order.balance = curToken.balance
        let amount = (NSDecimalNumber(string: c.amount).adding(NSDecimalNumber(string: c.gas_amount))).description
        order.amount = amount
        order.chainId = "108"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 108}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        order.price = NSDecimalNumber(string: amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.price.decimalString())).decimalValue.description
        return order
    }
    
    private func ttParamType() -> TBWCParamType? {
        guard let chain = self.currentChain, let curToken = self.curTTToken else { return nil }
        let currencyType = NativeCurrencyType(decimals: curToken.decimal, symbol: curToken.symbol, icon: curToken.getIconName())
        let paramType = TBWCParamType(chainId: NSDecimalNumber(value: chain.id).toBase(16).description, chainName: chain.name, rpcUrls: [chain.rpc_url], nativeCurrency: currencyType)
        return paramType
    }
    
    
    private var polygonAssets: [AssetsItem]?
    private func fetchPolygonBalance() {
        let appid = TBAccount.shared.systemCheckData.zapper
        let _ = TBZapperNetworkBalance.getAppsBalances(appId: appid, type: .Polygon, addresses: [self.fromAddress]).start(next: {[weak self] result in
            guard let strongSelf = self else { return }
            if case let .success(tokens) = result,
                let dic = tokens.first,
                let token = TBZapperToken.deserialize(from: dic),
                let assets = token.products?.first?.assets, assets.count > 0 {
                strongSelf.polygonAssets = assets
                strongSelf.updateState { _ in
                    return .reday(readType: .success)
                }
            } else {
                strongSelf.updateState { _ in
                    return .reday(readType: .fault)
                }
            }
        })
    }
    
    private var curPolygonToken: AssetsItem?
    private func updatePolygonCurrency(by asset: AssetsItem) {
        self.curPolygonToken = asset
        self.redEnvelopeNode.currencyNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUSD)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.getTitle(), balanceUSD)
        self.redEnvelopeNode.updateBalance(by: .valid(value: value))
    }
    
    private func polygonOrder() -> TBTransferAssetOrder? {
        guard let curToken = self.curPolygonToken, let c = self.rpCreate else { return nil }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.rpConfig.address
        order.network = curToken.network
        order.icon = curToken.getIconName()
        order.decimals = curToken.decimals
        order.symbol = curToken.symbol
        order.address = (curToken.address == "0x0000000000000000000000000000000000000000") ? nil : curToken.address
        order.balance = curToken.balance
        let amount = NSDecimalNumber(string: c.amount).adding(NSDecimalNumber(string: c.gas_amount)).description
        order.amount = amount
        order.chainId = "137"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 137}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        order.price = NSDecimalNumber(string: amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.price.decimalString())).decimalValue.description
        return order
    }
    
    private func polygonParamType() -> TBWCParamType? {
        guard let chain = self.currentChain, let curToken = self.curPolygonToken else { return nil }
        let currencyType = NativeCurrencyType(decimals: curToken.decimals, symbol: curToken.symbol, icon: curToken.getIconName())
        let paramType = TBWCParamType(chainId: NSDecimalNumber(value: chain.id).toBase(16).description, chainName: chain.name, rpcUrls: [chain.rpc_url], nativeCurrency: currencyType)
        return paramType
    }
    
    
    private var osAssets: [TTOSAssetsItem]?
    private func fetchOasisBalance() {
        guard let config = self.chainConfig,
                let coinId = config.chainType.filter({$0.id == 42262}).first?.currency.first?.coin_id
        else {
            self.updateState { _ in
                return .reday(readType: .fault)
            }
            return
        }
        let currency = config.chainType.filter({$0.id == 42262}).first!.currency.first!
        let _ = combineLatest(TBOasisNetworkBalance.getAppsBalances(address: self.fromAddress), TBRedEnvelopeInteractor.fetchCurrencyPrice(by: coinId)).start(next: {[weak self] balance, price in
            guard let strongSelf = self else { return }
            var assest = TTOSAssetsItem()
            assest.id = currency.id
            assest.coin_id = currency.coin_id
            assest.decimal = currency.decimal
            assest.symbol = currency.name
            assest.is_main_currency = currency.is_main_currency
            assest.icon = currency.icon
            assest.price = price.usd
            assest.network = "Oasis"
            let balanceNum = NSDecimalNumber(string: balance.decimalString()).dividing(by: NSDecimalNumber(decimal: pow(10, currency.decimal)))
            assest.balance = strongSelf.formatnumber(by: balanceNum, maxFractionDigits: 10)
            let balanceUSD = balanceNum.multiplying(by: NSDecimalNumber(string: price.usd))
            assest.balanceUSD = strongSelf.formatnumber(by: balanceUSD, maxFractionDigits: 3)
            strongSelf.osAssets = [assest]
            strongSelf.updateState { _ in
                return .reday(readType: .success)
            }
        })
    }
        
    private var curOsToken: TTOSAssetsItem?
    private func updateOsCurrency(by asset: TTOSAssetsItem) {
        self.curOsToken = asset
        self.redEnvelopeNode.currencyNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUSD)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.getTitle(), balanceUSD)
        self.redEnvelopeNode.updateBalance(by: .valid(value: value))
    }
    
    private func oasisOrder() -> TBTransferAssetOrder? {
        guard let curToken = self.curOsToken, let c = self.rpCreate else { return nil }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.rpConfig.address
        order.network = curToken.network
        order.icon = curToken.getIconName()
        order.decimals = curToken.decimal
        order.symbol = curToken.symbol
        order.address = nil
        order.balance = curToken.balance
        let amount = NSDecimalNumber(string: c.amount).adding(NSDecimalNumber(string: c.gas_amount)).description
        order.amount = amount
        order.chainId = "42262"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 42262}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        order.price = NSDecimalNumber(string: amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.price.decimalString())).decimalValue.description
        return order
    }
    
    private func oasisParamType() -> TBWCParamType? {
        guard let chain = self.currentChain, let curToken = self.curOsToken else { return nil }
        let currencyType = NativeCurrencyType(decimals: curToken.decimal, symbol: curToken.symbol, icon: curToken.getIconName())
        let paramType = TBWCParamType(chainId: NSDecimalNumber(value: chain.id).toBase(16).description, chainName: chain.name, rpcUrls: [chain.rpc_url], nativeCurrency: currencyType)
        return paramType
    }
    
    
    private func currentOrder(by chainType: TBChainType) -> TBTransferAssetOrder? {
        switch chainType {
        case .ETH:
            return self.ethOrder()
        case .OS:
            return self.oasisOrder()
        case .Polygon:
            return self.polygonOrder()
        case .TT:
            return self.ttOrder()
        case .unkonw:
            return nil
        }
    }
    
    private func currentParamType(by chainType: TBChainType) -> TBWCParamType? {
        switch chainType {
        case .ETH:
            return self.ethParamType()
        case .OS:
            return self.oasisParamType()
        case .Polygon:
            return self.polygonParamType()
        case .TT:
            return self.ttParamType()
        case .unkonw:
            return nil
        }
    }
    
    private func resetPage(by type: ResetType) {
        switch type {
        case .all:
            self.osAssets = nil
            self.ttAssets = nil
            self.ethAssets = nil
            self.polygonAssets = nil
            self.redEnvelopeNode.navNode.updateWallet(by: UnClearNetworkItem())
            self.redEnvelopeNode.updateNetwork(nil)
            self.redEnvelopeNode.currencyNode.updateCurrency(UnClearNetworkItem())
        case .network:
            self.redEnvelopeNode.updateNetwork(nil)
            self.redEnvelopeNode.currencyNode.updateCurrency(UnClearNetworkItem())
        case .currency:
            self.redEnvelopeNode.currencyNode.updateCurrency(UnClearNetworkItem())
        }
        self.redEnvelopeNode.cleanInput()
        self.redEnvelopeNode.updateSumTokens("")
        self.redEnvelopeNode.updateFromBalance(by: .none)
        self.redEnvelopeNode.updateBalance(by: .unowned)
        self.updateNextButtonStatus(useAble: false)
    }
        
    func currencyConfig(chainName: String, currencyName: String) -> RedEnvelopeConfig.Currency? {
        return self.rpConfig.config.filter({$0.name == chainName}).first?.currency.filter({$0.name == currencyName}).first
    }
    
    func formatnumber(by number: NSDecimalNumber, maxFractionDigits: Int) -> String {
        let format = NumberFormatter()
        format.maximumFractionDigits = maxFractionDigits
        if let a = format.string(for: number) {
            return a
        } else {
            return ""
        }
    }
    
    func jumpToVerify(result: CreateResult) {
        ProgressHUD.dismiss()
        
        self.updateState { _ in
            return .inital
        }
        self.selectedWallet(self.currentWallet)
        
        guard let rpc = self.rpCreate else { return }
        let tokensNum = NSDecimalNumber(string: rpc.amount).adding(NSDecimalNumber(string: rpc.gas_amount))
        let asset = VerifyAsset(tokensCount: tokensNum.description, symbol: rpc.currency_name, price: NSDecimalNumber(string: rpc.currency_price).multiplying(by: tokensNum).description)
        let vc = TBRedpVerifyController(context: self.context, peerId: self.toPeerId, asset: asset, result: result)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension TBWeb3ConfigEntry.Chain: TBSegmentItem {
    public func selectedIcon() -> String {
        return "List Menu/btn_radio_selected"
    }
    
    public func unSelectedIcon() -> String {
        return "List Menu/btn_radio_disselected"
    }
    
    public func iconImage() -> String? {
        return self.icon
    }
    
    public func title() -> String {
        return self.name
    }
}

extension TTOSAssetsItem: NetworkItem {
    public func getIconName() -> String {
        return self.icon
    }
    
    public func getTitle() -> String {
        return self.symbol
    }
}

extension AssetsItem: NetworkItem {
    public func getIconName() -> String {
        return self.displayProps?.images?.first ?? ""
    }
    
    public func getTitle() -> String {
        return self.displayProps?.label ?? ""
    }
}

extension TBWeb3ConfigEntry.Chain.Currency: NetworkItem {
    
    public func getIconName() -> String {
        return self.icon
    }
    
    public func getTitle() -> String {
        return self.name
    }
}
