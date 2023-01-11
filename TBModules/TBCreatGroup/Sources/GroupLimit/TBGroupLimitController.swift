

import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import LegacyComponents
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI
import PresentationDataUtils
import LegacyUI

import TBAccount
import TBDisplay
import TBWalletCore
import TBWeb3Core
import TBLanguage

private struct TBGroupLimitArguments {
    let context: AccountContext
    let updateFocus:(TBGroupLimitEntryTag, Bool) -> Void
    let updateGroupLimit:(TBWeb3GroupInfoEntry.LimitType) ->Void
    let changeToken:()->Void
    let changeChain:()->Void
    let changeCurrency:()->Void
    let done:()->Void
    let changeAddress:(String)->Void
    let changeTokenId:(String)->Void
    let changeMinToken:(String)->Void
    let changeMaxToken:(String)->Void
    let connectWallet:()->Void
    let changePayAmout:(String)->Void
}

private enum TBGroupLimitSection: Int32 {
    case limitSelect 
    
    case condition 
    case balance 
    
    case pay 
    case amount 
}

private enum TBGroupLimitEntryTag: ItemListItemTag {
    case payAmout 
    case address 
    case balanceMin 
    case balanceMax 
    case tokenId 
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? TBGroupLimitEntryTag {
            switch self {
            case .payAmout:
                if case .payAmout = other {
                    return true
                }else {
                    return false
                }
            case .address:
                if case .address = other {
                    return true
                }else{
                    return false
                }
            case .balanceMin:
                if case .balanceMin = other {
                    return true
                }else{
                    return false
                }
            case .balanceMax:
                if case .balanceMax = other {
                    return true
                }else{
                    return false
                }
            case .tokenId:
                if case .tokenId = other {
                    return true
                }else{
                    return false
                }
            }
        } else {
            return false
        }
    }
}

private enum TBGroupLimitEntry: ItemListNodeEntry {
    
    
    case limitHeader(des:String) 
    case noLimit(isSelect: Bool) 
    case conditionLimit(isSelect: Bool) 
    case payLimit(isSelect: Bool) 
    case limitfooter(des: String) 
    
    
    case conditionHeader(des: String) 
    case conditionChainType(title:String, type: TBWeb3ConfigEntry.Chain) 
    case conditionTokenType(title:String, type: TBWeb3ConfigEntry.Token) 
    case conditionAddress(title:String, address: String) 
    case conditionTokenId(title:String, tokenId: String) 
    
    case balanceHeader(des: String) 
    case balanceCoinType(title:String, type: TBWeb3ConfigEntry.Chain.Currency) 
    case balanceMin(min: String) 
    case balanceMax(max: String) 
    
    
    
    case payHeader(des: String) 
    
    case connectWallet(title: String) 
    case payWallet(title:String, walletConnect: TBWalletConnect, wallet:TBWeb3ConfigEntry.Wallet) 
    case payChainType(title:String, type: TBWeb3ConfigEntry.Chain) 
    case payTokenType(title:String, type: TBWeb3ConfigEntry.Token) 
    
    case amountHeader(des: String) 
    case amountCoinType(title: String, type: TBWeb3ConfigEntry.Chain.Currency) 
    case amount(amount: String) 
    
    
    
    var section: ItemListSectionId {
        switch self {
        case .limitHeader, .noLimit, .conditionLimit, .payLimit, .limitfooter:
            return TBGroupLimitSection.limitSelect.rawValue
        case .conditionHeader, .conditionChainType, .conditionTokenType, .conditionAddress, .conditionTokenId:
            return TBGroupLimitSection.condition.rawValue
        case .balanceHeader, .balanceCoinType, .balanceMin, .balanceMax:
            return TBGroupLimitSection.balance.rawValue
        case .payHeader, .connectWallet, .payWallet, .payChainType, .payTokenType:
            return TBGroupLimitSection.pay.rawValue
        case .amountHeader, .amountCoinType, .amount:
            return TBGroupLimitSection.amount.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .limitHeader:
            return 100
        case .noLimit:
            return 101
        case .conditionLimit:
            return 102
        case .payLimit:
            return 103
        case .limitfooter:
            return 104
            
        case .conditionHeader:
            return 200
        case .conditionChainType:
            return 201
        case .conditionTokenType:
            return 202
        case .conditionAddress:
            return 203
        case .conditionTokenId:
            return 204
            
        case .balanceHeader:
            return 300
        case .balanceCoinType:
            return 301
        case .balanceMin:
            return 302
        case .balanceMax:
            return 303
            
        case .payHeader:
            return 400
        case .connectWallet:
            return 401
        case .payWallet:
            return 402
        case .payChainType:
            return 403
        case .payTokenType:
            return 404
            
        case .amountHeader:
            return 500
        case .amountCoinType:
            return 501
        case .amount:
            return 502
        }
    }
    
    static func ==(lhs: TBGroupLimitEntry, rhs: TBGroupLimitEntry) -> Bool {
        switch lhs {
        case let .limitHeader(des: lhsDes):
            if case let .limitHeader(des: rhsDes) = rhs, lhsDes == rhsDes {
                return true
            } else {
                return false
            }
        case let .noLimit(isSelect: lhsIsSelect):
            if case let .noLimit(isSelect: rhsIsSelect) = rhs, lhsIsSelect == rhsIsSelect {
                return true
            } else {
                return false
            }
        case let .conditionLimit(isSelect: lhsIsSelect):
            if case let .conditionLimit(isSelect: rhsIsSelect) = rhs, lhsIsSelect == rhsIsSelect {
                return true
            } else {
                return false
            }
        case let .payLimit(isSelect: lhsIsSelect):
            if case let .payLimit(isSelect: rhsIsSelect) = rhs, lhsIsSelect == rhsIsSelect {
                return true
            } else {
                return false
            }
        case let .limitfooter(des: lhsDes):
            if case let .limitfooter(des: rhsDes) = rhs, lhsDes == rhsDes {
                return true
            } else {
                return false
            }
        case let .conditionHeader(des: lhsDes):
            if case let .conditionHeader(des: rhsDes) = rhs, lhsDes == rhsDes {
                return true
            } else {
                return false
            }
        case let .conditionChainType(title: lhsTitle, type: lhsType):
            if case let .conditionChainType(title: rhsTitle, type: rhsType) = rhs, lhsTitle == rhsTitle, lhsType == rhsType {
                return true
            } else {
                return false
            }
        case let .conditionTokenType(title: lhsTitle, type: lhsType):
            if case let .conditionTokenType(title: rhsTitle, type: rhsType) = rhs, lhsTitle == rhsTitle, lhsType == rhsType {
                return true
            } else {
                return false
            }
        case let .conditionAddress(title: lhsTitle, address: lhsAddress):
            if case let .conditionAddress(title: rhsTitle, address: rhsAddress) = rhs, lhsTitle == rhsTitle, lhsAddress == rhsAddress {
                return true
            } else {
                return false
            }
        case let .conditionTokenId(title: lhsTitle, tokenId: lhsTokenId):
            if case let .conditionTokenId(title: rhsTitle, tokenId: rhsTokenId) = rhs, lhsTitle == rhsTitle, lhsTokenId == rhsTokenId {
                return true
            } else {
                return false
            }
        case let .balanceHeader(des: lhsDes):
            if case let .balanceHeader(des: rhsDes) = rhs, lhsDes == rhsDes{
                return true
            } else {
                return false
            }
        case let .balanceCoinType(title: lhsTitle, type: lhsType):
            if case let .balanceCoinType(title: rhsTitle, type: rhsType) = rhs, lhsTitle == rhsTitle, lhsType == rhsType{
                return true
            } else {
                return false
            }
        case let .balanceMin(min: lhsMin):
            if case let .balanceMin(min: rhsMin) = rhs, lhsMin == rhsMin{
                return true
            } else {
                return false
            }
        case let .balanceMax(max: lhsMax):
            if case let .balanceMax(max: rhsMax) = rhs, lhsMax == rhsMax{
                return true
            } else {
                return false
            }
        case let .payHeader(des: lhsDes):
            if case let .payHeader(des: rhsDes) = rhs, lhsDes == rhsDes{
                return true
            } else {
                return false
            }
        case let .payWallet(title: lhsTitle, walletConnect: lhsWalletConnect, _):
            if case let .payWallet(title: rhsTitle, walletConnect: rhsWalletConnect, _) = rhs, lhsTitle == rhsTitle, lhsWalletConnect == rhsWalletConnect{
                return true
            } else {
                return false
            }
        case let .connectWallet(title: lhsTitle):
            if case let .connectWallet(title: rhsTitle) = rhs, lhsTitle == rhsTitle{
                return true
            } else {
                return false
            }
        case let .payChainType(title: lhsTitle, type: lhsType):
            if case let .payChainType(title: rhsTitle, type: rhsType) = rhs, lhsTitle == rhsTitle, lhsType == rhsType{
                return true
            } else {
                return false
            }
        case let .payTokenType(title: lhsTitle, type: lhsType):
            if case let .payTokenType(title: rhsTitle, type: rhsType) = rhs, lhsTitle == rhsTitle, lhsType == rhsType{
                return true
            } else {
                return false
            }
        case let .amountHeader(des: lhsDes):
            if case let .amountHeader(des: rhsDes) = rhs, lhsDes == rhsDes{
                return true
            } else {
                return false
            }
        case let .amountCoinType(title: lhsTitle, type: lhsType):
            if case let .amountCoinType(title: rhsTitle, type: rhsType) = rhs, lhsTitle == rhsTitle, lhsType == rhsType{
                return true
            } else {
                return false
            }
        case let .amount(amount: lhsAmount):
            if case let .amount(amount: rhsAmount) = rhs, lhsAmount == rhsAmount {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: TBGroupLimitEntry, rhs: TBGroupLimitEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TBGroupLimitArguments
        switch self {
        case let .limitHeader(des: des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
        case let .noLimit(isSelect: isSelect):
            return ItemListCheckboxItem(presentationData: presentationData, title: TBWeb3GroupInfoEntry.LimitType.noLimit.des, style: .left, checked: isSelect, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateGroupLimit(.noLimit)
            })
        case let .conditionLimit(isSelect: isSelect):
            return ItemListCheckboxItem(presentationData: presentationData, title: TBWeb3GroupInfoEntry.LimitType.conditionLimit.des, style: .left, checked: isSelect, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateGroupLimit(.conditionLimit)
            })
        case let .payLimit(isSelect: isSelect):
            return ItemListCheckboxItem(presentationData: presentationData, title: TBWeb3GroupInfoEntry.LimitType.payLimit.des, style: .left, checked: isSelect, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateGroupLimit(.payLimit)
            })
        case let .limitfooter(des: des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
        case let .conditionHeader(des: des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
        case .conditionChainType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , sectionId: self.section, style: .blocks) {
                arguments.changeChain()
            }
        case .conditionTokenType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , sectionId: self.section, style: .blocks) {
                arguments.changeToken()
            }
        case .conditionAddress(title: let title, address: let address):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title, attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x828282)]), text: address, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_input_tokenaddress),spacing: 10, tag: TBGroupLimitEntryTag.address, sectionId: self.section) { text in
                arguments.changeAddress(text)
            } action: {
            }
        case .conditionTokenId(title: let title, tokenId: let tokenId):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title, attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x828282)]), text: tokenId, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_input_token), spacing: 10, tag: TBGroupLimitEntryTag.tokenId, sectionId: self.section) { text in
                arguments.changeTokenId(text)
            } action: {
            }
        case .balanceHeader(des: let des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
        case .balanceCoinType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , sectionId: self.section, style: .blocks) {
                arguments.changeCurrency()
            }
        case .balanceMin(min: let min):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: "", attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x828282)]), text: min, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_input_tokennum_min), spacing: 10, tag: TBGroupLimitEntryTag.balanceMin, sectionId: self.section) { text in
                arguments.changeMinToken(text)
            } action: {
            }
        case .balanceMax(max: let max):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: "", attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x828282)]), text: max, placeholder: "Toekn", spacing: 10, tag: TBGroupLimitEntryTag.balanceMax, sectionId: self.section) { text in
                arguments.changeMaxToken(text)
            } action: {
            }
        case let .payHeader(des: des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
            
        case let .connectWallet(title: title):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:"" , sectionId: self.section, style: .blocks) {
                arguments.connectWallet()
            }
        case .payWallet(title: let title, walletConnect: let walletConnect, wallet: let wallet):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, enabled: false, label:wallet.name , sectionId: self.section, style: .blocks, disclosureStyle: .none) {
                
            }
        case .payChainType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , sectionId: self.section, style: .blocks) {
                arguments.changeChain()
            }
        case .payTokenType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , sectionId: self.section, style: .blocks) {
                arguments.changeToken()
            }
        case let .amountHeader(des: des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
        case .amountCoinType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , sectionId: self.section, style: .blocks) {
                arguments.changeCurrency()
            }
        case .amount(amount: let amount):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string:""), text: amount, placeholder: "", tag: TBGroupLimitEntryTag.payAmout, sectionId: self.section, textUpdated: {
                text in
                arguments.changePayAmout(text)
            }, shouldUpdateText: { text in
                return true
            }, updatedFocus: {focus in
                arguments.updateFocus(TBGroupLimitEntryTag.payAmout, focus)
            }, action: {
                
            })
        }
    }
}

private func groupLimitEntries(presentationData: PresentationData, state: TBGroupLimitState) -> [TBGroupLimitEntry] {
    var entries: [TBGroupLimitEntry] = []
    
    entries.append(.limitHeader(des: ""))
    entries.append(.noLimit(isSelect: state.groupLimit == .noLimit))
    entries.append(.conditionLimit(isSelect: state.groupLimit == .conditionLimit))
    entries.append(.payLimit(isSelect: state.groupLimit == .payLimit))
    if state.groupLimit != .noLimit {
        entries.append(.limitfooter(des: ""))
    }
    
    if state.groupLimit == .conditionLimit {
    
        entries.append(.conditionHeader(des: ""))
        if let chainType = state.conditionLimitState.chainType {
            entries.append(.conditionChainType(title: "Chain Type", type: chainType))
        }
        if let tokenType = state.conditionLimitState.tokenType {
            entries.append(.conditionTokenType(title: "Token Type", type: tokenType))
        }
        entries.append(.conditionAddress(title: "Address", address: state.conditionLimitState.address))
        
        //entries.append(.conditionTokenId(title: "Token ID", tokenId: state.conditionLimitState.tokenId))
        
        entries.append(.balanceHeader(des: "Balance"))
        if let currency = state.conditionLimitState.currencyType {
            entries.append(.balanceCoinType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_coin_type), type: currency))
        }
        entries.append(.balanceMin(min: state.conditionLimitState.minToken))
        entries.append(.balanceMax(max: state.conditionLimitState.maxToken))
    } else if state.groupLimit == .payLimit {
        entries.append(.payHeader(des: ""))
        if let c = state.payLimitState.wallet, let wallet = c.platForm.transform(config: state.config) {
            entries.append(.payWallet(title: "", walletConnect: c, wallet: wallet))
            if let chainType = state.payLimitState.chainType {
                entries.append(.payChainType(title: "Chain Type", type: chainType))
            }
            if let tokenType = state.payLimitState.tokenType {
                entries.append(.payTokenType(title: "Token Type", type: tokenType))
            }
            entries.append(.amountHeader(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_paynum)))
            if let coinType = state.payLimitState.coinType {
                entries.append(.amountCoinType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_coin_type), type: coinType))
            }
            entries.append(.amount(amount: state.payLimitState.amount))
        }else{
            entries.append(.connectWallet(title: ""))
        }
    }
    return entries
}

public func groupLimitControllerImpl(context: AccountContext, config: TBWeb3ConfigEntry, initalLimitState:TBGroupLimitState?, update:@escaping (TBGroupLimitState)->Void) -> ViewController {
    
    let initialState:TBGroupLimitState
    if let initalLimitState = initalLimitState {
        initialState = initalLimitState
    }else{
        initialState = TBGroupLimitState(config: config, limit: .noLimit)
    }
    
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((TBGroupLimitState) -> TBGroupLimitState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    var replaceControllerImpl: ((ViewController) -> Void)?
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var pushImpl: ((ViewController) -> Void)?
    var endEditingImpl: (() -> Void)?
    var ensureItemVisibleImpl: ((TBGroupLimitEntryTag, Bool) -> Void)?
    
    let actionsDisposable = DisposableSet()
    
    let arguments = TBGroupLimitArguments(
        context: context,
        updateFocus: { entrtyTag, focus in
            if focus {
                ensureItemVisibleImpl?(entrtyTag, true)
            }
        },
        updateGroupLimit: { limitType in
            updateState { current in
                var current = current
                current.groupLimit = limitType
                return current
            }
        },
        changeToken: {
            let state = stateValue.with{$0}
            let controller = tokenListControllerImpl(
                context: context,
                groupLimit: state.groupLimit,
                config: config,
                selectItem: state.currentSelectToken(),
                update: { item in
                    updateState{ current in
                        return TBGroupLimitState.changeSelectToken(item, state: current)
                    }
                }
            )
            pushImpl?(controller)
        },
        changeChain: {
            let state = stateValue.with{$0}
            let controller = chainListControllerImpl(
                context: context,
                config: config,
                selectItem: state.currentSelectChain(),
                update: { item in
                    updateState{ current in
                        return TBGroupLimitState.changeSelectChain(item, state: current)
                    }
                }
            )
            pushImpl?(controller)
        },
        changeCurrency: {
            let state = stateValue.with{$0}
            if let chain = state.currentSelectChain() {
                let controller = chainCurrencyListControllerImpl(
                    context: context,
                    chain: chain,
                    selectItem: state.currentSelectCurrency(),
                    update: { item in
                        updateState{ current in
                            return TBGroupLimitState.changeSelectChainCurrency(item, state: current)
                        }
                    }
                )
                pushImpl?(controller)
            }
        },
        done:{
            update(stateValue.with({$0}))
            dismissImpl?()
        },
        changeAddress: { text in
            updateState{ current in
                var current = current
                current.conditionLimitState.address = text
                return current
            }
        },
        changeTokenId: { text in
            updateState{ current in
                var current = current
                current.conditionLimitState.tokenId = text
                return current
            }
        },
        changeMinToken: { text in
            updateState{ current in
                var current = current
                current.conditionLimitState.minToken = text
                return current
            }
        },
        changeMaxToken: { text in
            updateState{ current in
                var current = current
                current.conditionLimitState.maxToken = text
                return current
            }
        },
        connectWallet: {
            TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask) { result, c in
                if let c = c, result == true {
                    updateState{ current in
                        var current = current
                        current.payLimitState.wallet = c
                        return current
                    }
                }
            }
        },
        changePayAmout: { text in
            updateState{ current in
                var current = current
                current.payLimitState.amount = text
                return current
            }
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let rightNavigationButton: ItemListNavigationButton
        rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Done), style: .bold, enabled: state.checkInfo() == .pass, action: {
            arguments.done()
        })
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(""), leftNavigationButton: nil, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: groupLimitEntries(presentationData: presentationData, state: state), style: .blocks, focusItemTag: TBGroupLimitEntryTag.payAmout)
        
        return (controllerState, (listState, arguments))
    }
    |> afterDisposed {
        actionsDisposable.dispose()
    }
    
    let controller = ItemListController(context: context, state: signal)
    controller.didDeinit = {
        let state = stateValue.with {$0}
        if state.checkInfo() == .pass {
            update(state)
        }
    }
    replaceControllerImpl = { [weak controller] value in
        (controller?.navigationController as? NavigationController)?.replaceAllButRootController(value, animated: true)
    }
    dismissImpl = { [weak controller] in
        if let controller = controller {
            (controller.navigationController as? NavigationController)?.filterController(controller, animated: true)
        }
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    pushImpl = { [weak controller] c in
        controller?.push(c)
    }
    controller.willDisappear = { _ in
        endEditingImpl?()
    }
    endEditingImpl = {
        [weak controller] in
        controller?.view.endEditing(true)
    }
    ensureItemVisibleImpl = { [weak controller] targetTag, animated in
        controller?.afterLayout({
            guard let controller = controller else {
                return
            }
            var resultItemNode: ListViewItemNode?
            let _ = controller.frameForItemNode({ itemNode in
                if let itemNode = itemNode as? ItemListItemNode {
                    if let tag = itemNode.tag, tag.isEqual(to: targetTag) {
                        resultItemNode = itemNode as? ListViewItemNode
                        return true
                    }
                }
                return false
            })
            
            if let resultItemNode = resultItemNode {
                controller.ensureItemNodeVisible(resultItemNode, animated: animated)
            }
        })
    }
    return controller
}
