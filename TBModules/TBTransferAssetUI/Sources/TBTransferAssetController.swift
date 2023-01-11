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

extension TBWeb3ConfigEntry.Chain: NetworkItem {
    public func getIconName() -> String {
        return self.icon
    }
    
    public func getTitle() -> String {
        return self.name
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

extension TBWeb3ConfigEntry.Chain.Currency: NetworkItem {
    
    public func getIconName() -> String {
        return self.icon
    }
    
    public func getTitle() -> String {
        return self.name
    }
}

extension CurrencyBalance: NetworkItem {
    public func getIconName() -> String {
        return self.icon
    }
    
    public func getTitle() -> String {
        return self.name
    }
}

extension CurrencyBalance: TBTokenItem {
    public func tokenIcon() -> String {
        return self.icon
    }
    
    public func tokenName() -> String {
        return self.name
    }
    
    public func tokenMarketPrice() -> String {
        return self.unitPrice
    }
    
    public func tokenCount() -> String {
        return self.balance
    }
    
    public func tokenTotal() -> String {
        return self.balanceUsd
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

extension TTOSAssetsItem: TBTokenItem {
    public func tokenIcon() -> String {
        return self.icon
    }
    
    public func tokenName() -> String {
        return self.symbol
    }
    
    public func tokenMarketPrice() -> String {
        return self.price
    }
    
    public func tokenCount() -> String {
        return self.balance
    }
    
    public func tokenTotal() -> String {
        return self.balanceUSD
    }
}

public class TBTransferAssetController: ViewController {
    
    public let context: AccountContext
    private let animationCache: AnimationCache
    private let animationRenderer: MultiAnimationRenderer
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private var transferAssetNode: TBTransferAssetControllerNode {
        return super.displayNode as! TBTransferAssetControllerNode
    }
    
    private let from: TBWallet
    private var fromAddress:String {
        get {
            return self.from.walletAddress()
        }
    }
    private let toPeerId: PeerId?
    private let toAddress: String
    private var chainConfig: TBWeb3ConfigEntry?
    
    public var sendRedPackEvent: ((String) -> ())?
    
    public init(context: AccountContext, from: TBWallet, toPeerId: PeerId? = nil, toAddress: String, chain: TBWeb3ConfigEntry.Chain? = nil, animationCache: AnimationCache? = nil, animationRenderer: MultiAnimationRenderer? = nil, hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.from = from
        self.toPeerId = toPeerId
        self.toAddress = toAddress
        self.animationCache = animationCache != nil ? animationCache! : context.animationCache
        self.animationRenderer = animationRenderer != nil ? animationRenderer! : context.animationRenderer
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.displayNavigationBar = false
        let _ = (TBWeb3Config.shared.configSignal
                 |> take(1)
                 |> deliverOnMainQueue).start(next: {[weak self] config  in
            if let strongSelf = self, let config = config {
                strongSelf.chainConfig = config
                if let c = chain {
                    strongSelf.selectedNetwork(c)
                } else {
                    if let c = config.chainType.first {
                        strongSelf.selectedNetwork(c)
                    }
                }
            }
        })
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }

     override public func loadDisplayNode() {
         self.displayNode = TBTransferAssetControllerNode(context: self.context, presentationData: self.presentationData)
         self.displayNodeDidLoad()
     }
    
    override public func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.transferAssetNode.containNode.closeEvent = { [weak self] in
            self?.dismiss(animated: true)
        }
        self.transferAssetNode.containNode.nextEvent = { [weak self] in
            guard let strongSelf = self, let curChain = strongSelf.currentChain else { return }
            strongSelf.transferAssetNode.containNode.endEdit()
            switch curChain.getChainType() {
            case .unkonw:
                return
            case .ETH:
                strongSelf.ethNextStep()
            case .Polygon:
                strongSelf.polygonNextStep()
            case .TT:
                strongSelf.ttNextStep()
            case .OS:
                strongSelf.oasisnNextStep()
            }
        }
        self.transferAssetNode.containNode.networkClickEvent = { [weak self] in
            self?.transferAssetNode.containNode.endEdit()
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
        self.transferAssetNode.containNode.currencyClickEvent = { [weak self] in
            self?.transferAssetNode.containNode.endEdit()
            guard let strongSelf = self else { return }
            let items: [TBTokenItem] = strongSelf.getCurrentTokens() ?? [TbToken]()
            let popVc = TBPopController(context: strongSelf.context)
            let node = TBTransferAssetTokensNode(context: strongSelf.context, isEmpty: items.count == 0)
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
        let _ = self.transferAssetNode.containNode.bitInputPromise.get().start(next: {[weak self] text in
            self?.updateCount(by: text)
        })
        if let _ = self.toPeerId {
            let _ = (self.context.account.viewTracker.peerView(self.toPeerId!, updateData: true)
                     |> deliverOnMainQueue).start { [weak self] peerView in
                let user = peerView.peers[peerView.peerId] as? TelegramUser
                self?.updateNameBy(user)
                self?.updateAvatarBy(user)
            }
        } else {
            self.transferAssetNode.containNode.updateTransferName(name: self.toAddress.simpleAddress())
            self.transferAssetNode.containNode.updateTransferAvatar(avatar: UIImage(named: "Wallet/line_wallet"))
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        if let height = layout.inputHeight, height > 0 { return }
        self.transferAssetNode.update(layout: layout, transition: transition)
    }
    
    
    private func updateNameBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let name: String = {
            if let name = user.username {
                return name
            }
            var text = ""
            if let firstName = user.firstName {
                text.append("\(firstName) ")
            }
            if let lastName = user.lastName {
                text.append("\(lastName)")
            }
            return text
        }()
        self.transferAssetNode.containNode.updateTransferName(name: name.count > 0 ? name : "***" )
    }
    
    private func updateAvatarBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 40,height: 40)) {
            let _ = signal.start {[weak self] a in
                self?.transferAssetNode.containNode.updateTransferAvatar(avatar: a?.0)
            }
        }else {
            self.transferAssetNode.containNode.updateTransferAvatar(avatar: UIImage(named: "Wallet/line_wallet"))
        }
    }
    
    
    private var currentChain: TBWeb3ConfigEntry.Chain?
    func selectedNetwork(_ chain: TBWeb3ConfigEntry.Chain) {
        if let currentChain = self.currentChain, chain == currentChain { return }
        self.currentChain = chain
        self.transferAssetNode.containNode.updateNetwork(chain)
        self.transferAssetNode.containNode.updateFromBalance(by: .none)
        self.transferAssetNode.containNode.updateBalance(by: .unkonw)
        switch chain.getChainType() {
        case .ETH:
            if let assets = self.ethAssets, assets.count > 0 {
                self.updateEthCurrency(by: assets.first!)
            } else {
                self.fetchEthereumBalance()
            }
        case .TT:
            if let assets = self.ttAssets, assets.count > 0 {
                self.updateTTCurrency(by: assets.first!)
            } else {
                self.fetchThunderCoreBalance()
            }
        case .Polygon:
            if let assets = self.polygonAssets, assets.count > 0 {
                self.updatePolygonCurrency(by: assets.first!)
            } else {
                self.fetchPolygonBalance()
            }
        case .OS:
            if let assets = self.osAssets, assets.count > 0 {
                self.updateOsCurrency(by: assets.first!)
            } else {
                self.fetchOasisBalance()
            }
        default:
            self.transferAssetNode.containNode.updateBalance(by: .unkonw)
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
        switch curChain.getChainType() {
        case .ETH:
            if let eth = token as? CurrencyBalance {
                self.updateEthCurrency(by: eth)
                return
            }
        case .TT:
            if let tt = token as? TTOSAssetsItem {
                self.updateTTCurrency(by: tt)
                return
            }
        case .Polygon:
            if let polygon = token as? CurrencyBalance {
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
    
    
    func updateCount(by text: String) {
        if let chain = self.currentChain {
            switch chain.getChainType() {
            case .unkonw:
                self.transferAssetNode.containNode.updateFromBalance(by: .none)
                self.updateNextButtonStatus(useAble: false)
            case .ETH:
                if let curretToken = self.curEthToken {
                    let count = curretToken.tokenCount().decimalString()
                    let totalNumber = NSDecimalNumber(string: count)
                    let inputCount = text.decimalString()
                    let inputNumber = NSDecimalNumber(string: inputCount)
                    if totalNumber.doubleValue <= 0 || totalNumber.compare(inputNumber) == .orderedAscending {
                        self.transferAssetNode.containNode.updateFromBalance(by: .lackOfBalance)
                        self.updateNextButtonStatus(useAble: false)
                    } else if inputNumber.compare(NSDecimalNumber(string: "0")) == .orderedSame {
                        self.transferAssetNode.containNode.updateFromBalance(by: .none)
                        self.updateNextButtonStatus(useAble: false)
                    }  else {
                        let price = curretToken.tokenMarketPrice().decimalString()
                        let totalP = NSDecimalNumber(string: price).multiplying(by: inputNumber).decimalValue.description
                        self.transferAssetNode.containNode.updateFromBalance(by: .input(value: "$\(totalP)"))
                        self.updateNextButtonStatus(useAble: true)
                    }
                }
            case .TT:
                if let curretToken = self.curTTToken {
                    let count = curretToken.tokenCount().decimalString()
                    let totalNumber = NSDecimalNumber(string: count)
                    let inputCount = text.decimalString()
                    let inputNumber = NSDecimalNumber(string: inputCount)
                    if totalNumber.doubleValue <= 0 || totalNumber.compare(inputNumber) == .orderedAscending {
                        self.transferAssetNode.containNode.updateFromBalance(by: .lackOfBalance)
                        self.updateNextButtonStatus(useAble: false)
                    } else if inputNumber.compare(NSDecimalNumber(string: "0")) == .orderedSame {
                        self.transferAssetNode.containNode.updateFromBalance(by: .none)
                        self.updateNextButtonStatus(useAble: false)
                    }  else {
                        let price = curretToken.tokenMarketPrice().decimalString()
                        let totalP = NSDecimalNumber(string: price).multiplying(by: inputNumber).decimalValue.description
                        self.transferAssetNode.containNode.updateFromBalance(by: .input(value: "$\(totalP)"))
                        self.updateNextButtonStatus(useAble: true)
                    }
                }
            case .OS:
                if let curretToken = self.curOsToken {
                    let count = curretToken.tokenCount().decimalString()
                    let totalNumber = NSDecimalNumber(string: count)
                    let inputCount = text.decimalString()
                    let inputNumber = NSDecimalNumber(string: inputCount)
                    if totalNumber.doubleValue <= 0 || totalNumber.compare(inputNumber) == .orderedAscending {
                        self.transferAssetNode.containNode.updateFromBalance(by: .lackOfBalance)
                        self.updateNextButtonStatus(useAble: false)
                    } else if inputNumber.compare(NSDecimalNumber(string: "0")) == .orderedSame {
                        self.transferAssetNode.containNode.updateFromBalance(by: .none)
                        self.updateNextButtonStatus(useAble: false)
                    }  else {
                        let price = curretToken.tokenMarketPrice().decimalString()
                        let totalP = NSDecimalNumber(string: price).multiplying(by: inputNumber).decimalValue.description
                        self.transferAssetNode.containNode.updateFromBalance(by: .input(value: "$\(totalP)"))
                        self.updateNextButtonStatus(useAble: true)
                    }
                }
            case .Polygon:
                if let curretToken = self.curPolygonToken {
                    let count = curretToken.tokenCount().decimalString()
                    let totalNumber = NSDecimalNumber(string: count)
                    let inputCount = text.decimalString()
                    let inputNumber = NSDecimalNumber(string: inputCount)
                    if totalNumber.doubleValue <= 0 || totalNumber.compare(inputNumber) == .orderedAscending {
                        self.transferAssetNode.containNode.updateFromBalance(by: .lackOfBalance)
                        self.updateNextButtonStatus(useAble: false)
                    } else if inputNumber.compare(NSDecimalNumber(string: "0")) == .orderedSame {
                        self.transferAssetNode.containNode.updateFromBalance(by: .none)
                        self.updateNextButtonStatus(useAble: false)
                    }  else {
                        let price = curretToken.tokenMarketPrice().decimalString()
                        let totalP = NSDecimalNumber(string: price).multiplying(by: inputNumber).decimalValue.description
                        self.transferAssetNode.containNode.updateFromBalance(by: .input(value: "$\(totalP)"))
                        self.updateNextButtonStatus(useAble: true)
                    }
                }
            }
        }
    }
    
    
    func updateNextButtonStatus(useAble: Bool) {
        self.transferAssetNode.containNode.updateNextButtonStatus(useAble: useAble)
    }
    
    
    private var ethAssets: [CurrencyBalance]?
    private func fetchEthereumBalance() {
        let appid = TBAccount.shared.systemCheckData.zapper
        
        let _ = (Web3NetworkBalanceApi.fetchEthOrPolygonBalance(type: .Eth, address: self.fromAddress)
                 |> deliverOnMainQueue).start(next: {[weak self] a in
            guard let strongSelf = self else { return }
            if a.currencyBalances.count > 0 {
                strongSelf.ethAssets = a.currencyBalances
                strongSelf.updateEthCurrency(by: a.currencyBalances.first!)
            } else {
                strongSelf.noBalanceForCurrencyInConfigChain()
            }
        })
        














    }
    
    private var curEthToken: CurrencyBalance?
    private func updateEthCurrency(by asset: CurrencyBalance) {
        self.curEthToken = asset
        self.transferAssetNode.containNode.cleanInput()
        self.transferAssetNode.containNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUsd)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.name, balanceUSD)
        self.transferAssetNode.containNode.updateBalance(by: .valid(value: value))
    }
    
    private func ethNextStep() {
        guard let curToken = self.curEthToken else { return }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.toAddress
        order.network = curToken.network
        order.icon = curToken.icon
        order.decimals = curToken.decimals
        order.symbol = curToken.symbol
        order.address = (curToken.address == "0x0000000000000000000000000000000000000000") ? nil : curToken.address
        order.balance = curToken.balance
        order.chainId = "1"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 1}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        let amount = self.transferAssetNode.containNode.getInputText()
        order.amount = amount
        order.price = NSDecimalNumber(string: amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.unitPrice.decimalString())).decimalValue.description
        self.nextStep(by: order)
    }
    
    
    private var ttAssets: [TTOSAssetsItem]?
    private func fetchThunderCoreBalance() {
        guard let config = self.chainConfig, let coinId = config.chainType.filter({$0.id == 108}).first?.currency.first?.coin_id else { return }
        let appid = TBAccount.shared.systemCheckData.tt_api_key
        let currency = config.chainType.filter({$0.id == 108}).first!.currency.first!
        let _ = combineLatest(TBTTNetworkBalance.getAppsBalances(appId: appid, address: self.fromAddress), TBTransferAssetInteractor.fetchCurrencyPrice(by: coinId)).start(next: {[weak self] balance, price in
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
            strongSelf.updateTTCurrency(by: assest)
        })
    }
    
    private var curTTToken: TTOSAssetsItem?
    private func updateTTCurrency(by asset: TTOSAssetsItem) {
        self.curTTToken = asset
        self.transferAssetNode.containNode.cleanInput()
        self.transferAssetNode.containNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUSD)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.getTitle(), balanceUSD)
        self.transferAssetNode.containNode.updateBalance(by: .valid(value: value))
    }
    
    private func ttNextStep() {
        guard let curToken = self.curTTToken else { return }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.toAddress
        order.network = curToken.network
        order.icon = curToken.getIconName()
        order.decimals = curToken.decimal
        order.symbol = curToken.symbol
        order.address = nil
        order.balance = curToken.balance
        let amount = self.transferAssetNode.containNode.getInputText()
        order.amount = amount
        order.chainId = "108"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 108}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        order.price = NSDecimalNumber(string: amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.price.decimalString())).decimalValue.description
        self.nextStep(by: order)
    }
    
    
    private var polygonAssets: [CurrencyBalance]?
    private func fetchPolygonBalance() {
        let _ = (Web3NetworkBalanceApi.fetchEthOrPolygonBalance(type: .Polygon, address: self.fromAddress)
                 |> deliverOnMainQueue).start(next: {[weak self] a in
            guard let strongSelf = self else { return }
            if a.currencyBalances.count > 0 {
                strongSelf.polygonAssets = a.currencyBalances
                strongSelf.updatePolygonCurrency(by: a.currencyBalances.first!)
            } else {
                strongSelf.noBalanceForCurrencyInConfigChain()
            }
        })
    }
    
    private var curPolygonToken: CurrencyBalance?
    private func updatePolygonCurrency(by asset: CurrencyBalance) {
        self.curPolygonToken = asset
        self.transferAssetNode.containNode.cleanInput()
        self.transferAssetNode.containNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUsd)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.name, balanceUSD)
        self.transferAssetNode.containNode.updateBalance(by: .valid(value: value))
    }
    
    private func polygonNextStep() {
        guard let curToken = self.curPolygonToken else { return }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.toAddress
        order.network = curToken.network
        order.icon = curToken.icon
        order.decimals = curToken.decimals
        order.symbol = curToken.symbol
        order.address = (curToken.address == "0x0000000000000000000000000000000000000000") ? nil : curToken.address
        order.balance = curToken.balance
        let amount = self.transferAssetNode.containNode.getInputText()
        order.amount = amount
        order.chainId = "137"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 137}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        order.price = NSDecimalNumber(string: amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.unitPrice.decimalString())).decimalValue.description
        self.nextStep(by: order)
    }
    
    
    private var osAssets: [TTOSAssetsItem]?
    private func fetchOasisBalance() {
        guard let config = self.chainConfig, let coinId = config.chainType.filter({$0.id == 42262}).first?.currency.first?.coin_id else { return }
        let currency = config.chainType.filter({$0.id == 42262}).first!.currency.first!
        let _ = combineLatest(TBOasisNetworkBalance.getAppsBalances(address: self.fromAddress), TBTransferAssetInteractor.fetchCurrencyPrice(by: coinId)).start(next: {[weak self] balance, price in
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
            strongSelf.updateOsCurrency(by: assest)
        })
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
    
    private var curOsToken: TTOSAssetsItem?
    private func updateOsCurrency(by asset: TTOSAssetsItem) {
        self.curOsToken = asset
        self.transferAssetNode.containNode.cleanInput()
        self.transferAssetNode.containNode.updateCurrency(asset)
        let balanceNum = NSDecimalNumber(string: asset.balance)
        let balance = self.formatnumber(by: balanceNum, maxFractionDigits: 10)
        let usdNum = NSDecimalNumber(string: asset.balanceUSD)
        let balanceUSD = self.formatnumber(by: usdNum, maxFractionDigits: 3)
        let value = String(format: "%@ %@ $%@", balance, asset.getTitle(), balanceUSD)
        self.transferAssetNode.containNode.updateBalance(by: .valid(value: value))
    }
    
    private func oasisnNextStep() {
        guard let curToken = self.curOsToken else { return }
        var order = TBTransferAssetOrder()
        order.fromAddress = self.fromAddress
        order.toAddress = self.toAddress
        order.network = curToken.network
        order.icon = curToken.getIconName()
        order.decimals = curToken.decimal
        order.symbol = curToken.symbol
        order.address = nil
        order.balance = curToken.balance
        let amount = self.transferAssetNode.containNode.getInputText()
        order.amount = amount
        order.chainId = "42262"
        let currencyId = self.chainConfig?.chainType.filter({$0.id == 42262}).first?.currency.filter({$0.name == curToken.symbol}).first?.id ?? -99
        order.currencyId = "\(currencyId)"
        order.price = NSDecimalNumber(string: amount.decimalString()).multiplying(by: NSDecimalNumber(string: curToken.price.decimalString())).decimalValue.description
        self.nextStep(by: order)
    }
    
    private func noBalanceForCurrencyInConfigChain() {
        guard let chain = self.currentChain else { return }
        if let currency = chain.currency.filter({ $0.is_main_currency}).first {
            self.transferAssetNode.containNode.updateCurrency(currency)
        }
        self.transferAssetNode.containNode.updateFromBalance(by: .lackOfBalance)
    }
    
    
    private func nextStep(by order: TBTransferAssetOrder) {
        let popVc = TBPopController(context: self.context, canCloseByTouches: false)
        let node = TBTransferAssetOrderNode(context: self.context, from: self.from, toPeerId: self.toPeerId, order: order)
        node.cornerRadius = 10
        node.backgroundColor = UIColor.white
        node.closeEvent = {[weak popVc, weak self] in
            popVc?.dismiss(animated: true)
            self?.dismiss(animated: true)
        }
        node.previousStepEvent = {[weak popVc] in
            popVc?.dismiss(animated: true)
        }
        
        node.transferAssetSuccessHandle = { [weak popVc, weak self] str in
            self?.sendRedPackEvent?(str)
            popVc?.dismiss(animated: true)
            self?.dismiss(animated: true)
        }
        
        let screenSize = UIScreen.main.bounds.size
        popVc.setContentNode(node, frame: CGRect(origin: CGPoint(x: 0, y: screenSize.height * 0.1), size: CGSize(width: screenSize.width, height: 0.9 * screenSize.height + 10)))
        popVc.pop(from: self, transition: .immediate)
        DispatchQueue.main.async {
            node.update(size: CGSize(width: screenSize.width, height: 0.9 * screenSize.height + 10))
        }
    }
}

class TBTransferAssetControllerNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    let containNode: TBTransferAssetContainNode
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.containNode = TBTransferAssetContainNode(context: context, presentationData: presentationData)
        super.init()
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
    }
    
    override func didLoad() {
        super.didLoad()
        self.containNode.cornerRadius = 10
        self.addSubnode(self.containNode)
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let size = layout.size
        transition.updateFrame(node: self.containNode, frame: CGRect(x: 0, y: 0.1 * size.height, width: size.width, height: 0.9 * size.height + 10))
        self.containNode.update(size: CGSize(width: size.width, height: 0.9 * size.height + 10), transition: transition)
    }
}

class TBTransferAssetContainNode: ASDisplayNode {
    
    enum FromBalanceType {
        case none
        case input(value: String)
        case lackOfBalance
    }
    
    enum Balance {
        case unkonw
        case invalid(chainName: String)
        case valid(value: String)
    }
    
    class InvalidNetworkAlertNode: ASDisplayNode {
        
        private let presentationData: PresentationData
        private let icon: ASImageNode
        private let containt: ASTextNode
        
        init(presentationData: PresentationData) {
            self.presentationData = presentationData
            self.icon = ASImageNode()
            self.containt = ASTextNode()
            super.init()
        }
        
        override func didLoad() {
            super.didLoad()
            self.icon.image = UIImage(named: "TBWallet/TransferAsset/alert_red_icon")
            self.addSubnode(self.icon)
            self.containt.maximumNumberOfLines = 4
            self.addSubnode(self.containt)
        }
        
        func updateAlert(_ alert: String) -> CGSize {
            self.containt.attributedText = NSAttributedString(string: alert, font: Font.regular(14), textColor: UIColor(hexString: "#FFEB5757")!)
            let size = self.containt.updateLayout(CGSize(width: UIScreen.main.bounds.width - 110, height: .greatestFiniteMagnitude))
            return CGSize(width: size.width + 24, height: max(20, size.height) + 2)
        }
        
        func updateFrame(by size: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
            transition.updateFrame(node: self.icon, frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            transition.updateFrame(node: self.containt, frame: CGRect(x: 24, y: 2, width: size.width - 24, height: size.height))
        }
    }

    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let networkTitleNode: NetworkNode
    private let closeButtonNode: ASButtonNode
    private let avatarNode: ASImageNode
    private let nameNode: ASTextNode
    private let bitTitleNode: NetworkNode
    
    private let sumMoneyNode: ASTextNode
    private let lackOfBalanceAlertNode: ASTextNode
    private let transferAssetNode: UITextField
    private let lineNode: ASDisplayNode
    private let balanceNode: ASTextNode
    private let invalidNetworkAlertNode: InvalidNetworkAlertNode
    
    private let nextButtonNode: ASButtonNode
    private let nextButtonLayer: CAGradientLayer
    
    let bitInputPromise: ValuePromise<String>
    
    var closeEvent: (() -> Void)?
    var nextEvent: (() -> Void)?
    var networkClickEvent: (() -> Void)?
    var currencyClickEvent: (() -> Void)?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.networkTitleNode = NetworkNode(context: context, presentationData: presentationData, config: NetworkNodeConfig(margin: 19))
        self.closeButtonNode = ASButtonNode()
        
        self.avatarNode = ASImageNode()
        self.nameNode = ASTextNode()
        self.bitTitleNode = NetworkNode(context: context, presentationData: presentationData, config: NetworkNodeConfig(titleFont: Font.medium(14), margin: 18))
        
        self.sumMoneyNode = ASTextNode()
        self.lackOfBalanceAlertNode = ASTextNode()
        self.transferAssetNode = UITextField()
        self.lineNode = ASDisplayNode()
        self.balanceNode = ASTextNode()
        self.invalidNetworkAlertNode = InvalidNetworkAlertNode(presentationData: presentationData)
        
        self.nextButtonNode = ASButtonNode()
        self.nextButtonLayer = CAGradientLayer()
        
        self.bitInputPromise = ValuePromise<String>(ignoreRepeated: true)
        super.init()
        self.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(noti:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHidden(noti:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.networkTitleNode.titleClickEvent = { [weak self] in
            self?.networkClickEvent?()
        }
        self.addSubnode(self.networkTitleNode)
        self.closeButtonNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.closeButtonNode.addTarget(self, action: #selector(closeButtonClickEvent(sender:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.closeButtonNode)
        
        self.avatarNode.image = UIImage(named: "Wallet/line_wallet")
        self.avatarNode.backgroundColor = UIColor(hexString: "#FF02ABFF")!
        self.avatarNode.cornerRadius = 32
        self.addSubnode(self.avatarNode)
        self.addSubnode(self.nameNode)
        self.bitTitleNode.cornerRadius = 8
        self.bitTitleNode.borderWidth = 1
        self.bitTitleNode.borderColor = UIColor(hexString: "#FFDCDDE0")!.cgColor
        self.bitTitleNode.titleClickEvent = { [weak self] in
            self?.currencyClickEvent?()
        }
        self.addSubnode(self.bitTitleNode)
        
        self.addSubnode(self.sumMoneyNode)
        self.addSubnode(self.lackOfBalanceAlertNode)
        self.transferAssetNode.placeholder = "0.00"
        self.transferAssetNode.keyboardType = .decimalPad
        self.transferAssetNode.textColor = UIColor(hexString: "#FF56565C")
        self.transferAssetNode.font = Font.medium(40)
        self.transferAssetNode.textAlignment = .center
        self.transferAssetNode.delegate = self
        self.view.addSubview(self.transferAssetNode)
        self.lineNode.backgroundColor = UIColor(hexString: "#FFDCDDE0")
        self.addSubnode(self.lineNode)
        self.addSubnode(self.balanceNode)
        self.addSubnode(self.invalidNetworkAlertNode)
        
        self.nextButtonNode.cornerRadius = 24
        self.nextButtonNode.setTitle("Next", with: Font.medium(15), with: UIColor.white, for: .normal)
        self.nextButtonNode.addTarget(self, action: #selector(nextButtonClickEvent(sender:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.nextButtonNode)
        self.nextButtonLayer.cornerRadius = 24
        self.nextButtonLayer.startPoint = CGPoint(x: 0, y: 0)
        self.nextButtonLayer.endPoint = CGPoint(x: 1, y: 0)
        self.nextButtonLayer.colors = [UIColor(hexString: "#FF01B4FF")!.cgColor, UIColor(hexString: "#FF8836DF")!.cgColor]
        self.nextButtonLayer.locations = [0.0, 1.0]
        self.nextButtonNode.layer.insertSublayer(self.nextButtonLayer, below: self.nextButtonNode.titleNode.layer)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hiddenKeyBoard(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.closeButtonNode, frame: CGRect(x: size.width - 50 , y: 17, width: 40, height: 40))
        transition.updateFrame(node: self.avatarNode, frame: CGRect(x: (size.width - 64) / 2, y: 70, width: 64, height: 64))
        transition.updateFrame(node: self.nameNode, frame: CGRect(x: 0, y: 140, width: size.width, height: 22))
        transition.updateFrame(node: self.sumMoneyNode, frame: CGRect(x: 30, y: 259, width: size.width - 60, height: 20))
        transition.updateFrame(node: self.lackOfBalanceAlertNode, frame: CGRect(x: 30, y: 259, width: size.width - 60, height: 20))
        transition.updateFrame(view: self.transferAssetNode, frame: CGRect(x: (size.width - 250) / 2, y: 291, width: 250, height: 47))
        transition.updateFrame(node: self.lineNode, frame: CGRect(x: 55, y: 345, width: size.width - 110, height: 1))
        transition.updateFrame(node: self.balanceNode, frame: CGRect(x: 30, y: 351, width: size.width - 60, height: 20))
        transition.updateFrame(node: self.nextButtonNode, frame: CGRect(x: 24, y: size.height - 98, width: size.width - 48, height: 48))
        transition.updateFrame(layer: self.nextButtonLayer, frame: CGRect(x: 0, y: 0, width: size.width - 48, height: 48))
    }
    
    @objc func closeButtonClickEvent(sender: UIButton) {
        self.closeEvent?()
    }
    
    @objc func nextButtonClickEvent(sender: UIButton) {
        self.nextEvent?()
    }
    
    
    @objc func hiddenKeyBoard(tap: UITapGestureRecognizer) {
        self.transferAssetNode.resignFirstResponder()
    }
    
    private var keyBoardHeight: CGFloat = 0.0
    private var keyBoardShow: Bool = false
    @objc func keyboardWillShow(noti: Notification) {
        if self.keyBoardShow { return }
        self.keyBoardShow = true
        let duration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let endY = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.origin.y
        self.keyBoardHeight = UIScreen.main.bounds.height - endY
        let transition = ContainedViewLayoutTransition.animated(duration: duration, curve: .easeInOut)
        var frame = self.nextButtonNode.frame
        frame.origin.y -= self.keyBoardHeight / 2
        var mframe = self.frame
        mframe.origin.y -= self.keyBoardHeight / 2
        transition.updateFrame(node: self.nextButtonNode, frame: frame)
        transition.updateFrame(node: self, frame: mframe)
    }
    
    @objc func keyboardWillHidden(noti: Notification) {
        if self.keyBoardShow == false { return }
        self.keyBoardShow = false
        let duration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let transition = ContainedViewLayoutTransition.animated(duration: duration, curve: .easeInOut)
        var frame = self.nextButtonNode.frame
        frame.origin.y += self.keyBoardHeight / 2
        transition.updateFrame(node: self.nextButtonNode, frame: frame)
        var mframe = self.frame
        mframe.origin.y += self.keyBoardHeight / 2
        transition.updateFrame(node: self, frame: mframe)
    }
    
    
    func cleanInput() {
        self.transferAssetNode.text = ""
        self.bitInputPromise.set("")
    }
    
    func updateNextButtonStatus(useAble: Bool) {
        self.nextButtonNode.alpha = useAble ? 1 : 0.6
        self.nextButtonNode.isEnabled = useAble
    }
    
    func endEdit() {
        self.transferAssetNode.resignFirstResponder()
    }
    
    func updateNetwork(_ network: NetworkItem) {
        let transition = ContainedViewLayoutTransition.animated(duration: 0.22, curve: .easeInOut)
        let width = self.networkTitleNode.updateNetwork(network)
        transition.updateFrame(node: self.networkTitleNode, frame: CGRect(x: 0, y: 16, width: width, height: 42))
        self.networkTitleNode.update(size: CGSize(width: width, height: 42), transition: transition)
    }
    
    func updateCurrency(_ network: NetworkItem) {
        let transition = ContainedViewLayoutTransition.immediate
        let width = self.bitTitleNode.updateNetwork(network)
        transition.updateFrame(node: self.bitTitleNode, frame: CGRect(x: (UIScreen.main.bounds.width - width) / 2, y: 198, width: width, height: 36))
        self.bitTitleNode.update(size: CGSize(width: width, height: 36), transition: transition)
    }
    
    func updateTransferName(name: String) {
        let formatString = TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_towhotransfer)
        let transtext =  String(format: formatString,name )
        self.nameNode.attributedText = NSAttributedString(string:transtext, font: Font.bold(18), textColor: UIColor(hexString: "#FF1A1A1D")!, paragraphAlignment: .center)
    }
    
    func updateTransferAvatar(avatar: UIImage?) {
        self.avatarNode.image = avatar
    }
    
    func updateFromBalance(by type: FromBalanceType) {
        switch type {
        case .none:
            self.lackOfBalanceAlertNode.isHidden = false
            self.sumMoneyNode.isHidden = true
            
            
            self.lackOfBalanceAlertNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_input_price_tips),
                                                                            font: Font.regular(14),
                                                                            textColor: UIColor(hexString: "#FF56565C")!,paragraphAlignment: .center)
        case .lackOfBalance:
            self.lackOfBalanceAlertNode.isHidden = false
            self.sumMoneyNode.isHidden = true
            
            self.lackOfBalanceAlertNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_input_price_tips1),
                                                                            font: Font.regular(14),
                                                                            textColor: UIColor(hexString: "#FFFF4550")!,
                                                                            paragraphAlignment: .center)
        case let .input(value):
            self.lackOfBalanceAlertNode.isHidden = true
            self.sumMoneyNode.isHidden = false
            self.sumMoneyNode.attributedText = NSAttributedString(string: value, font: Font.regular(14), textColor: UIColor(hexString: "#FF56565C")!,paragraphAlignment: .center)
        }
    }
    
    func updateBalance(by balance: Balance) {
        switch balance {
        case .unkonw:
            self.balanceNode.isHidden = true
            self.invalidNetworkAlertNode.isHidden = true
        case let .invalid(network):
            self.balanceNode.isHidden = true
            self.invalidNetworkAlertNode.isHidden = false
            let size = self.invalidNetworkAlertNode.updateAlert(" " + network)
            self.invalidNetworkAlertNode.frame = CGRect(x: (UIScreen.main.bounds.width - size.width) / 2.0, y: 349, width: size.width, height: size.height)
            self.invalidNetworkAlertNode.updateFrame(by: size)
        case let .valid(value):
            self.balanceNode.isHidden = false
            self.invalidNetworkAlertNode.isHidden = true
            self.balanceNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_wallet_balance) + value, font: Font.regular(14), textColor: UIColor(hexString: "#FF56565C")!,paragraphAlignment: .center)
        }
    }
    
    public func getInputText() -> String {
        return self.transferAssetNode.text ?? "0"
    }
}

extension TBTransferAssetContainNode: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, string == "." {
            if text.count == 0 {
                return false
            }
            if text.contains(".") {
                return false
            }
        }
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        self.bitInputPromise.set(text)
        return true
    }
}

