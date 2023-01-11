import Foundation

public protocol TrackEvent {
    
    var rawValue: TBTrackEvent.Event { get }
    
    func getRawValue() -> TBTrackEvent.Event
    
}

extension TrackEvent {
    
    public var rawValue: TBTrackEvent.Event {
        get {
            return self.getRawValue()
        }
    }
}

public class TBTrackEvent {
    
    public struct Event: Equatable {
        let key: String
        let name: String

        public init(key: String, name: String) {
            self.key = key
            self.name = name
        }
        
        public static func ==(lhs: Event, rhs: Event) -> Bool {
            if lhs.key != rhs.key {
                return false
            }
            return true
        }
    }
    
    
    
    
    public enum Logging: TrackEvent  {
        
        case first_open
        
        case start_page_show
        
        case start_button_click
        
        case register_button_click
        
        case phone_number_show
        
        case phone_number_next
        
        case check_code_show
        
        case telegram_new_user_info
        
        case chat_page_show
        
        case no_read_open
        
        case no_read_chat_open
        
        case translate_chat
        
        public func getRawValue() -> Event {
            switch self {
            case .first_open: // ("first_open"),
                return Event(key: "first_open", name: "")
            case .start_page_show:  // ("start_page_show"),
                return Event(key: "start_page_show", name: "")
            case .start_button_click:  // ("start_button_click")
                return Event(key: "start_button_click", name: "")
            case .register_button_click: //  ("register_button_click"),
                return Event(key: "register_button_click", name: "")
            case .phone_number_show: // ("phone_number_show"),
                return Event(key: "phone_number_show", name: "")
            case .phone_number_next: // ("phone_number_next"),
                return Event(key: "phone_number_next", name: "")
            case .check_code_show: // ("check_code_show"),
                return Event(key: "check_code_show", name: "")
            case .telegram_new_user_info: // Telegram("telegram_new_user_info"),
                return Event(key: "telegram_new_user_info", name: "Telegram")
            case .chat_page_show: // app("chat_page_show"),
                return Event(key: "chat_page_show", name: "app")
            case .no_read_open: 
                return Event(key: "no_read_open", name: "")
            case .no_read_chat_open: 
                return Event(key: "no_read_chat_open", name: "")
            case .translate_chat:  
                return Event(key: "translate_chat", name: "")
            }
        }
    }
    
    
    public enum HomeNav: TrackEvent {
        
        case numberclean_click
        
        case home_search_click
        
        case topbar_more_click
        
        public func getRawValue() -> Event {
            switch self {
            case .numberclean_click:
                return Event(key: "numberclean_click", name: "")
            case .home_search_click:
                return Event(key: "home_search_click", name: "")
            case .topbar_more_click:
                return Event(key: "topbar_more_click", name: "")
            }
        }
    }
    
    
    public enum Tools: TrackEvent {
        
        case friends_message_click
        
        case aboutme_click
        
        case not_contact_click
        // ("folder_add_click"),
        case folder_add_click
        
        public func getRawValue() -> Event {
            switch self {
            case .friends_message_click:
                return Event(key: "friends_message_click", name: "")
            case .aboutme_click:
                return Event(key: "aboutme_click", name: "")
            case .not_contact_click:
                return Event(key: "not_contact_click", name: "")
            case .folder_add_click:
                return Event(key: "folder_add_click", name: "")
            }
        }
        
    }
    
    
    public enum Tab: TrackEvent{
        
        case channel_tab_click 
        
        case contacts_tab_click
        
        case settings_tab_click
        
        public func getRawValue() -> Event {
            switch self {
            case .channel_tab_click:
                return Event(key: "channel_tab_click", name: "")
            case .contacts_tab_click:
                return Event(key: "contacts_tab_click", name: "")
            case .settings_tab_click:
                return Event(key: "settings_tab_click", name: "setting")
            }
        }
    }
   
    
    public enum Language: TrackEvent {
        
        case phonenumber_language_click
        
        case menu_language_click 
        
        public func getRawValue() -> Event {
            switch self {
            case .phonenumber_language_click:
                return Event(key: "phonenumber_language_click", name: "")
            case .menu_language_click:
                return Event(key: "contacts_tab_click", name: "")
            }
        }
    }
    
    
    public enum Asset: TrackEvent {
        
        case profile_tab_click
        
        case profile_tt_click
        
        case profile_oasis_click
        
        case profile_polygon_click
        
        case profile_eth_click
        
        case group_home_group_create_click
        
        case group_home_group_join_click
        
        public func getRawValue() -> Event {
            switch self {
            case .profile_tab_click:
                return Event(key: "profile_tab_click", name: "Tab")
            case .profile_tt_click:
                return Event(key: "profile_tt_click", name: "TT")
            case .profile_oasis_click:
                return Event(key: "profile_oasis_click", name: "Oasis")
            case .profile_polygon_click:
                return Event(key: "profile_polygon_click", name: "Polygon")
            case .profile_eth_click:
                return Event(key: "profile_eth_click", name: "Eth")
            case .group_home_group_create_click:
                return Event(key: "group_home_group_create_click", name: "_")
            case .group_home_group_join_click:
                return Event(key: "group_home_group_join_click", name: "_ ")
            }
        }
    }
    
    
    public enum Setting: TrackEvent {
        
        case setting_connect_wallet_click
        
        public func getRawValue() -> Event {
            switch self {
            case .setting_connect_wallet_click:
                return Event(key: "setting_connect_wallet_click", name: "_")
            }
        }
    }
    
    
    public enum Wallet: TrackEvent {
        
        case connect_wallet_metamask_click
        
        case metamask_connect_ok
        
        public func getRawValue() -> Event {
            switch self {
            case .connect_wallet_metamask_click:
                return Event(key: "connect_wallet_metamask_click", name: "_metamask")
            case .metamask_connect_ok:
                return Event(key: "metamask_connect_ok", name: "metamask")
            }
        }
    }
    
    
    public enum Transfer: TrackEvent {
        
        case user_profile_transfer
        
        case user_profile_click
        
        public func getRawValue() -> Event {
            switch self {
            case .user_profile_transfer:
                return Event(key: "user_profile_transfer", name: "_")
            case .user_profile_click:
                return Event(key: "user_profile_click", name: "_")
            }
        }
    }
    
}
