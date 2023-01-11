






import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import LegacyComponents
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import OpenInExternalAppUI
import ItemListPeerActionItem
import TBStorage
import TBLanguage

private final class TBIncognitoModeViewControllerArguments {
    let toggleNotShowingMyPhone: (Bool) -> Void
    let toggleNoReadReceipt: (Bool) -> Void
    let toggleNotDisplayedOnlineStatus: (Bool) -> Void
    
    init(toggleNotShowingMyPhone: @escaping (Bool) -> Void, toggleNoReadReceipt: @escaping (Bool) -> Void, toggleNotDisplayedOnlineStatus: @escaping (Bool) -> Void) {
        self.toggleNotShowingMyPhone = toggleNotShowingMyPhone
        self.toggleNoReadReceipt = toggleNoReadReceipt
        self.toggleNotDisplayedOnlineStatus = toggleNotDisplayedOnlineStatus
    }
}


private enum DataAndStorageSection: Int32 {
    case phone
    case readed
    case online
}


public enum DataAndStorageEntryTag: ItemListItemTag {
    case notShowingMyPhone
    case noReadReceipt
    case notDisplayedOnlineStatus

    public func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DataAndStorageEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum TBPrivacyItemNodeEntry: ItemListNodeEntry {
    case notShowingMyPhone(PresentationTheme, String, Bool)
    case noReadReceipt(PresentationTheme, String, Bool)
    case noReadReceiptInfo(PresentationTheme, String)
    case notDisplayedOnlineStatus(PresentationTheme, String, Bool)
    case notDisplayedOnlineStatusInfo(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .notShowingMyPhone:
            return DataAndStorageSection.phone.rawValue
        case .noReadReceipt, .noReadReceiptInfo:
            return DataAndStorageSection.readed.rawValue
        case .notDisplayedOnlineStatus, .notDisplayedOnlineStatusInfo:
            return DataAndStorageSection.online.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .notShowingMyPhone:
            return 0
        case .noReadReceipt:
            return 1
        case .noReadReceiptInfo:
            return 2
        case .notDisplayedOnlineStatus:
            return 3
        case .notDisplayedOnlineStatusInfo:
            return 4
        }
    }
    
    static func ==(lhs: TBPrivacyItemNodeEntry, rhs: TBPrivacyItemNodeEntry) -> Bool {
        switch lhs {
        case let .notShowingMyPhone(lhsTheme, lhsText, lhsValue):
            if case let .notShowingMyPhone(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .noReadReceipt(lhsTheme, lhsText, lhsValue):
            if case let .noReadReceipt(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .noReadReceiptInfo(lhsTheme, lhsText):
            if case let .noReadReceiptInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .notDisplayedOnlineStatus(lhsTheme, lhsText, lhsValue):
            if case let .notDisplayedOnlineStatus(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .notDisplayedOnlineStatusInfo(lhsTheme, lhsText):
            if case let .notDisplayedOnlineStatusInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: TBPrivacyItemNodeEntry, rhs: TBPrivacyItemNodeEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TBIncognitoModeViewControllerArguments
        switch self {
        case let .notShowingMyPhone(_, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, maximumNumberOfLines: 2, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleNotShowingMyPhone(value)
            }, tag: DataAndStorageEntryTag.notShowingMyPhone)
        case let .noReadReceipt(_, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleNoReadReceipt(value)
            }, tag: DataAndStorageEntryTag.noReadReceipt)
        case let .noReadReceiptInfo(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .notDisplayedOnlineStatus(_, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleNotDisplayedOnlineStatus(value)
            }, tag: DataAndStorageEntryTag.notDisplayedOnlineStatus)
        case let .notDisplayedOnlineStatusInfo(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private struct TBPrivacyControllerState: Equatable {
    var notShowMyPhoneInMyInterface = false
    var noReadReceipt = false
    var notDisplayedOnlineStatus = false
    
    static func ==(lhs: TBPrivacyControllerState, rhs: TBPrivacyControllerState) -> Bool {
        return lhs.notShowMyPhoneInMyInterface == rhs.notShowMyPhoneInMyInterface &&
        lhs.noReadReceipt == rhs.noReadReceipt &&
        lhs.notDisplayedOnlineStatus == rhs.notDisplayedOnlineStatus
    }
}

private func dataAndStorageControllerEntries(presentationData: PresentationData, state:TBPrivacyControllerState) -> [TBPrivacyItemNodeEntry] {
    var entries: [TBPrivacyItemNodeEntry] = []
    entries.append(.notShowingMyPhone(presentationData.theme, TBLanguage.sharedInstance.localizable(TBLankey.setting_not_show_phone_in_my_interface), state.notShowMyPhoneInMyInterface))
    entries.append(.noReadReceipt(presentationData.theme, TBLanguage.sharedInstance.localizable(TBLankey.setting_No_read_receipt), state.noReadReceipt))
    entries.append(.noReadReceiptInfo(presentationData.theme, TBLanguage.sharedInstance.localizable(TBLankey.setting_No_read_receipt_des)))
    entries.append(.notDisplayedOnlineStatus(presentationData.theme, TBLanguage.sharedInstance.localizable(TBLankey.setting_Online_status_is_not_displayed), state.notDisplayedOnlineStatus))
    entries.append(.notDisplayedOnlineStatusInfo(presentationData.theme, TBLanguage.sharedInstance.localizable(TBLankey.setting_Online_status_is_not_displayed_des)))
    return entries
}

public func makeTBIncognitoModeViewController(context: AccountContext) -> ViewController {
    
    
    var initialState = TBPrivacyControllerState()
    
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    
    let actionsDisposable = DisposableSet()
    
    
    let arguments = TBIncognitoModeViewControllerArguments { value in
        UserDefaults.standard.tb_set(bool: value, for: .dontShowMyPhoneOnMyInterface)
        initialState.notShowMyPhoneInMyInterface = UserDefaults.standard.tb_bool(for: .dontShowMyPhoneOnMyInterface)
        statePromise.set(initialState)
    } toggleNoReadReceipt: { value in
        UserDefaults.standard.tb_set(bool: value, for: .coinIncognitoMode)
        initialState.noReadReceipt = UserDefaults.standard.tb_bool(for: .coinIncognitoMode)
        statePromise.set(initialState)
    } toggleNotDisplayedOnlineStatus: { value in
        
        let _ = (context.engine.privacy.requestAccountPrivacySettings() |> take(1)).start { settings in 
            var enbalePeerIds = [PeerId : SelectivePrivacyPeer]()
            var disablePeerIds = [PeerId : SelectivePrivacyPeer]()
            switch settings.presence {
            case let .disableEveryone(enableFor):
                enbalePeerIds = enableFor
            case let .enableContacts(enableFor, disableFor):
                enbalePeerIds = enableFor
                disablePeerIds = disableFor
            case let .enableEveryone(disableFor):
                disablePeerIds = disableFor
            default :
                break
            }
            
            var updateSettingSignal: Signal<Void, NoError>?
            
            if value { 
                updateSettingSignal = context.engine.privacy.updateSelectiveAccountPrivacySettings(type: .presence, settings: .disableEveryone(enableFor: enbalePeerIds))
            }else{
                updateSettingSignal = context.engine.privacy.updateSelectiveAccountPrivacySettings(type: .presence, settings: .enableContacts(enableFor: enbalePeerIds, disableFor: disablePeerIds))
            }
            if let updateSettingSignal = updateSettingSignal {
                
                actionsDisposable.add(updateSettingSignal.start(completed:{
                    initialState.notDisplayedOnlineStatus = value
                    statePromise.set(initialState)
                }))
            }
        } error: { _ in
            
        } completed: {
            
        }
    }
    
    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(TBLanguage.sharedInstance.localizable(TBLankey.setting_incognito_settings)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: dataAndStorageControllerEntries(presentationData: presentationData, state: state), style: .blocks, ensureVisibleItemTag: nil, emptyStateItem: nil, animateChanges: false)
        return (controllerState, (listState, arguments))
    } |> afterDisposed {
        actionsDisposable.dispose()
    }
    
    let controller = ItemListController(context: context, state: signal)
    
    
    initialState.notShowMyPhoneInMyInterface = UserDefaults.standard.tb_bool(for: .dontShowMyPhoneOnMyInterface)
    initialState.noReadReceipt = UserDefaults.standard.tb_bool(for: .coinIncognitoMode)
    statePromise.set(initialState)

    
    let presenceSignal = context.engine.privacy.requestAccountPrivacySettings()
    |> take(1)
    |> map({ accountPrivacySettings -> Bool  in
       var bidAll = false
        switch accountPrivacySettings.presence {
        case .disableEveryone:
            bidAll = true
        default:
            bidAll = false
        }
        return bidAll
    })
    let _ = presenceSignal.start(next: { isOn in
         initialState.notDisplayedOnlineStatus = isOn
         statePromise.set(initialState)
     })
    
    return controller
}
