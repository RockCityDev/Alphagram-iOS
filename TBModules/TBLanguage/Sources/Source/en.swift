






import Foundation

extension TBLanguage {
    
    
    func dic_en() -> [String:String]{
        let dic:[String:String] =
        ["login_language_text_en":"English",
         "login_language_text_cn":"Chinese (Simplified)",
         "login_language_text_hk":"Traditional Hong Kong",
         "login_language_text_tw":"Traditional Taiwan",
         "login_language_text_por":"Português",
         "login_language_text_baml":"Bahasa Melayu",
         "login_language_text_bain":"Bahasa Indonesia",
         "login_language_text_esp":"Español",
         TBLankey.Comprehensive_Telegram_social:"Comprehensive Telegram social",
         TBLankey.Comprehensive_Telegram_social1:"Gathering my channels feeds",
         TBLankey.Comprehensive_Telegram_social2:"Get more done with less effort",
         TBLankey.splash_btn_login:"Login with Telegram account",
         TBLankey.splash_btn_register_tip:"No Telegram account?",
         TBLankey.splash_btn_register:"Log in",
         TBLankey.login_phone_view_title:"Log in Telegram with phone number",
         TBLankey.login_phone_view_subtitle:"Please select your country code and enter your phone number",
         TBLankey.bot_token_login_text:"Login with Bot Token",
         TBLankey.login_see_phone_title:"Nobody can see my phone number",
         TBLankey.login_see_phone_desc:"Strongly suggest to select this for privacy protection",
         TBLankey.stealth_login_title:"Enable incognito",
         TBLankey.login_phone_number:"Phone number",
         TBLankey.stealth_login_tips:"The messages won\'t be marked as seen by you.",
         TBLankey.language_text:"Select a language",
         TBLankey.home_contact:"Contacts",
         TBLankey.home_relatedme:"For Me",
         TBLankey.home_unknown_sender:"Strangers",
         TBLankey.message_center_content:"Info Center",
         TBLankey.home_commontools:"Tools",
         TBLankey.message_center_myjoin_group:"Groups I joined in",
         TBLankey.message_center_archiveortop:"Archive and Pinned",
         
         
         TBLankey.homeoption_pop_qrcode:"Scan",
         TBLankey.homeoption_pop_addfriend:"New Contact",
         TBLankey.homeoption_pop_creategroup:"New Group",
         TBLankey.homeoption_pop_createchannel:"New Channel",
         TBLankey.homeoption_pop_encryptedchat:"Start Secret chat",
         
         TBLankey.login_selectCountryArea_title : "Country/Area",
         
         
         TBLankey.dialog_clean_tv_cancel:"Cancel",
         TBLankey.dialog_clean_tv_ok:"Sure",
         TBLankey.dialog_clean_all:"Mark all as read?",
         TBLankey.dialog_copy : "Copy",
         TBLankey.ac_download_text_share : "Share",
         TBLankey.view_home_message_folder:"Chat Folders",
         
         
         TBLankey.launch_guide_v1_1:"Self-Oriented Chat Folders",
         TBLankey.launch_guide_v1_2:"Translate with one click",
         TBLankey.launch_guide_v1_3:"Safe Encrypted Chats",
         
         
         TBLankey.setting_my_wallet : "My Digital Wallet", 
         TBLankey.setting_my_nft_avatar : "Edit NFT Avatar", 
         TBLankey.setting_connect_wallet: "Connect Wallet", 
         TBLankey.setting_go_to_setting : "Go To Settings", 
         TBLankey.setting_connected : "Connected", 
         TBLankey.setting_select_nft_avatar: "Choose your NFT avatar", 
         TBLankey.setting_use_NFTs_in_your_wallet:"Use NFTs in your wallet",
         TBLankey.setting_Please_install_the_wallet_before_connecting:"Please install the wallet before connecting", 
         TBLankey.setting_Please_connect_the_wallet_first:"Please connect the wallet first", 
         TBLankey.setting_there_is_no_nft_in_wallet:"There is currently no NFT in the wallet to choose from",
         TBLankey.setting_Downloading_original_image_please_wait:"Downloading original image, please wait...",
         
         TBLankey.setting_Do_you_want_to_disconnect_the_wallet:"Do you want to disconnect the wallet?", 
         
         TBLankey.setting_commontools : "Tools",
         TBLankey.setting_privacy_setting : "Privacy Setting",
         TBLankey.setting_incognito_settings : "Incognito settings",
         TBLankey.setting_not_show_phone_in_my_interface : "Phone number is not showing on my interface",
         TBLankey.setting_No_read_receipt : "No read receipt",
         TBLankey.setting_No_read_receipt_des : "Don't show the read mark to the other party after reading the message",
         TBLankey.setting_Online_status_is_not_displayed : "Online status is not displayed",
         TBLankey.setting_Online_status_is_not_displayed_des : "Online does not show online time",
         TBLankey.settings_AddAnotherAccount_Help : "You can add up to 20 different accounts", 
         
         
         TBLankey.commontools_scan_qrcode : "Scan QR-code",  
         TBLankey.commontools_add_friend : "Invite Friends", 
         TBLankey.commontools_resource_navigation : "Resource Guide", 
         TBLankey.commontools_group_recommend : "Group Recommendation", 
         TBLankey.commontools_channel_recommend : "Channel Recommendation", 
         TBLankey.commontools_official_group_ch : "Official Group", 
         TBLankey.commontools_official_group_ex : "Official Group", 
         
         TBLankey.commontools_official_channel : "Official Channel", 
         TBLankey.hot_header_media : "Media",
         TBLankey.hot_header_information : "Information",
         
         TBLankey.commontools_oneclick_cleanup : "Clean up now", 
         TBLankey.commontools_local_cache_size_tips : "storage is used", 
         
         
         TBLankey.ac_title_storage_clean : "Clean Cache", 
         
         
         TBLankey.user_personal_message : "Message",
         TBLankey.user_personal_voice : "Voice",
         TBLankey.user_personal_video : "Video",
         TBLankey.user_personal_secret_chat : "Screct Chat",
         TBLankey.user_personal_add_friend : "Add Friends",
         TBLankey.user_personal_edit_friend : "Edit",
         TBLankey.user_personal_main_page : "Home",
         TBLankey.user_personal_introduction : "Profile",
         TBLankey.user_personal_common_group : "Groups in common",
         TBLankey.user_personal_msg_num : "sent %d messages in this group",
         TBLankey.user_personal_last_msg_date : "Last sent was ",
         TBLankey.user_personal_online_time : "Last on-line was ",
         TBLankey.fg_textview_expand : "Unfold",
         TBLankey.fg_textview_collapse : "Fold",
         
         
         TBLankey.translate_setting_title : "Translate Settings",
         TBLankey.translate_language_auto : "Detect language",
         TBLankey.translate_switch_title : "Speech bubble for translating",
         TBLankey.translate_switch_info : "Show the fast translation bubble on the right of every message",
         TBLankey.translate_dialog_close : "Confirm",
         
         
         TBLankey.transfer_activity_title : "Transfer",
         TBLankey.transfer_activity_sended : "Send to",
         TBLankey.transfer_activity_search_hint : "Search for ID, Public Key (0x) or ENS",
         TBLankey.transfer_activity_recenttransactions : "Recent Transactions",
         TBLankey.transfer_activity_myfriend : "My Friends",
         TBLankey.transfer_activity_transfer_nextstep : "Next",
         TBLankey.transfer_activity_nobind_friend : "No wallet-connected friend",
         TBLankey.transfer_activity_tips : "Transaction history and valid friends are here",
         
         
         TBLankey.chat_transfer_towhotransfer:"Trasfer to %@",
         TBLankey.chat_transfer_toyoutransfer:"Transfer to you",
         
         TBLankey.chat_transfer_input_price_tips:"Enter the amount",
         TBLankey.chat_transfer_input_price_tips1:"You don\'t have enough balance",
         TBLankey.chat_transfer_wallet_balance:"Balance",
         TBLankey.chat_transfer_nextstep:"Next",
         TBLankey.chat_transfer_confirm:"Confirm",
         TBLankey.chat_transfer_back:"Back",
         TBLankey.chat_transfer_tips:"Please make sure the address is correct, to avoid assets loss",
         TBLankey.transfer_detatils_dialog_title:"Transaction Detail",
         TBLankey.transfer_detatils_dialog_goto_etherscan:"View on %@",
         
         TBLankey.transfer_detatils_dialog_status:"Status",
         TBLankey.transfer_detatils_dialog_status1:"Confirmed",
         TBLankey.transfer_detatils_dialog_num:"Amount",
         TBLankey.transfer_detatils_dialog_gasfee:"Estimated Gas Fee",
         TBLankey.transfer_detatils_dialog_totalnum:"Total Amount",
         
         TBLankey.chat_transfer_meunbind_wallet:"No connected wallet",
         TBLankey.chat_transfer_meubbind_tips:"You need to connect a wallet before transferring",
         TBLankey.chat_transfer_bind_wallet:"Connect a wallet",
         
         
         
         TBLankey.tb_tab_hot:"Hot",
         
         
         TBLankey.ac_wallet_tips : "Invalid Ethereum wallet address",
         TBLankey.ac_wallet_content : "Please key in the correct Ethereum wallet address. Cross-chain transfers are not supported for now.",
         TBLankey.ac_wallet_btn : "I understand",
         
         
         TBLankey.btn_null_function_tips : "Coming soon",
         TBLankey.wallet_home_input : "Enter the Wallet Address:0X...",
         TBLankey.wallet_home_btn : "Check",
         TBLankey.create_group_type : "Private Group Type",
         TBLankey.create_group_tips_unlimit : "Anyone is allowed to join this private group",
         TBLankey.create_group_tips_conditions : "Users are required to connect their wallet and have a certain amount of assets to join the group",
         TBLankey.create_group_tips_pay : "Users are required to connect their wallet and pay a certain amount of assets to join the group",
         TBLankey.create_group_conditions_described : "Conditions",
         TBLankey.create_group_pay_described : "Payment",
         TBLankey.create_group_address_title : "Wallet",
         TBLankey.create_group_chain_type : "Blockchain / Net",
         TBLankey.create_group_token_type : "Asset Standards",
         TBLankey.create_group_coin_type : "Coin Type",
         TBLankey.create_group_input_tokenaddress : "Enter Token Address",
         TBLankey.toast_tips_please_input_tokenaddress : "Please enter token address",
         TBLankey.group_details_invitation_title : "Group3 invitation link",
         TBLankey.group_details_invitation_tips : "Users will join the group via this link and verification",
         TBLankey.dialog_create_group_successful_addconding : "Conditions of Joining Group",
         TBLankey.dialog_create_group_successful_addpaynum : "Price of Joining Group",
         TBLankey.dialog_create_group_successful_condition_join : "Hold  %@",
         TBLankey.group_details_share_successful : "Shared successfully",
         TBLankey.wallet_failure_tips : "Invalid wallet connection, please reconnect it",
         TBLankey.group_share_content : "Group %@ sent you an invitation, welcome to join in",
         
         
         TBLankey.create_group_describe : "Group Description",
         TBLankey.create_group_add_describe : "Add Description",
         TBLankey.create_group_join_group : "No limits",
         TBLankey.create_group_conditionjoin_group : "Join in with conditions",
         TBLankey.create_group_paytojoin_group : "Pay to join in",
         TBLankey.create_group_input_tokennum_min : "Minimum Token",
         TBLankey.create_group_paynum : "Amount",
         TBLankey.create_group_input_paynum : "Amount of payment",
         TBLankey.create_group_link_wallet : "Connect a wallet",
         TBLankey.create_group_input_token : "Input Token ID",
         
         
         TBLankey.vip_group_title : "Coin Groups",
         TBLankey.vip_group_properties : "Total Assets",
         TBLankey.vip_group_link_wallet : "Connect Wallet",
         TBLankey.vip_group_link_detail : "Assets Detail",
         TBLankey.vip_group_joined : "Joined",
         TBLankey.vip_group_created : "Created",
         TBLankey.vip_group_wating : "Verifying, please try again later",
         TBLankey.vip_group_join_null : "Joined no Group/Chanel",
         TBLankey.vip_group_crate_null : "Created no Group/Chanel",
         TBLankey.vip_group_tag_all : "All",
         TBLankey.group_pay_join_tag_title : "Group Tags",
         TBLankey.group_pay_join_amount_title : "Entry price",
         TBLankey.group_pay_join_pay_join : "Pay to join in",
         TBLankey.group_pay_confirm_title : "Confirm",
         TBLankey.group_pay_confirm_permit_title : "Permit to join in",
         TBLankey.group_pay_confirm_pay_member_count : "%d have paid",
         TBLankey.group_pay_confirm_status_title : "Status",
         TBLankey.group_pay_confirm_pay_off : "Wait to pay",
         TBLankey.group_pay_confirm_pay_fail : "failed to pay",
         TBLankey.group_pay_confirm_pay_continue : "Continue to pay",
         TBLankey.group_pay_confirm_pay_on : "Paid? Contact the Client Service",
         TBLankey.group_pay_confirm_pay_success : "Succeeded",
         TBLankey.group_pay_confirm_pay_confirm : "Confirm to pay",
         TBLankey.group_pay_confirm_paying : "Paying...",
         TBLankey.group_pay_confirm_pay_cancel : "Cancel",
         TBLankey.group_validate_join_tag_title : "Group tags",
         
         
         
         TBLankey.create_group_NFT_description : "NFT description",
         TBLankey.create_group_optional : "optional",
         
         
         TBLankey.asset_home_button_join : "Join",
         TBLankey.asset_home_tab_asset : "Assets",
         TBLankey.asset_home_hold : "Hold >= ",
         TBLankey.act_permissions_chat_group : "%d Members",
         TBLankey.group_validate_join_condition_join_title : "Join in with conditions",
         TBLankey.group_validate_join_condition_join : "Hold  %@ can join in",
         TBLankey.group_validate_join_join_success : "Verified,joining in",
         TBLankey.group_validate_join_validating : "Verifying...",
         TBLankey.group_validate_join_validate_join : "Verify to join in",
         TBLankey.group_validate_join_validate_cancel : "Cancel",
         TBLankey.group_validate_join_validate_not_satisfied : "The conditions of joining the group are not met, please try again",
         TBLankey.group_validate_join_validate_fail : "Fail to be authorized, please try again",
         TBLankey.uplink_verification_title : "Verifying by blockchain...",
         TBLankey.uplink_verification_text : "Verifying by blockchain",
         TBLankey.uplink_verification_content : "Join in the group automatically after verified\n in about 30s",
         TBLankey.uplink_verification_know : "I understand",
         TBLankey.group_join_authorized_signature : "Authorized signature",
         TBLankey.group_join_authorized_process : "In the process of authorization ...",
         
         
         TBLankey.wallet_home_act_contract_address_title : "Contract Address",
         TBLankey.wallet_home_act_token_id_title : "Token ID",
         TBLankey.wallet_home_act_blockchain_title : "Blockchain",
         TBLankey.wallet_home_act_token_standard_title : "Token Standards",
         TBLankey.wallet_home_act_bar_tokenid : "Token ID",
         TBLankey.wallet_home_act_bar_nft : "NFT",
         TBLankey.wallet_home_act_bar_transactionhistory : "Transaction History",
         TBLankey.wallet_home_copy_address : "The wallet address is copied",
         TBLankey.wallet_home_use_nft_avatar : "Use this NFT as the avatar display?",
        ]
        
        return dic
    }
    
}
