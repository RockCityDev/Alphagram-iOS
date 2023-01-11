






import Foundation

extension TBLanguage {
    
    
    func dic_zh_cn() -> [String:String]{
        let dic:[String:String] =
        ["Login_PhoneTitle":"login Telegram account",
         "login_language_text_en":"English",
         "login_language_text_cn":"",
         "login_language_text_hk":"()",
         "login_language_text_tw":"()",
         TBLankey.Comprehensive_Telegram_social:"TG",
         TBLankey.Comprehensive_Telegram_social1:"",
         TBLankey.Comprehensive_Telegram_social2:"",
         TBLankey.splash_btn_login:"Telegram ",
         TBLankey.splash_btn_register_tip:"Telegram",
         TBLankey.splash_btn_register:"",
         TBLankey.login_phone_view_title:" Telegram",
         TBLankey.login_phone_view_subtitle:"",
         TBLankey.bot_token_login_text:" Bot Token ",
         TBLankey.login_see_phone_title:"",
         TBLankey.login_see_phone_desc:"",
         TBLankey.stealth_login_title:"",
         TBLankey.login_phone_number:"",
         TBLankey.stealth_login_tips:"",
         TBLankey.language_text:"",
         TBLankey.home_contact:"",
         TBLankey.home_relatedme:"",
         TBLankey.home_unknown_sender:"",
         TBLankey.message_center_content:"",
         TBLankey.message_center_myjoin_group:"",
         TBLankey.message_center_archiveortop:"",
         TBLankey.home_commontools:"",
         
         
         TBLankey.homeoption_pop_qrcode:"",
         TBLankey.homeoption_pop_addfriend:"",
         TBLankey.homeoption_pop_creategroup:"",
         TBLankey.homeoption_pop_createchannel:"",
         TBLankey.homeoption_pop_encryptedchat:"",
         
         TBLankey.login_selectCountryArea_title : "/",
         
         TBLankey.dialog_clean_tv_cancel:"",
         TBLankey.dialog_clean_tv_ok:"",
         TBLankey.dialog_clean_all:"?",
         TBLankey.dialog_copy : "",
         TBLankey.ac_download_text_share : "",
         TBLankey.view_home_message_folder : "",
         
         
         TBLankey.launch_guide_v1_1:"",
         TBLankey.launch_guide_v1_2:"",
         TBLankey.launch_guide_v1_3:"",
         
         
         TBLankey.setting_my_wallet : "", 
         TBLankey.setting_my_nft_avatar : "NFT", 
         TBLankey.setting_connect_wallet: "", 
         TBLankey.setting_go_to_setting : "", 
         TBLankey.setting_connected : "", 
         TBLankey.setting_select_nft_avatar: " NFT ", 
         TBLankey.setting_use_NFTs_in_your_wallet:"NFT",
         TBLankey.setting_Please_install_the_wallet_before_connecting:"", 
         TBLankey.setting_Please_connect_the_wallet_first:"", 
         TBLankey.setting_there_is_no_nft_in_wallet:"NFT",
         TBLankey.setting_Downloading_original_image_please_wait:" ...",
         
         TBLankey.setting_Do_you_want_to_disconnect_the_wallet:"?", 
         
         TBLankey.setting_commontools : "",
         TBLankey.setting_privacy_setting : "",
         TBLankey.setting_incognito_settings : "",
         TBLankey.setting_not_show_phone_in_my_interface : "",
         TBLankey.setting_No_read_receipt : "",
         TBLankey.setting_No_read_receipt_des : "",
         TBLankey.setting_Online_status_is_not_displayed : "",
         TBLankey.setting_Online_status_is_not_displayed_des : "",
         TBLankey.settings_AddAnotherAccount_Help : "20",
         
         TBLankey.commontools_scan_qrcode : "\nQR cord",
         TBLankey.commontools_add_friend : "",
         TBLankey.commontools_resource_navigation : "",
         TBLankey.commontools_group_recommend : "",
         TBLankey.commontools_channel_recommend : "",
         TBLankey.commontools_official_group_ch : "",
         TBLankey.commontools_official_group_ex : "",
         
         TBLankey.commontools_oneclick_cleanup : "",
         TBLankey.commontools_local_cache_size_tips : "",
         
         
         TBLankey.ac_title_storage_clean : "",
         
         
         TBLankey.user_personal_message : "",
         TBLankey.user_personal_voice : "",
         TBLankey.user_personal_video : "",
         TBLankey.user_personal_secret_chat : "",
         TBLankey.user_personal_add_friend : "",
         TBLankey.user_personal_edit_friend : "",
         TBLankey.user_personal_main_page : "",
         TBLankey.user_personal_introduction : "",
         TBLankey.user_personal_common_group : "",
         TBLankey.user_personal_msg_num : " %d ",
         TBLankey.user_personal_last_msg_date : " ",
         TBLankey.user_personal_online_time : "",
         TBLankey.fg_textview_expand : "",
         TBLankey.fg_textview_collapse : "",
         
         
         TBLankey.translate_setting_title : "",
         TBLankey.translate_language_auto : "",
         TBLankey.translate_switch_title : "",
         TBLankey.translate_switch_info : "",
         TBLankey.translate_dialog_close : "",
         
         
         TBLankey.transfer_activity_title : "",
         TBLankey.transfer_activity_sended : "",
         TBLankey.transfer_activity_search_hint : "ID (0x) ENS",
         TBLankey.transfer_activity_recenttransactions : "",
         TBLankey.transfer_activity_myfriend : "",
         TBLankey.transfer_activity_transfer_nextstep : "",
         TBLankey.transfer_activity_nobind_friend : "",
         TBLankey.transfer_activity_tips : "",
         
         TBLankey.chat_transfer_towhotransfer:"%@",
         TBLankey.chat_transfer_toyoutransfer:"",
         TBLankey.chat_transfer_input_price_tips:"",
         TBLankey.chat_transfer_input_price_tips1:"",
         TBLankey.chat_transfer_wallet_balance:"",
         TBLankey.chat_transfer_nextstep:"",
         TBLankey.chat_transfer_confirm:"",
         TBLankey.chat_transfer_back:"",
         TBLankey.chat_transfer_tips:"",
         TBLankey.transfer_detatils_dialog_title:"",
         
         TBLankey.transfer_detatils_dialog_goto_etherscan:" %@",
         TBLankey.transfer_detatils_dialog_status:"",
         TBLankey.transfer_detatils_dialog_status1:"",
         TBLankey.transfer_detatils_dialog_num:"",
         TBLankey.transfer_detatils_dialog_gasfee:"",
         TBLankey.transfer_detatils_dialog_totalnum:"",
         
         TBLankey.chat_transfer_meunbind_wallet:"",
         TBLankey.chat_transfer_meubbind_tips:"",
         TBLankey.chat_transfer_bind_wallet:"",
         
         
         TBLankey.tb_tab_hot:"",
         TBLankey.commontools_official_channel : "", 
         TBLankey.hot_header_media : "",
         TBLankey.hot_header_information : "",
         
         TBLankey.ac_wallet_tips : " Ethereum ",
         TBLankey.ac_wallet_content : " Ethereum ",
         TBLankey.ac_wallet_btn : "",
         
         
         TBLankey.btn_null_function_tips : "",
         TBLankey.wallet_home_input : "0X...",
         TBLankey.wallet_home_btn : "",
         TBLankey.create_group_type : "",
         TBLankey.create_group_tips_unlimit : "",
         TBLankey.create_group_tips_conditions : "",
         TBLankey.create_group_tips_pay : "",
         TBLankey.create_group_conditions_described : "",
         TBLankey.create_group_pay_described : "",
         TBLankey.create_group_address_title : "",
         TBLankey.create_group_chain_type : " / ",
         TBLankey.create_group_token_type : "",
         TBLankey.create_group_coin_type : "",
         TBLankey.create_group_input_tokenaddress : "",
         TBLankey.toast_tips_please_input_tokenaddress : "",
         TBLankey.group_details_invitation_title : "Group3 ",
         TBLankey.group_details_invitation_tips : "",
         TBLankey.dialog_create_group_successful_addconding : "",
         TBLankey.dialog_create_group_successful_addpaynum : "",
         TBLankey.dialog_create_group_successful_condition_join : "  %@",
         TBLankey.group_details_share_successful : "",
         TBLankey.wallet_failure_tips : "",
         TBLankey.group_share_content : "%@",
         
         
         TBLankey.create_group_describe : "",
         TBLankey.create_group_add_describe : "",
         TBLankey.create_group_join_group : "",
         TBLankey.create_group_paytojoin_group : "",
         TBLankey.create_group_conditionjoin_group : "",
         TBLankey.create_group_input_tokennum_min : "Token",
         TBLankey.create_group_paynum : "",
         TBLankey.create_group_input_paynum : "",
         TBLankey.create_group_link_wallet : "",
         TBLankey.create_group_input_token : "Token ID",
         
         
         TBLankey.vip_group_title : "",
         TBLankey.vip_group_properties : "",
         TBLankey.vip_group_link_wallet : "",
         TBLankey.vip_group_link_detail : "",
         TBLankey.vip_group_joined : "",
         TBLankey.vip_group_created : "",
         TBLankey.vip_group_wating : "",
         TBLankey.vip_group_join_null : "/",
         TBLankey.vip_group_crate_null : "/",
         TBLankey.vip_group_tag_all : "",
         TBLankey.group_pay_join_tag_title : "",
         TBLankey.group_pay_join_amount_title : "",
         TBLankey.group_pay_join_pay_join : "",
         TBLankey.group_pay_confirm_title : "",
         TBLankey.group_pay_confirm_permit_title : "",
         TBLankey.group_pay_confirm_pay_member_count : "%d ",
         TBLankey.group_pay_confirm_status_title : "",
         TBLankey.group_pay_confirm_pay_off : "",
         TBLankey.group_pay_confirm_pay_fail : "",
         TBLankey.group_pay_confirm_pay_continue : "",
         TBLankey.group_pay_confirm_pay_on : "",
         TBLankey.group_pay_confirm_pay_success : "",
         TBLankey.group_pay_confirm_pay_confirm : "",
         TBLankey.group_pay_confirm_paying : "...",
         TBLankey.group_pay_confirm_pay_cancel : "",
         TBLankey.group_validate_join_tag_title : "",
         
         
         TBLankey.create_group_NFT_description : "NFT ",
         TBLankey.create_group_optional : "",
         
         
         TBLankey.asset_home_button_join : "",
         TBLankey.asset_home_tab_asset : "",
         TBLankey.asset_home_hold : " >= ",
         TBLankey.act_permissions_chat_group : "%d ",
         TBLankey.group_validate_join_condition_join_title : "",
         TBLankey.group_validate_join_condition_join : "  %@ ",
         TBLankey.group_validate_join_join_success : "",
         TBLankey.group_validate_join_validating : "...",
         TBLankey.group_validate_join_validate_join : "",
         TBLankey.group_validate_join_validate_cancel : "",
         TBLankey.group_validate_join_validate_not_satisfied : "",
         TBLankey.group_validate_join_validate_fail : "",
         TBLankey.uplink_verification_title : "...",
         TBLankey.uplink_verification_text : "",
         TBLankey.uplink_verification_content : "\n %s",
         TBLankey.uplink_verification_know : "",
         TBLankey.group_join_authorized_signature : "",
         TBLankey.group_join_authorized_process : "...",
         
         
         TBLankey.wallet_home_act_contract_address_title : "",
         TBLankey.wallet_home_act_token_id_title : "ID",
         TBLankey.wallet_home_act_blockchain_title : "",
         TBLankey.wallet_home_act_token_standard_title : "",
         TBLankey.wallet_home_act_bar_tokenid : "",
         TBLankey.wallet_home_act_bar_nft : "NFT",
         TBLankey.wallet_home_act_bar_transactionhistory : "",
         TBLankey.wallet_home_copy_address : "",
         TBLankey.wallet_home_use_nft_avatar : " NFT ?",
        ]
        
        return dic
    }
    
}
