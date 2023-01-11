

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

private struct TBItemLimitState: Equatable {
    let groupLimit: TBWeb3GroupInfoEntry.LimitType
    let config: TBWeb3ConfigEntry
    var currentItem:TBWeb3ConfigEntry.Token?
    
    static func == (lhs: TBItemLimitState, rhs: TBItemLimitState) -> Bool {
        return lhs.currentItem == rhs.currentItem
    }
}

private struct TBItemLimitArguments {
    let context: AccountContext
    let selectItem:(TBWeb3ConfigEntry.Token)->Void
    let done:()->Void
}

private enum TBItemLimitEntryTag: ItemListItemTag {
    case test 
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? TBItemLimitEntryTag {
            switch self {
            case .test:
                if case .test = other {
                    return true
                }else {
                    return false
                }
            }
        }else{
            return false
        }
    }
}

private enum TBItemLimitSection: Int32 {
    case section
}

private enum TBItemLimitEntry: ItemListNodeEntry {
    
    
    case item(TBWeb3ConfigEntry.Token, Int, Bool)
    

    var section: ItemListSectionId {
        return TBItemLimitSection.section.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case let .item(_, idx, _):
           return Int32(idx)
        }
    }
    
    static func ==(lhs: TBItemLimitEntry, rhs: TBItemLimitEntry) -> Bool {
        switch lhs {
        case let .item(lhsItem, lhsIdx, lhsIsSelect):
            if case let .item(rhsItem, rhsIdx, rhsIsSelect) = rhs, lhsItem == rhsItem, lhsIdx == rhsIdx, lhsIsSelect == rhsIsSelect {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: TBItemLimitEntry, rhs: TBItemLimitEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TBItemLimitArguments
        switch self {
        case let .item(item, _, isSelect):
            return TBItemListCheckboxItem(presentationData: presentationData, title:item.name, style: .right, checked: isSelect, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.selectItem(item)
            })
        }
    }
}

private func itemEntries(presentationData: PresentationData, state: TBItemLimitState) -> [TBItemLimitEntry] {
    var entries: [TBItemLimitEntry] = []
    let limitType = state.groupLimit
    let tokenList = state.config.tokenType.filter{ item in
        if limitType == .payLimit, item.tokenType() == .erc_721{
            return false
        }
        return true
    }
    
    for (idx, item) in tokenList.enumerated() {
        entries.append(.item(item, idx, item == state.currentItem))
    }

    return entries
}

public func tokenListControllerImpl(context: AccountContext,
                                    groupLimit: TBWeb3GroupInfoEntry.LimitType,
                                    config: TBWeb3ConfigEntry,
                                    selectItem: TBWeb3ConfigEntry.Token? = nil,
                                    update:@escaping (TBWeb3ConfigEntry.Token) -> Void,
                                    completion: ((PeerId, @escaping () -> Void) -> Void)? = nil) -> ViewController {
    
    let initialState = TBItemLimitState(groupLimit:groupLimit, config: config, currentItem: selectItem )
    
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((TBItemLimitState) -> TBItemLimitState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    var replaceControllerImpl: ((ViewController) -> Void)?
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var pushImpl: ((ViewController) -> Void)?
    var endEditingImpl: (() -> Void)?
    var ensureItemVisibleImpl: ((TBItemLimitEntryTag, Bool) -> Void)?
    
    let actionsDisposable = DisposableSet()

    let arguments = TBItemLimitArguments(
        context: context,
        selectItem: { item in
            updateState { current in
                var current = current
                current.currentItem = item
                return current
            }
            update(item)
        },
        done: {
            dismissImpl?()
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let rightNavigationButton: ItemListNavigationButton
        rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Done), style: .bold, enabled: true, action: {
            arguments.done()
        })
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(""), leftNavigationButton: nil, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Done))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: itemEntries(presentationData: presentationData, state: state), style: .blocks)
        
        return (controllerState, (listState, arguments))
    }
    |> afterDisposed {
        actionsDisposable.dispose()
    }
    
    let controller = ItemListController(context: context, state: signal)
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
