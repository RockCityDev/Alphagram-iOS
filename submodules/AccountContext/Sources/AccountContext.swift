import Foundation
import UIKit
import AsyncDisplayKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import SwiftSignalKit
import AsyncDisplayKit
import Display
import DeviceLocationManager
import TemporaryCachedPeerDataManager
import MeshAnimationCache
import InAppPurchaseManager
import AnimationCache
import MultiAnimationRenderer

public final class TelegramApplicationOpenUrlCompletion {
    public let completion: (Bool) -> Void
    
    public init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }
}

public enum AccessType {
    case notDetermined
    case allowed
    case denied
    case restricted
    case unreachable
}

public enum TelegramAppBuildType {
    case `internal`
    case `public`
}

public final class TelegramApplicationBindings {
    public let isMainApp: Bool
    public let appBundleId: String
    public let appBuildType: TelegramAppBuildType
    public let containerPath: String
    public let appSpecificScheme: String
    public let openUrl: (String) -> Void
    public let openUniversalUrl: (String, TelegramApplicationOpenUrlCompletion) -> Void
    public let canOpenUrl: (String) -> Bool
    public let getTopWindow: () -> UIWindow?
    public let displayNotification: (String) -> Void
    public let applicationInForeground: Signal<Bool, NoError>
    public let applicationIsActive: Signal<Bool, NoError>
    public let clearMessageNotifications: ([MessageId]) -> Void
    public let pushIdleTimerExtension: () -> Disposable
    public let openSettings: () -> Void
    public let openAppStorePage: () -> Void
    public let openSubscriptions: () -> Void
    public let registerForNotifications: (@escaping (Bool) -> Void) -> Void
    public let requestSiriAuthorization: (@escaping (Bool) -> Void) -> Void
    public let siriAuthorization: () -> AccessType
    public let getWindowHost: () -> WindowHost?
    public let presentNativeController: (UIViewController) -> Void
    public let dismissNativeController: () -> Void
    public let getAvailableAlternateIcons: () -> [PresentationAppIcon]
    public let getAlternateIconName: () -> String?
    public let requestSetAlternateIconName: (String?, @escaping (Bool) -> Void) -> Void
    public let forceOrientation: (UIInterfaceOrientation) -> Void
    
    public init(isMainApp: Bool, appBundleId: String, appBuildType: TelegramAppBuildType, containerPath: String, appSpecificScheme: String, openUrl: @escaping (String) -> Void, openUniversalUrl: @escaping (String, TelegramApplicationOpenUrlCompletion) -> Void, canOpenUrl: @escaping (String) -> Bool, getTopWindow: @escaping () -> UIWindow?, displayNotification: @escaping (String) -> Void, applicationInForeground: Signal<Bool, NoError>, applicationIsActive: Signal<Bool, NoError>, clearMessageNotifications: @escaping ([MessageId]) -> Void, pushIdleTimerExtension: @escaping () -> Disposable, openSettings: @escaping () -> Void, openAppStorePage: @escaping () -> Void, openSubscriptions: @escaping () -> Void, registerForNotifications: @escaping (@escaping (Bool) -> Void) -> Void, requestSiriAuthorization: @escaping (@escaping (Bool) -> Void) -> Void, siriAuthorization: @escaping () -> AccessType, getWindowHost: @escaping () -> WindowHost?, presentNativeController: @escaping (UIViewController) -> Void, dismissNativeController: @escaping () -> Void, getAvailableAlternateIcons: @escaping () -> [PresentationAppIcon], getAlternateIconName: @escaping () -> String?, requestSetAlternateIconName: @escaping (String?, @escaping (Bool) -> Void) -> Void, forceOrientation: @escaping (UIInterfaceOrientation) -> Void) {
        self.isMainApp = isMainApp
        self.appBundleId = appBundleId
        self.appBuildType = appBuildType
        self.containerPath = containerPath
        self.appSpecificScheme = appSpecificScheme
        self.openUrl = openUrl
        self.openUniversalUrl = openUniversalUrl
        self.canOpenUrl = canOpenUrl
        self.getTopWindow = getTopWindow
        self.displayNotification = displayNotification
        self.applicationInForeground = applicationInForeground
        self.applicationIsActive = applicationIsActive
        self.clearMessageNotifications = clearMessageNotifications
        self.pushIdleTimerExtension = pushIdleTimerExtension
        self.openSettings = openSettings
        self.openAppStorePage = openAppStorePage
        self.openSubscriptions = openSubscriptions
        self.registerForNotifications = registerForNotifications
        self.requestSiriAuthorization = requestSiriAuthorization
        self.siriAuthorization = siriAuthorization
        self.presentNativeController = presentNativeController
        self.dismissNativeController = dismissNativeController
        self.getWindowHost = getWindowHost
        self.getAvailableAlternateIcons = getAvailableAlternateIcons
        self.getAlternateIconName = getAlternateIconName
        self.requestSetAlternateIconName = requestSetAlternateIconName
        self.forceOrientation = forceOrientation
    }
}

public enum TextLinkItemActionType {
    case tap
    case longTap
}

public enum TextLinkItem {
    case url(url: String, concealed: Bool)
    case mention(String)
    case hashtag(String?, String)
}

public final class AccountWithInfo: Equatable {
    public let account: Account
    public let peer: Peer
    
    public init(account: Account, peer: Peer) {
        self.account = account
        self.peer = peer
    }
    
    public static func ==(lhs: AccountWithInfo, rhs: AccountWithInfo) -> Bool {
        if lhs.account !== rhs.account {
            return false
        }
        if !arePeersEqual(lhs.peer, rhs.peer) {
            return false
        }
        return true
    }
}

public enum OpenURLContext {
    case generic
    case chat(peerId: PeerId, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?)
}

public struct ChatAvailableMessageActionOptions: OptionSet {
    public var rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public init() {
        self.rawValue = 0
    }
    
    public static let deleteLocally = ChatAvailableMessageActionOptions(rawValue: 1 << 0)
    public static let deleteGlobally = ChatAvailableMessageActionOptions(rawValue: 1 << 1)
    public static let forward = ChatAvailableMessageActionOptions(rawValue: 1 << 2)
    public static let report = ChatAvailableMessageActionOptions(rawValue: 1 << 3)
    public static let viewStickerPack = ChatAvailableMessageActionOptions(rawValue: 1 << 4)
    public static let rateCall = ChatAvailableMessageActionOptions(rawValue: 1 << 5)
    public static let cancelSending = ChatAvailableMessageActionOptions(rawValue: 1 << 6)
    public static let unsendPersonal = ChatAvailableMessageActionOptions(rawValue: 1 << 7)
    public static let sendScheduledNow = ChatAvailableMessageActionOptions(rawValue: 1 << 8)
    public static let editScheduledTime = ChatAvailableMessageActionOptions(rawValue: 1 << 9)
    public static let externalShare = ChatAvailableMessageActionOptions(rawValue: 1 << 10)
}

public struct ChatAvailableMessageActions {
    public var options: ChatAvailableMessageActionOptions
    public var banAuthor: Peer?
    public var disableDelete: Bool
    public var isCopyProtected: Bool
    
    public init(options: ChatAvailableMessageActionOptions, banAuthor: Peer?, disableDelete: Bool, isCopyProtected: Bool) {
        self.options = options
        self.banAuthor = banAuthor
        self.disableDelete = disableDelete
        self.isCopyProtected = isCopyProtected
    }
}

public enum WallpaperUrlParameter {
    case slug(String, WallpaperPresentationOptions, [UInt32], Int32?, Int32?)
    case color(UIColor)
    case gradient([UInt32], Int32?)
}

public enum ResolvedUrlSettingsSection {
    case theme
    case devices
}

public struct ResolvedBotChoosePeerTypes: OptionSet {
    public var rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public init() {
        self.rawValue = 0
    }
    
    public static let users = ResolvedBotChoosePeerTypes(rawValue: 1)
    public static let bots = ResolvedBotChoosePeerTypes(rawValue: 2)
    public static let groups = ResolvedBotChoosePeerTypes(rawValue: 4)
    public static let channels = ResolvedBotChoosePeerTypes(rawValue: 16)
}

public struct ResolvedBotAdminRights: OptionSet {
    public var rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public init() {
        self.rawValue = 0
    }
    
    public static let changeInfo = ResolvedBotAdminRights(rawValue: 1)
    public static let postMessages = ResolvedBotAdminRights(rawValue: 2)
    public static let editMessages = ResolvedBotAdminRights(rawValue: 4)
    public static let deleteMessages = ResolvedBotAdminRights(rawValue: 16)
    public static let restrictMembers = ResolvedBotAdminRights(rawValue: 32)
    public static let inviteUsers = ResolvedBotAdminRights(rawValue: 64)
    public static let pinMessages = ResolvedBotAdminRights(rawValue: 128)
    public static let promoteMembers = ResolvedBotAdminRights(rawValue: 256)
    public static let manageVideoChats = ResolvedBotAdminRights(rawValue: 512)
    public static let canBeAnonymous = ResolvedBotAdminRights(rawValue: 1024)
    public static let manageChat = ResolvedBotAdminRights(rawValue: 2048)
    
    public var chatAdminRights: TelegramChatAdminRightsFlags? {
        var flags = TelegramChatAdminRightsFlags()
        
        if self.contains(ResolvedBotAdminRights.changeInfo) {
            flags.insert(.canChangeInfo)
        }
        if self.contains(ResolvedBotAdminRights.postMessages) {
            flags.insert(.canPostMessages)
        }
        if self.contains(ResolvedBotAdminRights.editMessages) {
            flags.insert(.canEditMessages)
        }
        if self.contains(ResolvedBotAdminRights.deleteMessages) {
            flags.insert(.canDeleteMessages)
        }
        if self.contains(ResolvedBotAdminRights.restrictMembers) {
            flags.insert(.canBanUsers)
        }
        if self.contains(ResolvedBotAdminRights.inviteUsers) {
            flags.insert(.canInviteUsers)
        }
        if self.contains(ResolvedBotAdminRights.pinMessages) {
            flags.insert(.canPinMessages)
        }
        if self.contains(ResolvedBotAdminRights.promoteMembers) {
            flags.insert(.canAddAdmins)
        }
        if self.contains(ResolvedBotAdminRights.manageVideoChats) {
            flags.insert(.canManageCalls)
        }
        if self.contains(ResolvedBotAdminRights.canBeAnonymous) {
            flags.insert(.canBeAnonymous)
        }
        
        if flags.isEmpty && !self.contains(ResolvedBotAdminRights.manageChat) {
            return nil
        }
        
        return flags
    }
}

public enum StickerPackUrlType {
    case stickers
    case emoji
}

public enum ResolvedUrl {
    case externalUrl(String)
    case urlAuth(String)
    case peer(Peer?, ChatControllerInteractionNavigateToPeer)
    case inaccessiblePeer
    case botStart(peer: Peer, payload: String)
    case groupBotStart(peerId: PeerId, payload: String, adminRights: ResolvedBotAdminRights?)
    case channelMessage(peer: Peer, messageId: MessageId, timecode: Double?)
    case replyThreadMessage(replyThreadMessage: ChatReplyThreadMessage, messageId: MessageId)
    case replyThread(messageId: MessageId)
    case stickerPack(name: String, type: StickerPackUrlType)
    case instantView(TelegramMediaWebpage, String?)
    case proxy(host: String, port: Int32, username: String?, password: String?, secret: Data?)
    case join(String)
    case localization(String)
    case confirmationCode(Int)
    case cancelAccountReset(phone: String, hash: String)
    case share(url: String?, text: String?, to: String?)
    case wallpaper(WallpaperUrlParameter)
    case theme(String)
    case settings(ResolvedUrlSettingsSection)
    case joinVoiceChat(PeerId, String?)
    case importStickers
    case startAttach(peerId: PeerId, payload: String?, choose: ResolvedBotChoosePeerTypes?)
    case invoice(slug: String, invoice: TelegramMediaInvoice)
    case premiumOffer(reference: String?)
}

public enum NavigateToChatKeepStack {
    case `default`
    case always
    case never
}

public final class ChatPeekTimeout {
    public let deadline: Int32
    public let linkData: String
    
    public init(deadline: Int32, linkData: String) {
        self.deadline = deadline
        self.linkData = linkData
    }
}

public final class ChatPeerNearbyData: Equatable {
    public static func == (lhs: ChatPeerNearbyData, rhs: ChatPeerNearbyData) -> Bool {
        return lhs.distance == rhs.distance
    }
    
    public let distance: Int32
    
    public init(distance: Int32) {
        self.distance = distance
    }
}

public final class ChatGreetingData: Equatable {
    public static func == (lhs: ChatGreetingData, rhs: ChatGreetingData) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public let uuid: UUID
    public let sticker: Signal<TelegramMediaFile?, NoError>
    
    public init(uuid: UUID, sticker: Signal<TelegramMediaFile?, NoError>) {
        self.uuid = uuid
        self.sticker = sticker
    }
}

public enum ChatSearchDomain: Equatable {
    case everything
    case members
    case member(Peer)
    
    public static func ==(lhs: ChatSearchDomain, rhs: ChatSearchDomain) -> Bool {
        switch lhs {
            case .everything:
                if case .everything = rhs {
                    return true
                } else {
                    return false
                }
            case .members:
                if case .members = rhs {
                    return true
                } else {
                    return false
                }
            case let .member(lhsPeer):
                if case let .member(rhsPeer) = rhs, lhsPeer.isEqual(rhsPeer) {
                    return true
                } else {
                    return false
                }
        }
    }
}

public enum ChatLocation: Equatable {
    case peer(id: PeerId)
    case replyThread(message: ChatReplyThreadMessage)
    case feed(id: Int32)
}

public enum ChatControllerActivateInput {
    case text
    case entityInput
}

public final class NavigateToChatControllerParams {
    public enum Location {
        case peer(EnginePeer)
        case replyThread(ChatReplyThreadMessage)
        
        public var peerId: EnginePeer.Id {
            switch self {
            case let .peer(peer):
                return peer.id
            case let .replyThread(message):
                return message.messageId.peerId
            }
        }
        
        public var threadId: Int64? {
            switch self {
            case .peer:
                return nil
            case let .replyThread(message):
                return Int64(message.messageId.id)
            }
        }
        
        public var asChatLocation: ChatLocation {
            switch self {
            case let .peer(peer):
                return .peer(id: peer.id)
            case let .replyThread(message):
                return .replyThread(message: message)
            }
        }
    }
    
    public let navigationController: NavigationController
    public let chatController: ChatController?
    public let context: AccountContext
    public let chatLocation: Location
    public let chatLocationContextHolder: Atomic<ChatLocationContextHolder?>
    public let subject: ChatControllerSubject?
    public let botStart: ChatControllerInitialBotStart?
    public let attachBotStart: ChatControllerInitialAttachBotStart?
    public let updateTextInputState: ChatTextInputState?
    public let activateInput: ChatControllerActivateInput?
    public let keepStack: NavigateToChatKeepStack
    public let useExisting: Bool
    public let useBackAnimation: Bool
    public let purposefulAction: (() -> Void)?
    public let scrollToEndIfExists: Bool
    public let activateMessageSearch: (ChatSearchDomain, String)?
    public let peekData: ChatPeekTimeout?
    public let peerNearbyData: ChatPeerNearbyData?
    public let reportReason: ReportReason?
    public let animated: Bool
    public let options: NavigationAnimationOptions
    public let parentGroupId: PeerGroupId?
    public let chatListFilter: Int32?
    public let chatNavigationStack: [PeerId]
    public let changeColors: Bool
    public let setupController: (ChatController) -> Void
    public let completion: (ChatController) -> Void



























    public init(navigationController: NavigationController, chatController: ChatController? = nil, context: AccountContext, chatLocation: Location, chatLocationContextHolder: Atomic<ChatLocationContextHolder?> = Atomic<ChatLocationContextHolder?>(value: nil), subject: ChatControllerSubject? = nil, botStart: ChatControllerInitialBotStart? = nil, attachBotStart: ChatControllerInitialAttachBotStart? = nil, updateTextInputState: ChatTextInputState? = nil, activateInput: ChatControllerActivateInput? = nil, keepStack: NavigateToChatKeepStack = .default, useExisting: Bool = true, useBackAnimation: Bool = false, purposefulAction: (() -> Void)? = nil, scrollToEndIfExists: Bool = false, activateMessageSearch: (ChatSearchDomain, String)? = nil, peekData: ChatPeekTimeout? = nil, peerNearbyData: ChatPeerNearbyData? = nil, reportReason: ReportReason? = nil, animated: Bool = true, options: NavigationAnimationOptions = [], parentGroupId: PeerGroupId? = nil, chatListFilter: Int32? = nil, chatNavigationStack: [PeerId] = [], changeColors: Bool = false, setupController: @escaping (ChatController) -> Void = { _ in }, completion: @escaping (ChatController) -> Void = { _ in }) {
        self.navigationController = navigationController
        self.chatController = chatController
        self.chatLocationContextHolder = chatLocationContextHolder
        self.context = context
        self.chatLocation = chatLocation
        self.subject = subject
        self.botStart = botStart
        self.attachBotStart = attachBotStart
        self.updateTextInputState = updateTextInputState
        self.activateInput = activateInput
        self.keepStack = keepStack
        self.useExisting = useExisting
        self.useBackAnimation = useBackAnimation
        self.purposefulAction = purposefulAction
        self.scrollToEndIfExists = scrollToEndIfExists
        self.activateMessageSearch = activateMessageSearch
        self.peekData = peekData
        self.peerNearbyData = peerNearbyData
        self.reportReason = reportReason
        self.animated = animated
        self.options = options
        self.parentGroupId = parentGroupId
        self.chatListFilter = chatListFilter
        self.chatNavigationStack = chatNavigationStack
        self.changeColors = changeColors
        self.setupController = setupController
        self.completion = completion
    }
}

public enum DeviceContactInfoSubject {
    case vcard(Peer?, DeviceContactStableId?, DeviceContactExtendedData)
    case filter(peer: Peer?, contactId: DeviceContactStableId?, contactData: DeviceContactExtendedData, completion: (Peer?, DeviceContactExtendedData) -> Void)
    case create(peer: Peer?, contactData: DeviceContactExtendedData, isSharing: Bool, shareViaException: Bool, completion: (Peer?, DeviceContactStableId, DeviceContactExtendedData) -> Void)
    
    public var peer: Peer? {
        switch self {
        case let .vcard(peer, _, _):
            return peer
        case let .filter(peer, _, _, _):
            return peer
        case .create:
            return nil
        }
    }
    
    public var contactData: DeviceContactExtendedData {
        switch self {
        case let .vcard(_, _, data):
            return data
        case let .filter(_, _, data, _):
            return data
        case let .create(_, data, _, _, _):
            return data
        }
    }
}

public enum PeerInfoControllerMode {
    case generic
    case calls(messages: [Message])
    case nearbyPeer(distance: Int32)
    case group(PeerId)
    case reaction(MessageId)
    case forumTopic(thread: ChatReplyThreadMessage)
}

public enum ContactListActionItemInlineIconPosition {
    case left
    case right
}

public enum ContactListActionItemIcon : Equatable {
    case none
    case generic(UIImage)
    case inline(UIImage, ContactListActionItemInlineIconPosition)
    
    public var image: UIImage? {
        switch self {
        case .none:
            return nil
        case let .generic(image):
            return image
        case let .inline(image, _):
            return image
        }
    }
    
    public static func ==(lhs: ContactListActionItemIcon, rhs: ContactListActionItemIcon) -> Bool {
        switch lhs {
        case .none:
            if case .none = rhs {
                return true
            } else {
                return false
            }
        case let .generic(image):
            if case .generic(image) = rhs {
                return true
            } else {
                return false
            }
        case let .inline(image, position):
            if case .inline(image, position) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}

public struct ContactListAdditionalOption: Equatable {
    public let title: String
    public let icon: ContactListActionItemIcon
    public let action: () -> Void
    public let clearHighlightAutomatically: Bool
    
    public init(title: String, icon: ContactListActionItemIcon, action: @escaping () -> Void, clearHighlightAutomatically: Bool = false) {
        self.title = title
        self.icon = icon
        self.action = action
        self.clearHighlightAutomatically = clearHighlightAutomatically
    }
    
    public static func ==(lhs: ContactListAdditionalOption, rhs: ContactListAdditionalOption) -> Bool {
        return lhs.title == rhs.title && lhs.icon == rhs.icon
    }
}

public enum ContactListPeerId: Hashable {
    case peer(PeerId)
    case deviceContact(DeviceContactStableId)
}

public enum ContactListAction: Equatable {
    case generic
    case voiceCall
    case videoCall
}

public enum ContactListPeer: Equatable {
    case peer(peer: Peer, isGlobal: Bool, participantCount: Int32?)
    case deviceContact(DeviceContactStableId, DeviceContactBasicData)
    
    public var id: ContactListPeerId {
        switch self {
        case let .peer(peer, _, _):
            return .peer(peer.id)
        case let .deviceContact(id, _):
            return .deviceContact(id)
        }
    }
    
    public var indexName: PeerIndexNameRepresentation {
        switch self {
        case let .peer(peer, _, _):
            return peer.indexName
        case let .deviceContact(_, contact):
            return .personName(first: contact.firstName, last: contact.lastName, addressNames: [], phoneNumber: "")
        }
    }
    
    public static func ==(lhs: ContactListPeer, rhs: ContactListPeer) -> Bool {
        switch lhs {
        case let .peer(lhsPeer, lhsIsGlobal, lhsParticipantCount):
            if case let .peer(rhsPeer, rhsIsGlobal, rhsParticipantCount) = rhs, lhsPeer.isEqual(rhsPeer), lhsIsGlobal == rhsIsGlobal, lhsParticipantCount == rhsParticipantCount {
                return true
            } else {
                return false
            }
        case let .deviceContact(id, contact):
            if case .deviceContact(id, contact) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}

public final class ContactSelectionControllerParams {
    public let context: AccountContext
    public let updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?
    public let autoDismiss: Bool
    public let title: (PresentationStrings) -> String
    public let options: [ContactListAdditionalOption]
    public let displayDeviceContacts: Bool
    public let displayCallIcons: Bool
    public let multipleSelection: Bool
    public let confirmation: (ContactListPeer) -> Signal<Bool, NoError>
    
    public init(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)? = nil, autoDismiss: Bool = true, title: @escaping (PresentationStrings) -> String, options: [ContactListAdditionalOption] = [], displayDeviceContacts: Bool = false, displayCallIcons: Bool = false, multipleSelection: Bool = false, confirmation: @escaping (ContactListPeer) -> Signal<Bool, NoError> = { _ in .single(true) }) {
        self.context = context
        self.updatedPresentationData = updatedPresentationData
        self.autoDismiss = autoDismiss
        self.title = title
        self.options = options
        self.displayDeviceContacts = displayDeviceContacts
        self.displayCallIcons = displayCallIcons
        self.multipleSelection = multipleSelection
        self.confirmation = confirmation
    }
}

public enum TBFlyMenu {
    case qrCode
    case newMessage
    case newFriend
    case newGroup(chainName: String?, chainId: String?)
    case newChannel
    case startSeret
    case chatQRCode
    case linkDeviceQRCode
}


public struct TBJoinGroupParams {
    public let context: AccountContext
    public let groupId: Int64
    public let tgGroupId: Int64?
    public let walletAddress:String?
    public weak var inViewController:ViewController?
    public init(context:AccountContext,
                groupId:Int64,
                tgGroupId:Int64?,
                walletAddress:String?,
                inViewController: ViewController) {
        self.context = context
        self.groupId = groupId
        self.tgGroupId = tgGroupId
        self.walletAddress = walletAddress
        self.inViewController = inViewController
    }
}


public enum ChatListSearchFilter: Equatable {
    case chats
    case topics
    case media
    case downloads
    case links
    case files
    case music
    case voice
    case peer(PeerId, Bool, String, String)
    case date(Int32?, Int32, String)
    
    public var id: Int64 {
        switch self {
            case .chats:
                return 0
            case .topics:
                return 1
            case .media:
                return 2
            case .downloads:
                return 4
            case .links:
                return 5
            case .files:
                return 6
            case .music:
                return 7
            case .voice:
                return 8
            case let .peer(peerId, _, _, _):
                return peerId.id._internalGetInt64Value()
            case let .date(_, date, _):
                return Int64(date)
        }
    }
}

#if ENABLE_WALLET
public enum OpenWalletContext {
    case generic
    case send(address: String, amount: Int64?, comment: String?)
}
#endif

public let defaultContactLabel: String = "_$!<Mobile>!$_"

public enum CreateGroupMode {
    case generic
    case supergroup
    case locatedGroup(latitude: Double, longitude: Double, address: String?)
}

public protocol AppLockContext: AnyObject {
    var invalidAttempts: Signal<AccessChallengeAttempts?, NoError> { get }
    var autolockDeadline: Signal<Int32?, NoError> { get }
    
    func lock()
    func unlock()
    func failedUnlockAttempt()
}

public protocol RecentSessionsController: AnyObject {
}

public protocol SharedAccountContext: AnyObject {
    var sharedContainerPath: String { get }
    var basePath: String { get }
    var mainWindow: Window1? { get }
    var accountManager: AccountManager<TelegramAccountManagerTypes> { get }
    var appLockContext: AppLockContext { get }
    
    var currentPresentationData: Atomic<PresentationData> { get }
    var presentationData: Signal<PresentationData, NoError> { get }
    
    var currentAutomaticMediaDownloadSettings: Atomic<MediaAutoDownloadSettings> { get }
    var automaticMediaDownloadSettings: Signal<MediaAutoDownloadSettings, NoError> { get }
    var currentAutodownloadSettings: Atomic<AutodownloadSettings> { get }
    var immediateExperimentalUISettings: ExperimentalUISettings { get }
    var currentInAppNotificationSettings: Atomic<InAppNotificationSettings> { get }
    var currentMediaInputSettings: Atomic<MediaInputSettings> { get }
    
    var applicationBindings: TelegramApplicationBindings { get }
    
    var mediaManager: MediaManager { get }
    var locationManager: DeviceLocationManager? { get }
    var callManager: PresentationCallManager? { get }
    var contactDataManager: DeviceContactDataManager? { get }
    
    var activeAccountContexts: Signal<(primary: AccountContext?, accounts: [(AccountRecordId, AccountContext, Int32)], currentAuth: UnauthorizedAccount?), NoError> { get }
    var activeAccountsWithInfo: Signal<(primary: AccountRecordId?, accounts: [AccountWithInfo]), NoError> { get }
    
    var presentGlobalController: (ViewController, Any?) -> Void { get }
    var presentCrossfadeController: () -> Void { get }
    
    func makeTempAccountContext(account: Account) -> AccountContext
    
    func updateNotificationTokensRegistration()
    func setAccountUserInterfaceInUse(_ id: AccountRecordId) -> Disposable
    func handleTextLinkAction(context: AccountContext, peerId: PeerId?, navigateDisposable: MetaDisposable, controller: ViewController, action: TextLinkItemActionType, itemLink: TextLinkItem)
    func openSearch(filter: ChatListSearchFilter, query: String?)
    func navigateToChat(accountId: AccountRecordId, peerId: PeerId, messageId: MessageId?)
    func openChatMessage(_ params: OpenChatMessageParams) -> Bool
    func messageFromPreloadedChatHistoryViewForLocation(id: MessageId, location: ChatHistoryLocationInput, context: AccountContext, chatLocation: ChatLocation, subject: ChatControllerSubject?, chatLocationContextHolder: Atomic<ChatLocationContextHolder?>, tagMask: MessageTags?) -> Signal<(MessageIndex?, Bool), NoError>


    func makeOverlayAudioPlayerController(context: AccountContext, chatLocation: ChatLocation, type: MediaManagerPlayerType, initialMessageId: MessageId, initialOrder: MusicPlaybackSettingsOrder, playlistLocation: SharedMediaPlaylistLocation?, parentNavigationController: NavigationController?) -> ViewController & OverlayAudioPlayerController
    func makePeerInfoController(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, peer: Peer, mode: PeerInfoControllerMode, avatarInitiallyExpanded: Bool, fromChat: Bool, requestsContext: PeerInvitationImportersContext?, fromViewController: ViewController?) -> ViewController?
    func makeChannelAdminController(context: AccountContext, peerId: PeerId, adminId: PeerId, initialParticipant: ChannelParticipant) -> ViewController?
    func makeDeviceContactInfoController(context: AccountContext, subject: DeviceContactInfoSubject, completed: (() -> Void)?, cancelled: (() -> Void)?) -> ViewController
    func makePeersNearbyController(context: AccountContext) -> ViewController
    func makeComposeController(context: AccountContext) -> ViewController

    func makeChatListController(context: AccountContext, location: ChatListControllerLocation, controlsHistoryPreload: Bool, hideNetworkActivityStatus: Bool, previewing: Bool, enableDebugActions: Bool) -> ChatListController
    func makeToolsCenterController(context: AccountContext) -> ViewController
    func makeChatController(context: AccountContext, chatLocation: ChatLocation, subject: ChatControllerSubject?, botStart: ChatControllerInitialBotStart?, mode: ChatControllerPresentationMode) -> ChatController
    func makeChatMessagePreviewItem(context: AccountContext, messages: [Message], theme: PresentationTheme, strings: PresentationStrings, wallpaper: TelegramWallpaper, fontSize: PresentationFontSize, chatBubbleCorners: PresentationChatBubbleCorners, dateTimeFormat: PresentationDateTimeFormat, nameOrder: PresentationPersonNameOrder, forcedResourceStatus: FileMediaResourceStatus?, tapMessage: ((Message) -> Void)?, clickThroughMessage: (() -> Void)?, backgroundNode: ASDisplayNode?, availableReactions: AvailableReactions?, isCentered: Bool) -> ListViewItem
    func makeChatMessageDateHeaderItem(context: AccountContext, timestamp: Int32, theme: PresentationTheme, strings: PresentationStrings, wallpaper: TelegramWallpaper, fontSize: PresentationFontSize, chatBubbleCorners: PresentationChatBubbleCorners, dateTimeFormat: PresentationDateTimeFormat, nameOrder: PresentationPersonNameOrder) -> ListViewItemHeader
    func makePeerSharedMediaController(context: AccountContext, peerId: PeerId) -> ViewController?
    func makeContactSelectionController(_ params: ContactSelectionControllerParams) -> ContactSelectionController
    func makeContactMultiselectionController(_ params: ContactMultiselectionControllerParams) -> ContactMultiselectionController
    func makePeerSelectionController(_ params: PeerSelectionControllerParams) -> PeerSelectionController
    func makeProxySettingsController(context: AccountContext) -> ViewController
    func makeLocalizationListController(context: AccountContext) -> ViewController
    func makeCreateGroupController(context: AccountContext, peerIds: [PeerId], initialTitle: String?, mode: CreateGroupMode, completion: ((PeerId, @escaping () -> Void) -> Void)?) -> ViewController
    func makeTBCreateGroupController(context: AccountContext, peerIds: [PeerId], chainName: String?, chainId: String?, initialTitle: String?, mode: CreateGroupMode, completion: ((PeerId, @escaping () -> Void) -> Void)?) -> ViewController
    func makeChatRecentActionsController(context: AccountContext, peer: Peer, adminPeerId: PeerId?) -> ViewController
    func makePrivacyAndSecurityController(context: AccountContext) -> ViewController
    func navigateToChatController(_ params: NavigateToChatControllerParams)
    func navigateToForumChannel(context: AccountContext, peerId: EnginePeer.Id, navigationController: NavigationController)
    func navigateToForumThread(context: AccountContext, peerId: EnginePeer.Id, threadId: Int64, messageId: EngineMessage.Id?,  navigationController: NavigationController, activateInput: ChatControllerActivateInput?, keepStack: NavigateToChatKeepStack) -> Signal<Never, NoError>
    func chatControllerForForumThread(context: AccountContext, peerId: EnginePeer.Id, threadId: Int64) -> Signal<ChatController, NoError>
    func openStorageUsage(context: AccountContext)
    func openLocationScreen(context: AccountContext, messageId: MessageId, navigationController: NavigationController)
    func openExternalUrl(context: AccountContext, urlContext: OpenURLContext, url: String, forceExternal: Bool, presentationData: PresentationData, navigationController: NavigationController?, dismissInput: @escaping () -> Void)
    func chatAvailableMessageActions(engine: TelegramEngine, accountPeerId: EnginePeer.Id, messageIds: Set<EngineMessage.Id>) -> Signal<ChatAvailableMessageActions, NoError>
    func chatAvailableMessageActions(engine: TelegramEngine, accountPeerId: EnginePeer.Id, messageIds: Set<EngineMessage.Id>, messages: [EngineMessage.Id: EngineMessage], peers: [EnginePeer.Id: EnginePeer]) -> Signal<ChatAvailableMessageActions, NoError>
    func resolveUrl(context: AccountContext, peerId: PeerId?, url: String, skipUrlAuth: Bool) -> Signal<ResolvedUrl, NoError>

    func openResolvedUrl(_ resolvedUrl: ResolvedUrl, context: AccountContext, urlContext: OpenURLContext, navigationController: NavigationController?, forceExternal: Bool, openPeer: @escaping (EnginePeer, ChatControllerInteractionNavigateToPeer) -> Void, sendFile: ((FileMediaReference) -> Void)?, sendSticker: ((FileMediaReference, UIView, CGRect) -> Bool)?, requestMessageActionUrlAuth: ((MessageActionUrlSubject) -> Void)?, joinVoiceChat: ((PeerId, String?, CachedChannelData.ActiveCall) -> Void)?, present: @escaping (ViewController, Any?) -> Void, dismissInput: @escaping () -> Void, contentContext: Any?)
    func tb_flyStartNav(type: TBFlyMenu, accountContext:AccountContext)
    func tb_tryJoinGroup(params:TBJoinGroupParams)
    func tb_makeChatController(context: AccountContext, chatLocation: ChatLocation) ->ViewController
    func openAddContact(context: AccountContext, firstName: String, lastName: String, phoneNumber: String, label: String, present: @escaping (ViewController, Any?) -> Void, pushController: @escaping (ViewController) -> Void, completed: @escaping () -> Void)
    func openAddPersonContact(context: AccountContext, peerId: PeerId, pushController: @escaping (ViewController) -> Void, present: @escaping (ViewController, Any?) -> Void)
    func presentContactsWarningSuppression(context: AccountContext, present: (ViewController, Any?) -> Void)
    func openImagePicker(context: AccountContext, completion: @escaping (UIImage) -> Void, present: @escaping (ViewController) -> Void)
    func openAddPeerMembers(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, parentController: ViewController, groupPeer: Peer, selectAddMemberDisposable: MetaDisposable, addMemberDisposable: MetaDisposable)
    
    func makeRecentSessionsController(context: AccountContext, activeSessionsContext: ActiveSessionsContext) -> ViewController & RecentSessionsController
    
    func makeChatQrCodeScreen(context: AccountContext, peer: Peer, threadId: Int64?) -> ViewController
    
    func makePremiumIntroController(context: AccountContext, source: PremiumIntroSource) -> ViewController
    
    func makeMyWebPageController(context: AccountContext, peerId: PeerId?, address: String?, isMe: Bool) -> ViewController

    func makeStickerPackScreen(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, mainStickerPack: StickerPackReference, stickerPacks: [StickerPackReference], loadedStickerPacks: [LoadedStickerPack], parentNavigationController: NavigationController?, sendSticker: ((FileMediaReference, UIView, CGRect) -> Bool)?) -> ViewController
    
    func makeProxySettingsController(sharedContext: SharedAccountContext, account: UnauthorizedAccount) -> ViewController

    func navigateToCurrentCall()
    var hasOngoingCall: ValuePromise<Bool> { get }
    var immediateHasOngoingCall: Bool { get }
    
    var hasGroupCallOnScreen: Signal<Bool, NoError> { get }
    var currentGroupCallController: ViewController? { get }
    
    func switchToAccount(id: AccountRecordId, fromSettingsController settingsController: ViewController?, withChatListController chatListController: ViewController?)
    func beginNewAuth(testingEnvironment: Bool)
}

public enum PremiumIntroSource {
    case settings
    case stickers
    case reactions
    case ads
    case upload
    case groupsAndChannels
    case pinnedChats
    case publicLinks
    case savedGifs
    case savedStickers
    case folders
    case chatsPerFolder
    case accounts
    case appIcons
    case about
    case deeplink(String?)
    case profile(PeerId)
    case emojiStatus(PeerId, Int64, TelegramMediaFile?, LoadedStickerPack?)
    case voiceToText
}

#if ENABLE_WALLET
private final class TonInstanceData {
    var config: String?
    var blockchainName: String?
    var instance: TonInstance?
}

private final class TonNetworkProxyImpl: TonNetworkProxy {
    private let network: Network
    
    init(network: Network) {
        self.network = network
    }
    
    func request(data: Data, timeout timeoutValue: Double, completion: @escaping (TonNetworkProxyResult) -> Void) -> Disposable {
        return (walletProxyRequest(network: self.network, data: data)
        |> timeout(timeoutValue, queue: .concurrentDefaultQueue(), alternate: .fail(.generic(500, "Local Timeout")))).start(next: { data in
            completion(.reponse(data))
        }, error: { error in
            switch error {
            case let .generic(_, text):
                completion(.error(text))
            }
        })
    }
}

public final class StoredTonContext {
    private let basePath: String
    private let postbox: Postbox
    private let network: Network
    public let keychain: TonKeychain
    private let currentInstance = Atomic<TonInstanceData>(value: TonInstanceData())
    
    public init(basePath: String, postbox: Postbox, network: Network, keychain: TonKeychain) {
        self.basePath = basePath
        self.postbox = postbox
        self.network = network
        self.keychain = keychain
    }
    
    public func context(config: String, blockchainName: String, enableProxy: Bool) -> TonContext {
        return self.currentInstance.with { data -> TonContext in
            if let instance = data.instance, data.config == config, data.blockchainName == blockchainName {
                return TonContext(instance: instance, keychain: self.keychain)
            } else {
                data.config = config
                let instance = TonInstance(basePath: self.basePath, config: config, blockchainName: blockchainName, proxy: enableProxy ? TonNetworkProxyImpl(network: self.network) : nil)
                data.instance = instance
                return TonContext(instance: instance, keychain: self.keychain)
            }
        }
    }
}

public final class TonContext {
    public let instance: TonInstance
    public let keychain: TonKeychain
    
    fileprivate init(instance: TonInstance, keychain: TonKeychain) {
        self.instance = instance
        self.keychain = keychain
    }
}

#endif

public protocol ComposeController: ViewController {
}

public protocol ChatLocationContextHolder: AnyObject {
}

public protocol AccountGroupCallContext: AnyObject {
}

public protocol AccountGroupCallContextCache: AnyObject {
}

public protocol AccountContext: AnyObject {
    var sharedContext: SharedAccountContext { get }
    var account: Account { get }
    var engine: TelegramEngine { get }
    
    var liveLocationManager: LiveLocationManager? { get }
    var peersNearbyManager: PeersNearbyManager? { get }
    var fetchManager: FetchManager { get }
    var prefetchManager: PrefetchManager? { get }
    var downloadedMediaStoreManager: DownloadedMediaStoreManager { get }
    var peerChannelMemberCategoriesContextsManager: PeerChannelMemberCategoriesContextsManager { get }
    var wallpaperUploadManager: WallpaperUploadManager? { get }
    var watchManager: WatchManager? { get }
    var inAppPurchaseManager: InAppPurchaseManager? { get }
    
    var currentLimitsConfiguration: Atomic<LimitsConfiguration> { get }
    var currentContentSettings: Atomic<ContentSettings> { get }
    var currentAppConfiguration: Atomic<AppConfiguration> { get }
    
    var cachedGroupCallContexts: AccountGroupCallContextCache { get }
    var meshAnimationCache: MeshAnimationCache { get }
    
    var animationCache: AnimationCache { get }
    var animationRenderer: MultiAnimationRenderer { get }
    
    var animatedEmojiStickers: [String: [StickerPackItem]] { get }
    
    var userLimits: EngineConfiguration.UserLimits { get }
    
    func storeSecureIdPassword(password: String)
    func getStoredSecureIdPassword() -> String?
    
    func chatLocationInput(for location: ChatLocation, contextHolder: Atomic<ChatLocationContextHolder?>) -> ChatLocationInput
    func chatLocationOutgoingReadState(for location: ChatLocation, contextHolder: Atomic<ChatLocationContextHolder?>) -> Signal<MessageId?, NoError>
    func chatLocationUnreadCount(for location: ChatLocation, contextHolder: Atomic<ChatLocationContextHolder?>) -> Signal<Int, NoError>
    func applyMaxReadIndex(for location: ChatLocation, contextHolder: Atomic<ChatLocationContextHolder?>, messageIndex: MessageIndex)
    
    func scheduleGroupCall(peerId: PeerId)
    func joinGroupCall(peerId: PeerId, invite: String?, requestJoinAsPeerId: ((@escaping (PeerId?) -> Void) -> Void)?, activeCall: EngineGroupCallDescription)
    func requestCall(peerId: PeerId, isVideo: Bool, completion: @escaping () -> Void)
}

public struct PremiumConfiguration {
    public static var defaultValue: PremiumConfiguration {
        return PremiumConfiguration(isPremiumDisabled: true)
    }
    
    public let isPremiumDisabled: Bool
    
    fileprivate init(isPremiumDisabled: Bool) {
        self.isPremiumDisabled = isPremiumDisabled
    }
    
    public static func with(appConfiguration: AppConfiguration) -> PremiumConfiguration {
        if let data = appConfiguration.data, let value = data["premium_purchase_blocked"] as? Bool {
            return PremiumConfiguration(isPremiumDisabled: value)
        } else {
            return .defaultValue
        }
    }
}
