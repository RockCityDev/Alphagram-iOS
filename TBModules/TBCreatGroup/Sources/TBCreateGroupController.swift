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
import MediaResources
import PhotoResources
import LocationResources
import LegacyUI
import LocationUI
import ItemListPeerItem
import ItemListAvatarAndNameInfoItem
import WebSearchUI
import Geocoding
import PeerInfoUI
import MapResourceToAvatarSizes
import ItemListAddressItem
import ItemListVenueItem
import LegacyMediaPickerUI
import TBAccount
import TBDisplay
import TBWeb3Core
import TBBusinessNetwork
import TBWalletCore
import InviteLinksUI
import TBLanguage

private struct CreateGroupArguments {
    let context: AccountContext
    
    let updateEditingName: (ItemListAvatarAndNameInfoItemName) -> Void
    let done: () -> Void
    let changeProfilePhoto: () -> Void
    let changeLocation: () -> Void
    let updateWithVenue: (TelegramMediaMap) -> Void
    let updateDes:(String) -> Void
    let addGroupLabel:() -> Void
    let changeLimt:() -> Void
    let deleteLabelEntity:([TBWeb3GroupInfoEntry.Tag])->Void
    
    let updateFocus:(CreateGroupEntryTag, Bool) -> Void
    let updateGroupLimit:(TBWeb3GroupInfoEntry.LimitType) ->Void
    let changeToken:()->Void
    let changeChain:()->Void
    let changeCurrency:()->Void
    let changeAddress:(String)->Void
    let changeTokenId:(String)->Void
    let changeMinToken:(String)->Void
    let changeMaxToken:(String)->Void
    let connectWallet:()->Void
    let changePayAmout:(String)->Void
    let endEditing:()->Void
}

private enum CreateGroupSection: Int32 {
    case info
    
    case label 
    case limit 
    
    case limitSelect 
    
    case condition 
    case balance 
    
    case pay 
    case amount 
    
    case members
    case location
    case venues
}

private enum CreateGroupEntryTag: ItemListItemTag {
    case info
    case des
    
    case payAmout 
    case address 
    case balanceMin 
    case balanceMax 
    case tokenId 
    
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? CreateGroupEntryTag {
            switch self {
            case .info:
                if case .info = other {
                    return true
                } else {
                    return false
                }
            case .des:
                if case .des = other {
                    return true
                } else {
                    return false
                }
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

private enum CreateGroupEntry: ItemListNodeEntry {
    
    case groupInfo(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, Peer?, ItemListAvatarAndNameInfoItemState, ItemListAvatarAndNameInfoItemUpdatingAvatar?)
    case setProfilePhoto(PresentationTheme, String)
    
    case groupDes(PresentationTheme, String)
    
    case addGroupLabel(PresentationTheme, UIImage, String)
    
    
    case groupLabel(PresentationTheme, [TBWeb3GroupInfoEntry.Tag])
    
    case labelHint(PresentationTheme, String)
    
    
    
    case groupLimit(PresentationTheme, UIImage, String, String,TBWeb3GroupInfoEntry.LimitType)
    
    case limitHint(PresentationTheme, String)
    
    
    
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
    

    
    case member(Int32, PresentationTheme, PresentationStrings, PresentationDateTimeFormat, PresentationPersonNameOrder, Peer, PeerPresence?)
    
    
    case locationHeader(PresentationTheme, String)
    case location(PresentationTheme, PeerGeoLocation)
    case changeLocation(PresentationTheme, String)
    case locationInfo(PresentationTheme, String)
    case venueHeader(PresentationTheme, String)
    case venue(Int32, PresentationTheme, TelegramMediaMap)
    
    
    var section: ItemListSectionId {
        switch self {
        case .groupInfo, .setProfilePhoto, .groupDes:
            return CreateGroupSection.info.rawValue
        case .addGroupLabel, .groupLabel, .labelHint:
            return CreateGroupSection.label.rawValue
        case .groupLimit, .limitHint:
            return CreateGroupSection.limit.rawValue
        case .limitHeader, .noLimit, .conditionLimit, .payLimit, .limitfooter:
            return CreateGroupSection.limitSelect.rawValue
        case .conditionHeader, .conditionChainType, .conditionTokenType:
            return CreateGroupSection.condition.rawValue
        case .balanceHeader, .balanceCoinType, .balanceMin, .balanceMax, .conditionAddress, .conditionTokenId:
            return CreateGroupSection.balance.rawValue
        case .payHeader, .connectWallet, .payWallet, .payChainType, .payTokenType:
            return CreateGroupSection.pay.rawValue
        case .amountHeader, .amountCoinType, .amount:
            return CreateGroupSection.amount.rawValue
        case .member:
            return CreateGroupSection.members.rawValue
        case .locationHeader, .location, .changeLocation, .locationInfo:
            return CreateGroupSection.location.rawValue
        case .venueHeader, .venue:
            return CreateGroupSection.venues.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .groupInfo:
            return 0
        case .setProfilePhoto:
            return 1
        case .groupDes:
            return 2
        case .addGroupLabel:
            return 3
        case .groupLabel:
            return 4
        case .labelHint:
            return 5
        case .groupLimit:
            return 6
        case .limitHint:
            return 7
            
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
            
        case .balanceHeader:
            return 300
        case .balanceCoinType:
            return 301
        case .balanceMin:
            return 302
        case .balanceMax:
            return 303
        case .conditionAddress:
            return 304
        case .conditionTokenId:
            return 305
            
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
            
            
        case let .member(index, _, _, _, _, _, _):
            return 503 + index
        case .locationHeader:
            return 10000
        case .location:
            return 10001
        case .changeLocation:
            return 10002
        case .locationInfo:
            return 10003
        case .venueHeader:
            return 10004
        case let .venue(index, _, _):
            return 10005 + index
        }
    }
    
    static func ==(lhs: CreateGroupEntry, rhs: CreateGroupEntry) -> Bool {
        switch lhs {
        case let .groupInfo(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsPeer, lhsEditingState, lhsAvatar):
            if case let .groupInfo(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsPeer, rhsEditingState, rhsAvatar) = rhs {
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsDateTimeFormat != rhsDateTimeFormat {
                    return false
                }
                if let lhsPeer = lhsPeer, let rhsPeer = rhsPeer {
                    if !lhsPeer.isEqual(rhsPeer) {
                        return false
                    }
                } else if (lhsPeer != nil) != (rhsPeer != nil) {
                    return false
                }
                if lhsEditingState != rhsEditingState {
                    return false
                }
                if lhsAvatar != rhsAvatar {
                    return false
                }
                return true
            } else {
                return false
            }
        case let .setProfilePhoto(lhsTheme, lhsText):
            if case let .setProfilePhoto(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .groupDes(lhsTheme, lhsText):
            if case let .groupDes(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .addGroupLabel(lhsTheme, _, lhsText):
            if case let .addGroupLabel(rhsTheme, _, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }else{
                return false
            }
            
        case let .groupLabel(lhsTheme, lhslabels):
            if case let .groupLabel(rhsTheme, rhslabels) = rhs, lhsTheme === rhsTheme, lhslabels.elementsEqual(rhslabels) {
                return true
            }
            return false
        case let .labelHint(lhsTheme, lhsText):
            if case let .labelHint(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }else{
                return false
            }
        case let .groupLimit(lhsTheme, _, lhsTitle, _, lhsLimit):
            if case let .groupLimit(rhsTheme, _, rhsTitle, _, rhsLimit) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsLimit == rhsLimit {
                return true
            }else{
                return false
            }
        case let .limitHint(lhsTheme, lhsText):
            if case let .limitHint(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }else{
                return false
            }
            
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
        case let .connectWallet(title: lhsTitle):
            if case let .connectWallet(title: rhsTitle) = rhs, lhsTitle == rhsTitle{
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
            
        case let .member(lhsIndex, lhsTheme, lhsStrings, lhsDateTimeFormat, lhsNameDisplayOrder, lhsPeer, lhsPresence):
            if case let .member(rhsIndex, rhsTheme, rhsStrings, rhsDateTimeFormat, rhsNameDisplayOrder, rhsPeer, rhsPresence) = rhs {
                if lhsIndex != rhsIndex {
                    return false
                }
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsDateTimeFormat != rhsDateTimeFormat {
                    return false
                }
                if lhsNameDisplayOrder != rhsNameDisplayOrder {
                    return false
                }
                if !lhsPeer.isEqual(rhsPeer) {
                    return false
                }
                if let lhsPresence = lhsPresence, let rhsPresence = rhsPresence {
                    if !lhsPresence.isEqual(to: rhsPresence) {
                        return false
                    }
                } else if (lhsPresence != nil) != (rhsPresence != nil) {
                    return false
                }
                return true
            } else {
                return false
            }
        case let .locationHeader(lhsTheme, lhsTitle):
            if case let .locationHeader(rhsTheme, rhsTitle) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
        case let .location(lhsTheme, lhsLocation):
            if case let .location(rhsTheme, rhsLocation) = rhs, lhsTheme === rhsTheme, lhsLocation == rhsLocation {
                return true
            } else {
                return false
            }
        case let .changeLocation(lhsTheme, lhsTitle):
            if case let .changeLocation(rhsTheme, rhsTitle) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
        case let .locationInfo(lhsTheme, lhsText):
            if case let .locationInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .venueHeader(lhsTheme, lhsTitle):
            if case let .venueHeader(rhsTheme, rhsTitle) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
        case let .venue(lhsIndex, lhsTheme, lhsVenue):
            if case let .venue(rhsIndex, rhsTheme, rhsVenue) = rhs {
                if lhsIndex != rhsIndex {
                    return false
                }
                if lhsTheme !== rhsTheme {
                    return false
                }
                if !lhsVenue.isEqual(to: rhsVenue) {
                    return false
                }
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: CreateGroupEntry, rhs: CreateGroupEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! CreateGroupArguments
        switch self {
        case let .groupInfo(_, _, dateTimeFormat, peer, state, avatar):
            return ItemListAvatarAndNameInfoItem(accountContext: arguments.context, presentationData: presentationData, dateTimeFormat: dateTimeFormat, mode: .editSettings, peer: peer.flatMap(EnginePeer.init), presence: nil, memberCount: nil, state: state, sectionId: ItemListSectionId(self.section), style: .blocks(withTopInset: false, withExtendedBottomInset: false), editingNameUpdated: { editingName in
                arguments.updateEditingName(editingName)
            }, editingNameCompleted: {
                arguments.endEditing()
            }, avatarTapped: {
                arguments.changeProfilePhoto()
            }, updatingImage: avatar, tag: CreateGroupEntryTag.info)
        case let .setProfilePhoto(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: ItemListSectionId(self.section), style: .blocks, action: {
                arguments.changeProfilePhoto()
            })
        case let .groupDes(_, text):
            return ItemListMultilineInputItem(presentationData: presentationData, text: text, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_add_describe), maxLength: ItemListMultilineInputItemTextLimit(value: 1000, display: true), sectionId: ItemListSectionId(self.section), style: .blocks, textUpdated: { updatedText in
                arguments.updateDes(updatedText)
            }, tag: CreateGroupEntryTag.des, forceShowTopLine: true)
            
        case let .addGroupLabel(_, icon, title):
            
            return ItemListDisclosureItem(presentationData: presentationData, icon: icon, title: title, label: "", labelStyle: .coloredText(UIColor(rgb: 0x4B5BFF)), sectionId: ItemListSectionId(self.section), style: .blocks, disclosureStyle: .arrow, action: {
                arguments.addGroupLabel()
            })
        case let .groupLabel(_, labels):
            return TBItemListLabelsItem(presentationData: presentationData, sectionId: ItemListSectionId(self.section), style: .blocks, labels: labels) { labelEntitys in
                arguments.deleteLabelEntity(labelEntitys)
            }
        case let .labelHint(_, value):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: value, sectionId: ItemListSectionId(self.section))
            
        case let .groupLimit(_, icon, title, detialText, _):
            return ItemListDisclosureItem(presentationData: presentationData, icon: icon, title: title, label: detialText, labelStyle: .text, sectionId: ItemListSectionId(self.section), style: .blocks, disclosureStyle: .arrow, action: {
                arguments.changeLimt()
            })
        case let .limitHint(_, value):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: value, sectionId: ItemListSectionId(self.section))
            
            
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
            let imageSize = CGSize(width: 24, height: 24)
            return TBItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , labelStyle: .textLeftIcon(.imageUrl(type.icon, imageSize), imageSize , UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks) {
                arguments.changeChain()
            }
        case .conditionTokenType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , labelStyle: .coloredText(UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks) {
                arguments.changeToken()
            }
        case .conditionAddress(title: let title, address: let address):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title, attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x828282)]), text: address, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_input_tokenaddress), returnKeyType: .done, spacing: 10, tag: CreateGroupEntryTag.address, sectionId: self.section, textUpdated: {
                text in
                arguments.changeAddress(text)
            }, shouldUpdateText: { text in
                return true
            }, updatedFocus: {focus in
                arguments.updateFocus(CreateGroupEntryTag.address, focus)
            }, action: {
                arguments.endEditing()
            })
        case .conditionTokenId(title: let title, tokenId: let tokenId):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: title, attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x828282)]), text: tokenId, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_optional),  returnKeyType: .done, spacing: 10, tag: CreateGroupEntryTag.tokenId, sectionId: self.section, textUpdated: {
                text in
                arguments.changeTokenId(text)
            }, shouldUpdateText: { text in
                return true
            }, updatedFocus: {focus in
                arguments.updateFocus(CreateGroupEntryTag.tokenId, focus)
            }, action: {
                arguments.endEditing()
            })
        case .balanceHeader(des: let des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
        case .balanceCoinType(title: let title, type: let type):
            let imageSize = CGSize(width: 24, height: 24)
            return TBItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , labelStyle: .textLeftIcon(.imageUrl(type.icon, imageSize), imageSize , UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks) {
                arguments.changeCurrency()
            }
        case .balanceMin(min: let min):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.create_group_paynum), attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x000000)]), text: min, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_input_tokennum_min), type: .decimal, returnKeyType: .done, spacing: 10, tag: CreateGroupEntryTag.balanceMin, sectionId: self.section, textUpdated: {
                text in
                arguments.changeMinToken(text)
            }, shouldUpdateText: { text in
                if text.count == 0 {
                    return true
                }
                if text.hasPrefix(".") {
                    return false
                }
                return Decimal(string: text) != nil
            }, updatedFocus: {focus in
                arguments.updateFocus(CreateGroupEntryTag.balanceMin, focus)
            }, action: {
                arguments.endEditing()
            })
        case .balanceMax(max: let max):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string: "", attributes: [.font:UIFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor:UIColor(rgb: 0x000000)]), text: max, placeholder: "Token",  returnKeyType: .done, spacing: 10, tag: CreateGroupEntryTag.balanceMax, sectionId: self.section, textUpdated: {
                text in
                arguments.changeMaxToken(text)
            }, shouldUpdateText: { text in
                return true
            }, updatedFocus: {focus in
                arguments.updateFocus(CreateGroupEntryTag.balanceMax, focus)
            }, action: {
                arguments.endEditing()
            })
        case let.payHeader(des: des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
            
        case let .connectWallet(title: title):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:" \(TBLanguage.sharedInstance.localizable(TBLankey.setting_connect_wallet))" , labelStyle: .coloredText(UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks) {
                arguments.connectWallet()
            }
        case .payWallet(title: let title, walletConnect: let walletConnect, wallet: let wallet):
            return TBItemListDisclosureItem(presentationData: presentationData, title: title, enabled: true, label:wallet.name , labelStyle:.textLeftIcon(.image(UIImage(bundleImageName: "Settings/wallet/icon_matamask_settings")), CGSize(width: 24, height: 24), UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks, disclosureStyle: .none) {
                
            }
        case .payChainType(title: let title, type: let type):
            let imageSize = CGSize(width: 24, height: 24)
            return TBItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , labelStyle: .textLeftIcon(.imageUrl(type.icon, imageSize), imageSize , UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks) {
                arguments.changeChain()
            }
        case .payTokenType(title: let title, type: let type):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name ,labelStyle: .coloredText(UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks) {
                arguments.changeToken()
            }
        case let .amountHeader(des: des):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: des, sectionId: self.section)
        case .amountCoinType(title: let title, type: let type):
            let imageSize = CGSize(width: 24, height: 24)
            return TBItemListDisclosureItem(presentationData: presentationData, title: title, label:type.name , labelStyle: .textLeftIcon(.imageUrl(type.icon, imageSize), imageSize , UIColor(rgb: 0x4B5BFF)), sectionId: self.section, style: .blocks) {
                arguments.changeCurrency()
            }
        case .amount(amount: let amount):
            return ItemListSingleLineInputItem(presentationData: presentationData, title: NSAttributedString(string:""), text: amount, placeholder: TBLanguage.sharedInstance.localizable(TBLankey.create_group_input_paynum), type: .decimal, returnKeyType: .done, tag: CreateGroupEntryTag.payAmout, sectionId: self.section, textUpdated: {
                text in
                arguments.changePayAmout(text)
            }, shouldUpdateText: { text in
                if text.count == 0 {
                    return true
                }
                if text.hasPrefix(".") {
                    return false
                }
                return Decimal(string: text) != nil
            }, updatedFocus: {focus in
                arguments.updateFocus(CreateGroupEntryTag.payAmout, focus)
            }, action: {
                arguments.endEditing()
            })
            
            
        case let .member(_, _, _, dateTimeFormat, nameDisplayOrder, peer, presence):
            return ItemListPeerItem(presentationData: presentationData, dateTimeFormat: dateTimeFormat, nameDisplayOrder: nameDisplayOrder, context: arguments.context, peer: EnginePeer(peer), presence: presence.flatMap(EnginePeer.Presence.init), text: .presence, label: .none, editing: ItemListPeerItemEditing(editable: false, editing: false, revealed: false), switchValue: nil, enabled: true, selectable: true, sectionId: self.section, action: nil, setPeerIdWithRevealedOptions: { _, _ in }, removePeer: { _ in })
        case let .locationHeader(_, title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .location(theme, location):
            let imageSignal = chatMapSnapshotImage(engine: arguments.context.engine, resource: MapSnapshotMediaResource(latitude: location.latitude, longitude: location.longitude, width: 90, height: 90))
            return ItemListAddressItem(theme: theme, label: "", text: location.address.replacingOccurrences(of: ", ", with: "\n"), imageSignal: imageSignal, selected: nil, sectionId: self.section, style: .blocks, action: nil)
        case let .changeLocation(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: ItemListSectionId(self.section), style: .blocks, action: {
                arguments.changeLocation()
            })
        case let .locationInfo(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .venueHeader(_, title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .venue(_, _, venue):
            return ItemListVenueItem(presentationData: presentationData, engine: arguments.context.engine, venue: venue, sectionId: self.section, style: .blocks, action: {
                arguments.updateWithVenue(venue)
            })
        }
    }
}

private struct CreateGroupState: Equatable {
    var creating: Bool
    var editingName: ItemListAvatarAndNameInfoItemName
    var nameSetFromVenue: Bool
    var avatar: ItemListAvatarAndNameInfoItemUpdatingAvatar?
    var location: PeerGeoLocation?
    var des: String
    var tags: [TBWeb3GroupInfoEntry.Tag]
    var limitState:TBGroupLimitState
    var noLimitChainName: String?
    var noLimitChainId: String?
    
    static func ==(lhs: CreateGroupState, rhs: CreateGroupState) -> Bool {
        if lhs.creating != rhs.creating {
            return false
        }
        if lhs.editingName != rhs.editingName {
            return false
        }
        if lhs.nameSetFromVenue != rhs.nameSetFromVenue {
            return false
        }
        if lhs.avatar != rhs.avatar {
            return false
        }
        if lhs.location != rhs.location {
            return false
        }
        if lhs.des != rhs.des {
            return false
        }
        if lhs.limitState != rhs.limitState {
            return false
        }
        if !lhs.tags.elementsEqual(rhs.tags) {
            return false
        }
        return true
    }
}

private func createGroupEntries(presentationData: PresentationData, state: CreateGroupState, peerIds: [PeerId], view: MultiplePeersView, venues: [TelegramMediaMap]?) -> [CreateGroupEntry] {
    var entries: [CreateGroupEntry] = []
    
    let groupInfoState = ItemListAvatarAndNameInfoItemState(editingName: state.editingName, updatingName: nil)
    
    let peer = TelegramGroup(id: PeerId(namespace: .max, id: PeerId.Id._internalFromInt64Value(0)), title: state.editingName.composedTitle, photo: [], participantCount: 0, role: .creator(rank: nil), membership: .Member, flags: [], defaultBannedRights: nil, migrationReference: nil, creationDate: 0, version: 0)
    
    entries.append(.groupInfo(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, peer, groupInfoState, state.avatar))
    entries.append(.groupDes(presentationData.theme, state.des))
    
    
    
    let limitState = state.limitState
    entries.append(.limitHeader(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_type)))
    entries.append(.noLimit(isSelect: limitState.groupLimit == .noLimit))
    entries.append(.conditionLimit(isSelect: limitState.groupLimit == .conditionLimit))
    entries.append(.payLimit(isSelect: limitState.groupLimit == .payLimit))
    if limitState.groupLimit != .noLimit {
        entries.append(.limitfooter(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_tips_conditions)))
    }
    
    if limitState.groupLimit == .conditionLimit {
    
        entries.append(.conditionHeader(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_conditionjoin_group)))
        if let chainType = limitState.conditionLimitState.chainType {
            entries.append(.conditionChainType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_chain_type), type: chainType))
        }
        if let tokenType = limitState.conditionLimitState.tokenType {
            entries.append(.conditionTokenType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_token_type), type: tokenType))
        }
        
        if let token = limitState.conditionLimitState.tokenType {
            if token.tokenType() == .erc_721 {
                entries.append(.balanceHeader(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_NFT_description)))
                entries.append(.conditionAddress(title: "Address", address: limitState.conditionLimitState.address))
                
                //entries.append(.conditionTokenId(title: "Token ID", tokenId: limitState.conditionLimitState.tokenId))
            }else{
                entries.append(.balanceHeader(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_conditions_described)))
                if let currency = limitState.conditionLimitState.currencyType {
                    entries.append(.balanceCoinType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_coin_type), type: currency))
                }
                entries.append(.balanceMin(min: limitState.conditionLimitState.minToken))
                
                
            }
        }
        
    } else if limitState.groupLimit == .payLimit {
        entries.append(.payHeader(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_paytojoin_group)))
        if let c = limitState.payLimitState.wallet, let wallet = c.platForm.transform(config: limitState.config)  {
            entries.append(.payWallet(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_address_title), walletConnect: c, wallet: wallet))
            if let chainType = limitState.payLimitState.chainType {
                entries.append(.payChainType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_chain_type), type: chainType))
            }
            if let tokenType = limitState.payLimitState.tokenType {
                entries.append(.payTokenType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_token_type), type: tokenType))
            }
            entries.append(.amountHeader(des: TBLanguage.sharedInstance.localizable(TBLankey.create_group_paynum)))
            if let coinType = limitState.payLimitState.coinType {
                entries.append(.amountCoinType(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_coin_type), type: coinType))
            }
            entries.append(.amount(amount: limitState.payLimitState.amount))
        }else{
            entries.append(.connectWallet(title: TBLanguage.sharedInstance.localizable(TBLankey.create_group_address_title)))
        }
    }
    
    
    
    
    var peers: [Peer] = []
    for peerId in peerIds {
        if let peer = view.peers[peerId] {
            peers.append(peer)
        }
    }
    
    peers.sort(by: { lhs, rhs in
        let lhsPresence = view.presences[lhs.id] as? TelegramUserPresence
        let rhsPresence = view.presences[rhs.id] as? TelegramUserPresence
        if let lhsPresence = lhsPresence, let rhsPresence = rhsPresence {
            if lhsPresence.status < rhsPresence.status {
                return false
            } else if lhsPresence.status > rhsPresence.status {
                return true
            } else {
                return lhs.id < rhs.id
            }
        } else if let _ = lhsPresence {
            return true
        } else if let _ = rhsPresence {
            return false
        } else {
            return lhs.id < rhs.id
        }
    })
    
    for i in 0 ..< peers.count {
        entries.append(.member(Int32(i), presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, presentationData.nameDisplayOrder, peers[i], view.presences[peers[i].id]))
    }
    
    if let location = state.location {
        entries.append(.locationHeader(presentationData.theme, presentationData.strings.Group_Location_Title.uppercased()))
        entries.append(.location(presentationData.theme, location))
        entries.append(.changeLocation(presentationData.theme, presentationData.strings.Group_Location_ChangeLocation))
        entries.append(.locationInfo(presentationData.theme, presentationData.strings.Group_Location_Info))
        
        entries.append(.venueHeader(presentationData.theme, presentationData.strings.Group_Location_CreateInThisPlace.uppercased()))
        if let venues = venues {
            if !venues.isEmpty {
                var index: Int32 = 0
                for venue in venues {
                    entries.append(.venue(index, presentationData.theme, venue))
                    index += 1
                }
            } else {
                
            }
        } else {
            
        }
    }
    
    return entries
}

public func createTBGroupControllerImpl(context: AccountContext, peerIds: [PeerId], chainName: String?, chainId: String?, initialTitle: String? = nil, mode: CreateGroupMode = .generic, completion: ((PeerId, @escaping () -> Void) -> Void)? = nil) -> ViewController {
    
    var location: PeerGeoLocation?
    if case let .locatedGroup(latitude, longitude, address) = mode {
        location = PeerGeoLocation(latitude: latitude, longitude: longitude, address: address ?? "")
    }
    
    let initialState = CreateGroupState(
        creating: false,
        editingName: .title(
            title: initialTitle ?? "",
            type: .group
        ),
        nameSetFromVenue: false,
        avatar: nil,
        location: location,
        des: "",
        tags: [TBWeb3GroupInfoEntry.Tag](),
        limitState: TBGroupLimitState(config:TBWeb3Config.shared.config ?? TBWeb3ConfigEntry() , limit: .noLimit),
        noLimitChainName: chainName,
        noLimitChainId: chainId
    )
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((CreateGroupState) -> CreateGroupState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    var replaceControllerImpl: ((ViewController) -> Void)?
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var pushImpl: ((ViewController) -> Void)?
    var endEditingImpl: (() -> Void)?
    var ensureItemVisibleImpl: ((CreateGroupEntryTag, Bool) -> Void)?
    
    let actionsDisposable = DisposableSet()
    
    let currentAvatarMixin = Atomic<TGMediaAvatarMenuMixin?>(value: nil)
    
    let uploadedAvatar = Promise<UploadedPeerPhotoData>()
    var uploadedVideoAvatar: (Promise<UploadedPeerPhotoData?>, Double?)? = nil
    
    let addressPromise = Promise<String?>(nil)
    let venuesPromise = Promise<[TelegramMediaMap]?>(nil)
    
    var avatarData:Data? = nil
    if case let .locatedGroup(latitude, longitude, address) = mode {
        if let address = address {
            addressPromise.set(.single(address))
        } else {
            addressPromise.set(reverseGeocodeLocation(latitude: latitude, longitude: longitude)
                               |> map { placemark in
                return placemark?.fullAddress ?? "\(latitude), \(longitude)"
            })
        }
        
        venuesPromise.set(nearbyVenues(context: context, latitude: latitude, longitude: longitude)
                          |> map(Optional.init))
    }
    
    let arguments = CreateGroupArguments(
        context: context,
        updateEditingName: { editingName in
            updateState { current in
                var current = current
                current.editingName = editingName
                current.nameSetFromVenue = false
                return current
            }
        },
        done: {
            let (creating, title, location, des) = stateValue.with { state -> (Bool, String, PeerGeoLocation?, String) in
                return (state.creating, state.editingName.composedTitle, state.location, state.des)
            }
            
            if !creating && !title.isEmpty {
                updateState { current in
                    var current = current
                    current.creating = true
                    return current
                }
                endEditingImpl?()
                
                
                
                let createSignal: Signal<PeerId?, CreateGroupError>
                var botPeer: Peer? = nil
                switch mode {
                case .generic:
                    createSignal  = context.engine.contacts.searchRemotePeers(query: TBAccount.shared.systemCheckData.bot_username)
                    |> mapError({ _ in
                        return CreateGroupError.generic
                    })
                    |> mapToSignal({ foundPeerTuple in
                        let (a, b) = foundPeerTuple
                        if let foundPeer = a.first{
                            botPeer = foundPeer.peer
                        }
                        if botPeer == nil {
                            if let foundPeer = b.first{
                                botPeer = foundPeer.peer
                            }
                        }
                        var fixPeerIds = peerIds
                        if let botPeer = botPeer {
                            fixPeerIds.append(botPeer.id)
                        }
                        return context.engine.peers.createGroup(title: title, peerIds: fixPeerIds)
                    })
                case .supergroup:
                    createSignal = context.engine.peers.createSupergroup(title: title, description: des)
                    |> map(Optional.init)
                    |> mapError { error -> CreateGroupError in
                        switch error {
                        case .generic:
                            return .generic
                        case .restricted:
                            return .restricted
                        case .tooMuchJoined:
                            return .tooMuchJoined
                        case .tooMuchLocationBasedGroups:
                            return .tooMuchLocationBasedGroups
                        case let .serverProvided(error):
                            return .serverProvided(error)
                        }
                    }
                case .locatedGroup:
                    guard let location = location else {
                        return
                    }
                    
                    createSignal = addressPromise.get()
                    |> castError(CreateGroupError.self)
                    |> mapToSignal { address -> Signal<PeerId?, CreateGroupError> in
                        guard let address = address else {
                            return .complete()
                        }
                        return context.engine.peers.createSupergroup(title: title, description: des, location: (location.latitude, location.longitude, address))
                        |> map(Optional.init)
                        |> mapError { error -> CreateGroupError in
                            switch error {
                            case .generic:
                                return .generic
                            case .restricted:
                                return .restricted
                            case .tooMuchJoined:
                                return .tooMuchJoined
                            case .tooMuchLocationBasedGroups:
                                return .tooMuchLocationBasedGroups
                            case let .serverProvided(error):
                                return .serverProvided(error)
                            }
                        }
                    }
                }
                
                
                actionsDisposable.add((createSignal
                                       
                                       |> mapToSignal { peerId -> Signal<PeerId?, CreateGroupError> in
                    guard let peerId = peerId else {
                        return .single(nil)
                    }
                    let updatingAvatar = stateValue.with {
                        return $0.avatar
                    }
                    if let _ = updatingAvatar {
                        return context.engine.peers.updatePeerPhoto(peerId: peerId, photo: uploadedAvatar.get(), video: uploadedVideoAvatar?.0.get(), videoStartTimestamp: uploadedVideoAvatar?.1, mapResourceToAvatarSizes: { resource, representations in
                            return mapResourceToAvatarSizes(postbox: context.account.postbox, resource: resource, representations: representations)
                        })
                        |> ignoreValues
                        |> `catch` { _ -> Signal<Never, CreateGroupError> in
                            return .complete()
                        }
                        |> mapToSignal { _ -> Signal<PeerId?, CreateGroupError> in
                        }
                        |> then(.single(peerId))
                    } else {
                        return .single(peerId)
                    }
                    
                } |> mapToSignal({ peerId -> Signal<PeerId?, CreateGroupError> in
                    if let peerId = peerId, !des.isEmpty{
                        return context.engine.peers.updatePeerDescription(peerId: peerId, description: des)
                        |> ignoreValues
                        |> `catch` { _ -> Signal<Never, CreateGroupError> in
                            return .complete()
                        }
                        |> mapToSignal { _ -> Signal<PeerId?, CreateGroupError> in
                        }
                        |> then(.single(peerId))
                    }else{
                        return .single(peerId)
                    }
                    
                }) |> mapToSignal({ peerId ->Signal<PeerId?, CreateGroupError>  in
                    if let peerId = peerId  {
                        let state = stateValue.with{$0}
                        
                        let int64PeerId =  -abs(peerId.id._internalGetInt64Value())
                        let uploadState = TBGroupLimitState.transform(
                            id:"",
                            chat_id: String(int64PeerId),
                            type: mode.transform(),
                            title: title,
                            des: des,
                            avatar: "",
                            avatarData: avatarData,
                            tags: stateValue.with{$0}.tags,
                            state: state.limitState,
                            noLimitChainName: state.noLimitChainName,
                            noLimitChainId: state.noLimitChainId
                        )
                        return TBWeb3GroupInteractor().web3UpdateGroupSignal(requestInfo:uploadState)
                        |> ignoreValues
                        |> `catch` { _ -> Signal<Never, CreateGroupError> in
                            return .complete()
                        }
                        |> mapToSignal { _ -> Signal<PeerId?, CreateGroupError> in
                        }
                        |> then(.single(peerId))
                    }else{
                        return .single(peerId)
                    }
                })
                                       |> deliverOnMainQueue
                                       |> afterDisposed {
                    Queue.mainQueue().async {
                        updateState { current in
                            var current = current
                            current.creating = false
                            return current
                        }
                    }
                }).start(next: { peerId in
                    if let peerId = peerId {
                        if let botPeer = botPeer {
                            let _ = context.engine.peers.addGroupAdmin(peerId: peerId, adminId: botPeer.id).start { _ in
                                
                            } error: { error in
                                
                            } completed: {
                                
                            }
                        }
                        if let completion = completion {
                            completion(peerId, {
                                dismissImpl?()
                            })
                        } else {
                            let controller = context.sharedContext.tb_makeChatController(context: context, chatLocation: .peer(id: peerId))
                            replaceControllerImpl?(controller)
                            Queue.mainQueue().after(0.5) { [weak controller] in
                                
                                let enqueueMessage = EnqueueMessage.message(text: "Hello world " + title, attributes: [], inlineStickers: [:], mediaReference: nil, replyToMessageId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])
                                let _ = enqueueMessages(account: context.account, peerId: peerId, messages: [enqueueMessage]).start()
                                if let controller = controller {
                                    let _  = (TBWeb3GroupInteractor().web3GroupInfoByChatIdSignal(chat_id: String(-abs(peerId.id._internalGetInt64Value()))) |> deliverOnMainQueue).start(next:{ [weak controller] groupInfo in
                                        if let groupInfo = groupInfo, let config = TBWeb3Config.shared.config, let controller = controller {
                                           let inviteController = TBInviteLinkListController(context: context, groupInfo: groupInfo, configEntry:config)
                                            controller.present(inviteController, in: .window(.root))
                                        }
                                    })
                                }
                            }
                            
                        }
                    }
                }, error: { error in
                    if case .serverProvided = error {
                        return
                    }
                    
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    let text: String?
                    switch error {
                    case .privacy:
                        text = presentationData.strings.Privacy_GroupsAndChannels_InviteToChannelMultipleError
                    case .generic:
                        text = presentationData.strings.Login_UnknownError
                    case .restricted:
                        text = presentationData.strings.Common_ActionNotAllowedError
                    case .tooMuchJoined:
                        pushImpl?(oldChannelsController(context: context, intent: .create))
                        return
                    case .tooMuchLocationBasedGroups:
                        text = presentationData.strings.CreateGroup_ErrorLocatedGroupsTooMuch
                    default:
                        text = nil
                    }
                    
                    if let text = text {
                        presentControllerImpl?(textAlertController(context: context, title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), nil)
                    }
                }))
            }
        },
        changeProfilePhoto: {
            endEditingImpl?()
            
            let title = stateValue.with { state -> String in
                return state.editingName.composedTitle
            }
            
            let _ = (context.engine.data.get(
                TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId),
                TelegramEngine.EngineData.Item.Configuration.SearchBots()
            )
                     |> deliverOnMainQueue).start(next: { peer, searchBotsConfiguration in
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                
                let legacyController = LegacyController(presentation: .custom, theme: presentationData.theme)
                legacyController.statusBar.statusBarStyle = .Ignore
                
                let emptyController = LegacyEmptyController(context: legacyController.context)!
                let navigationController = makeLegacyNavigationController(rootController: emptyController)
                navigationController.setNavigationBarHidden(true, animated: false)
                navigationController.navigationBar.transform = CGAffineTransform(translationX: -1000.0, y: 0.0)
                
                legacyController.bind(controller: navigationController)
                
                endEditingImpl?()
                presentControllerImpl?(legacyController, nil)
                
                let completedGroupPhotoImpl: (UIImage) -> Void = { image in
                    if let data = image.jpegData(compressionQuality: 0.6) {
                        avatarData = data
                        let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                        context.account.postbox.mediaBox.storeResourceData(resource.id, data: data)
                        let representation = TelegramMediaImageRepresentation(dimensions: PixelDimensions(width: 640, height: 640), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false)
                        uploadedAvatar.set(context.engine.peers.uploadedPeerPhoto(resource: resource))
                        uploadedVideoAvatar = nil
                        updateState { current in
                            var current = current
                            current.avatar = .image(representation, false)
                            return current
                        }
                    }
                }
                
                let completedGroupVideoImpl: (UIImage, Any?, TGVideoEditAdjustments?) -> Void = { image, asset, adjustments in
                    if let data = image.jpegData(compressionQuality: 0.6) {
                        let photoResource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                        context.account.postbox.mediaBox.storeResourceData(photoResource.id, data: data)
                        let representation = TelegramMediaImageRepresentation(dimensions: PixelDimensions(width: 640, height: 640), resource: photoResource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false)
                        updateState { state in
                            var state = state
                            state.avatar = .image(representation, true)
                            return state
                        }
                        
                        var videoStartTimestamp: Double? = nil
                        if let adjustments = adjustments, adjustments.videoStartValue > 0.0 {
                            videoStartTimestamp = adjustments.videoStartValue - adjustments.trimStartValue
                        }
                        
                        let signal = Signal<TelegramMediaResource?, UploadPeerPhotoError> { subscriber in
                            
                            let entityRenderer: LegacyPaintEntityRenderer? = adjustments.flatMap { adjustments in
                                if let paintingData = adjustments.paintingData, paintingData.hasAnimation {
                                    return LegacyPaintEntityRenderer(account: context.account, adjustments: adjustments)
                                } else {
                                    return nil
                                }
                            }
                            let uploadInterface = LegacyLiveUploadInterface(context: context)
                            let signal: SSignal
                            if let asset = asset as? AVAsset {
                                signal = TGMediaVideoConverter.convert(asset, adjustments: adjustments, watcher: uploadInterface, entityRenderer: entityRenderer)!
                            } else if let url = asset as? URL, let data = try? Data(contentsOf: url, options: [.mappedRead]), let image = UIImage(data: data), let entityRenderer = entityRenderer {
                                let durationSignal: SSignal = SSignal(generator: { subscriber in
                                    let disposable = (entityRenderer.duration()).start(next: { duration in
                                        subscriber.putNext(duration)
                                        subscriber.putCompletion()
                                    })
                                    
                                    return SBlockDisposable(block: {
                                        disposable.dispose()
                                    })
                                })
                                signal = durationSignal.map(toSignal: { duration -> SSignal in
                                    if let duration = duration as? Double {
                                        return TGMediaVideoConverter.renderUIImage(image, duration: duration, adjustments: adjustments, watcher: nil, entityRenderer: entityRenderer)!
                                    } else {
                                        return SSignal.single(nil)
                                    }
                                })
                                
                            } else {
                                signal = SSignal.complete()
                            }
                            
                            let signalDisposable = signal.start(next: { next in
                                if let result = next as? TGMediaVideoConversionResult {
                                    if let image = result.coverImage, let data = image.jpegData(compressionQuality: 0.7) {
                                        context.account.postbox.mediaBox.storeResourceData(photoResource.id, data: data)
                                    }
                                    
                                    if let timestamp = videoStartTimestamp {
                                        videoStartTimestamp = max(0.0, min(timestamp, result.duration - 0.05))
                                    }
                                    
                                    var value = stat()
                                    if stat(result.fileURL.path, &value) == 0 {
                                        if let data = try? Data(contentsOf: result.fileURL) {
                                            let resource: TelegramMediaResource
                                            if let liveUploadData = result.liveUploadData as? LegacyLiveUploadInterfaceResult {
                                                resource = LocalFileMediaResource(fileId: liveUploadData.id)
                                            } else {
                                                resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                                            }
                                            context.account.postbox.mediaBox.storeResourceData(resource.id, data: data, synchronous: true)
                                            subscriber.putNext(resource)
                                        }
                                    }
                                    subscriber.putCompletion()
                                }
                            }, error: { _ in
                            }, completed: nil)
                            
                            let disposable = ActionDisposable {
                                signalDisposable?.dispose()
                            }
                            
                            return ActionDisposable {
                                disposable.dispose()
                            }
                        }
                        
                        uploadedAvatar.set(context.engine.peers.uploadedPeerPhoto(resource: photoResource))
                        
                        let promise = Promise<UploadedPeerPhotoData?>()
                        promise.set(signal
                                    |> `catch` { _ -> Signal<TelegramMediaResource?, NoError> in
                            return .single(nil)
                        }
                                    |> mapToSignal { resource -> Signal<UploadedPeerPhotoData?, NoError> in
                            if let resource = resource {
                                return context.engine.peers.uploadedPeerVideo(resource: resource) |> map(Optional.init)
                            } else {
                                return .single(nil)
                            }
                        } |> afterNext { next in
                            if let next = next, next.isCompleted {
                                updateState { state in
                                    var state = state
                                    state.avatar = .image(representation, false)
                                    return state
                                }
                            }
                        })
                        uploadedVideoAvatar = (promise, videoStartTimestamp)
                    }
                }
                
                let mixin = TGMediaAvatarMenuMixin(context: legacyController.context, parentController: emptyController, hasSearchButton: true, hasDeleteButton: stateValue.with({ $0.avatar }) != nil, hasViewButton: false, personalPhoto: false, isVideo: false, saveEditedPhotos: false, saveCapturedMedia: false, signup: false)!
                let _ = currentAvatarMixin.swap(mixin)
                mixin.requestSearchController = { assetsController in
                    let controller = WebSearchController(context: context, peer: peer, chatLocation: nil, configuration: searchBotsConfiguration, mode: .avatar(initialQuery: title, completion: { result in
                        assetsController?.dismiss()
                        completedGroupPhotoImpl(result)
                    }))
                    presentControllerImpl?(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
                }
                mixin.didFinishWithImage = { image in
                    if let image = image {
                        completedGroupPhotoImpl(image)
                    }
                }
                mixin.didFinishWithVideo = { image, asset, adjustments in
                    if let image = image, let asset = asset {
                        completedGroupVideoImpl(image, asset, adjustments)
                    }
                }
                if stateValue.with({ $0.avatar }) != nil {
                    mixin.didFinishWithDelete = {
                        updateState { current in
                            var current = current
                            current.avatar = nil
                            return current
                        }
                        uploadedAvatar.set(.never())
                    }
                }
                mixin.didDismiss = { [weak legacyController] in
                    let _ = currentAvatarMixin.swap(nil)
                    legacyController?.dismiss()
                }
                let menuController = mixin.present()
                if let menuController = menuController {
                    menuController.customRemoveFromParentViewController = { [weak legacyController] in
                        legacyController?.dismiss()
                    }
                }
            })
        },
        changeLocation: {
            endEditingImpl?()
            
            let controller = LocationPickerController(context: context, mode: .pick, completion: { location, address in
                let addressSignal: Signal<String, NoError>
                if let address = address {
                    addressSignal = .single(address)
                } else {
                    addressSignal = reverseGeocodeLocation(latitude: location.latitude, longitude: location.longitude)
                    |> map { placemark in
                        if let placemark = placemark {
                            return placemark.fullAddress
                        } else {
                            return "\(location.latitude), \(location.longitude)"
                        }
                    }
                }
                
                let _ = (addressSignal
                         |> deliverOnMainQueue).start(next: { address in
                    addressPromise.set(.single(address))
                    updateState { current in
                        var current = current
                        current.location = PeerGeoLocation(latitude: location.latitude, longitude: location.longitude, address: address)
                        return current
                    }
                })
            })
            pushImpl?(controller)
        },
        updateWithVenue: { venue in
            guard let venueData = venue.venue else {
                return
            }
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            updateState { current in
                var current = current
                if current.editingName.isEmpty || current.nameSetFromVenue {
                    current.editingName = .title(title: venueData.title, type: .group)
                    current.nameSetFromVenue = true
                }
                current.location = PeerGeoLocation(latitude: venue.latitude, longitude: venue.longitude, address: presentationData.strings.Map_Locating + "\n\n")
                return current
            }
            
            let _ = (reverseGeocodeLocation(latitude: venue.latitude, longitude: venue.longitude)
                     |> map { placemark -> String in
                if let placemark = placemark {
                    return placemark.fullAddress
                } else {
                    return venueData.address ?? ""
                }
            }
                     |> deliverOnMainQueue).start(next: { address in
                addressPromise.set(.single(address))
                updateState { current in
                    var current = current
                    current.location = PeerGeoLocation(latitude: venue.latitude, longitude: venue.longitude, address: address)
                    return current
                }
            })
            ensureItemVisibleImpl?(.info, true)
        },
        updateDes: { des in
            updateState { current in
                var current = current
                current.des = des
                return current
            }
        },
        addGroupLabel: {
            let state = stateValue.with {$0}
            let controller = TBGroupLabelController(
                context: context,
                update: { tags in
                    updateState{ current in
                        var current = current
                        current.tags = tags
                        return current
                    }
                },
                initialLabels: state.tags,
                hideNetworkActivityStatus: true)
            pushImpl?(controller)
        },
        changeLimt: {
            let _ = TBWeb3Config.shared.configSignal.start(next: { config in
                if let config = config {
                    let controller = groupLimitControllerImpl(context: context, config: config, initalLimitState: stateValue.with{$0}.limitState, update:{ limitState in
                        updateState { current in
                            var current = current
                            current.limitState = limitState
                            return current
                        }
                    })
                    pushImpl?(controller)
                }
            })
        },
        deleteLabelEntity: { labelEntitys in
            updateState{ current in
                var current = current
                current.tags = labelEntitys
                return current
            }
        },
        updateFocus: { entrtyTag, focus in
            if focus {
                dispatch_after_delay(0, .main) {
                    ensureItemVisibleImpl?(entrtyTag, true)
                }
            }
        },
        updateGroupLimit: { limitType in
            updateState { current in
                var current = current
                current.limitState.groupLimit = limitType
                return current
            }
        },
        changeToken: {
            let state = stateValue.with{$0}
            let controller = tokenListControllerImpl(
                context: context,
                groupLimit: state.limitState.groupLimit,
                config: state.limitState.config,
                selectItem: state.limitState.currentSelectToken(),
                update: { item in
                    updateState{ current in
                        var current = current
                        current.limitState = TBGroupLimitState.changeSelectToken(item, state: current.limitState)
                        return current
                    }
                }
            )
            pushImpl?(controller)
        },
        changeChain: {
            let state = stateValue.with{$0}
            let controller = chainListControllerImpl(
                context: context,
                config: state.limitState.config,
                selectItem: state.limitState.currentSelectChain(),
                update: { item in
                    updateState{ current in
                        var current = current
                        current.limitState = TBGroupLimitState.changeSelectChain(item, state: current.limitState)
                        return current
                    }
                }
            )
            pushImpl?(controller)
        },
        changeCurrency: {
            let state = stateValue.with{$0}
            if let chain = state.limitState.currentSelectChain() {
                let controller = chainCurrencyListControllerImpl(
                    context: context,
                    chain: chain,
                    selectItem: state.limitState.currentSelectCurrency(),
                    update: { item in
                        updateState{ current in
                            var current = current
                            current.limitState = TBGroupLimitState.changeSelectChainCurrency(item, state: current.limitState)
                            return current
                        }
                    }
                )
                pushImpl?(controller)
            }
        },




        changeAddress: { text in
            updateState{ current in
                var current = current
                current.limitState.conditionLimitState.address = text
                return current
            }
        },
        changeTokenId: { text in
            updateState{ current in
                var current = current
                current.limitState.conditionLimitState.tokenId = text
                return current
            }
        },
        changeMinToken: { text in
            updateState{ current in
                var current = current
                current.limitState.conditionLimitState.minToken = text
                return current
            }
        },
        changeMaxToken: { text in
            updateState{ current in
                var current = current
                current.limitState.conditionLimitState.maxToken = text
                return current
            }
        },
        connectWallet: {
            TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask) { result, c in
                if let c = c, result == true {
                    updateState{ current in
                        var current = current
                        current.limitState.payLimitState.wallet = c
                        return current
                    }
                }
            }
        },
        changePayAmout: { text in
            updateState{ current in
                var current = current
                current.limitState.payLimitState.amount = text
                return current
            }
        },
        endEditing: {
            endEditingImpl?()
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), context.account.postbox.multiplePeersView(peerIds), .single(nil) |> then(addressPromise.get()), .single(nil) |> then(venuesPromise.get()))
    |> map { presentationData, state, view, address, venues -> (ItemListControllerState, (ItemListNodeState, Any)) in
        
        let rightNavigationButton: ItemListNavigationButton
        if state.creating {
            rightNavigationButton = ItemListNavigationButton(content: .none, style: .activity, enabled: true, action: {})
        } else {
            let enbale = !state.editingName.composedTitle.isEmpty && state.limitState.checkInfo() == .pass
            rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Compose_Create), style: .bold, enabled: enbale, action: {
                arguments.done()
            })
        }
        
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.Compose_NewGroupTitle), leftNavigationButton: nil, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: createGroupEntries(presentationData: presentationData, state: state, peerIds: peerIds, view: view, venues: venues), style: .blocks, focusItemTag: CreateGroupEntryTag.info)
        
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

extension CreateGroupMode {
    public func transform() -> TBWeb3Network.UpdateGroupEntry.GType {
        switch self {
        case .generic:
            return .group
        case .supergroup:
            return .supergroup
        case .locatedGroup:
            return .locatedGroup
        }
    }
}
