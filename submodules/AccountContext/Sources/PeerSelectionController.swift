import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData

public struct ChatListNodePeersFilter: OptionSet {
    public var rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let onlyWriteable = ChatListNodePeersFilter(rawValue: 1 << 0)
    public static let onlyPrivateChats = ChatListNodePeersFilter(rawValue: 1 << 1)
    public static let onlyGroups = ChatListNodePeersFilter(rawValue: 1 << 2)
    public static let onlyChannels = ChatListNodePeersFilter(rawValue: 1 << 3)
    public static let onlyManageable = ChatListNodePeersFilter(rawValue: 1 << 4)
    
    public static let excludeSecretChats = ChatListNodePeersFilter(rawValue: 1 << 5)
    public static let excludeRecent = ChatListNodePeersFilter(rawValue: 1 << 6)
    public static let excludeSavedMessages = ChatListNodePeersFilter(rawValue: 1 << 7)
    
    public static let doNotSearchMessages = ChatListNodePeersFilter(rawValue: 1 << 8)
    public static let removeSearchHeader = ChatListNodePeersFilter(rawValue: 1 << 9)
    
    public static let excludeDisabled = ChatListNodePeersFilter(rawValue: 1 << 10)
    public static let includeSavedMessages = ChatListNodePeersFilter(rawValue: 1 << 11)
    
    public static let excludeChannels = ChatListNodePeersFilter(rawValue: 1 << 12)
    public static let onlyGroupsAndChannels = ChatListNodePeersFilter(rawValue: 1 << 13)
    
    public static let excludeGroups = ChatListNodePeersFilter(rawValue: 1 << 14)
    public static let excludeUsers = ChatListNodePeersFilter(rawValue: 1 << 15)
    public static let excludeBots = ChatListNodePeersFilter(rawValue: 1 << 16)
}


public final class PeerSelectionControllerParams {
    public let context: AccountContext
    public let updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?
    public let filter: ChatListNodePeersFilter
    public let forumPeerId: EnginePeer.Id?
    public let hasChatListSelector: Bool
    public let hasContactSelector: Bool
    public let hasGlobalSearch: Bool
    public let title: String?
    public let attemptSelection: ((Peer, Int64?) -> Void)?
    public let createNewGroup: (() -> Void)?
    public let pretendPresentedInModal: Bool
    public let multipleSelection: Bool
    public let forwardedMessageIds: [EngineMessage.Id]
    public let hasTypeHeaders: Bool
    
    public init(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)? = nil, filter: ChatListNodePeersFilter = [.onlyWriteable], forumPeerId: EnginePeer.Id? = nil, hasChatListSelector: Bool = true, hasContactSelector: Bool = true, hasGlobalSearch: Bool = true, title: String? = nil, attemptSelection: ((Peer, Int64?) -> Void)? = nil, createNewGroup: (() -> Void)? = nil, pretendPresentedInModal: Bool = false, multipleSelection: Bool = false, forwardedMessageIds: [EngineMessage.Id] = [], hasTypeHeaders: Bool = false) {
        self.context = context
        self.updatedPresentationData = updatedPresentationData
        self.filter = filter
        self.forumPeerId = forumPeerId
        self.hasChatListSelector = hasChatListSelector
        self.hasContactSelector = hasContactSelector
        self.hasGlobalSearch = hasGlobalSearch
        self.title = title
        self.attemptSelection = attemptSelection
        self.createNewGroup = createNewGroup
        self.pretendPresentedInModal = pretendPresentedInModal
        self.multipleSelection = multipleSelection
        self.forwardedMessageIds = forwardedMessageIds
        self.hasTypeHeaders = hasTypeHeaders
    }
}

public enum AttachmentTextInputPanelSendMode {
    case generic
    case silent
    case schedule
}

public protocol PeerSelectionController: ViewController {
    var peerSelected: ((Peer, Int64?) -> Void)? { get set }
    var multiplePeersSelected: (([Peer], [PeerId: Peer], NSAttributedString, AttachmentTextInputPanelSendMode, ChatInterfaceForwardOptionsState?) -> Void)? { get set }
    var inProgress: Bool { get set }
    var customDismiss: (() -> Void)? { get set }
}
