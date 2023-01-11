






import Foundation

extension TBLanguage {
    
    
    func dic_ms() -> [String:String]{
        let dic:[String:String] =
        ["Login_PhoneTitle":"login Telegram account",
         "login_language_text_en":"Bahasa Inggeris",
         "login_language_text_cn":"Bahasa Cina (Ringkas)",
         "login_language_text_hk":"Cina Tradisional (Hong Kong)",
         "login_language_text_tw":"Cina Tradisional (Taiwan)",
         TBLankey.Comprehensive_Telegram_social:"Sosial Telegram Komprehensif",
         TBLankey.Comprehensive_Telegram_social1:"Kumpulkan suapan saluran saya",
         TBLankey.Comprehensive_Telegram_social2:"Selesaikan lebih banyak perkara dengan sedikit usaha",
         TBLankey.splash_btn_login:"Log masuk dengan akaun Telegram",
         TBLankey.splash_btn_register_tip:"Tiada akaun Telegram?",
         TBLankey.splash_btn_register:"Log masuk",
         TBLankey.login_phone_view_title:"Log masuk Telegram dengan nombor telefon",
         TBLankey.login_phone_view_subtitle:"Sila pilih kod negara anda dan masukkan nombor telefon anda",
         TBLankey.bot_token_login_text:"Log masuk dengan Token Bot",
         TBLankey.login_see_phone_title:"Tiada sesiapa boleh melihat nombor telefon saya",
         TBLankey.login_see_phone_desc:"Sangat cadangkan untuk memilih ini untuk perlindungan privasi",
         TBLankey.stealth_login_title:"Dayakan inkognito",
         TBLankey.stealth_login_tips:"Mesej tidak akan ditandakan sebagai dilihat oleh anda.",
         TBLankey.language_text:"Pilih bahasa",
         TBLankey.home_contact:"Kenalan",
         TBLankey.home_relatedme:"Untuk Saya",
         TBLankey.home_unknown_sender:"Orang asing",
         TBLankey.message_center_content:"Pusat Maklumat",
         TBLankey.message_center_myjoin_group:"Kumpulan yang saya sertai",
         TBLankey.message_center_archiveortop:"Arkib dan Disemat",
         TBLankey.home_commontools:"Alat",
         
         
         TBLankey.homeoption_pop_qrcode:"Imbas",
         TBLankey.homeoption_pop_addfriend:"Kenalan Baharu",
         TBLankey.homeoption_pop_creategroup:"Kumpulan Baharu",
         TBLankey.homeoption_pop_createchannel:"Saluran Baharu",
         TBLankey.homeoption_pop_encryptedchat:"Mulakan sembang Rahsia",
         
         
         TBLankey.dialog_clean_tv_cancel:"Batal",
         TBLankey.dialog_clean_tv_ok:"Pasti",
         TBLankey.dialog_clean_all:"Tandai semua sebagai dibaca?",
         TBLankey.view_home_message_folder:"Folder Sembang",
         
         
         TBLankey.launch_guide_v1_1:"Self-Oriented Chat Folders",
         TBLankey.launch_guide_v1_2:"Terjemah dengan satu klik",
         TBLankey.launch_guide_v1_3:"Safe Encrypted Chats",
         
         
         TBLankey.setting_my_wallet : "dompet digital saya", 
         TBLankey.setting_my_nft_avatar : "Edit Avatar NFT", 
         TBLankey.setting_connect_wallet: "sambung dompet", 
         TBLankey.setting_go_to_setting : "pergi ke tetapan", 
         TBLankey.setting_connected : "bersambung", 
         TBLankey.setting_select_nft_avatar: "Pilih avatar NFT anda", 
         TBLankey.setting_use_NFTs_in_your_wallet:"Gunakan NFT dalam dompet anda",
         TBLankey.setting_Please_install_the_wallet_before_connecting:"Sila pasang dompet sebelum menyambung", 
         TBLankey.setting_Please_connect_the_wallet_first:"Sila sambung dompet dahulu", 
         TBLankey.setting_there_is_no_nft_in_wallet:"Pada masa ini tiada NFT dalam dompet untuk dipilih",
         TBLankey.setting_Downloading_original_image_please_wait:"Memuat turun imej asal, sila tunggu...",
         
         TBLankey.setting_Do_you_want_to_disconnect_the_wallet:"Adakah anda mahu memutuskan sambungan dompet?", 
         
         TBLankey.setting_commontools : "Alat",
         TBLankey.setting_privacy_setting : "tetapan privasi",
         TBLankey.setting_incognito_settings : "Tetapan inkognito",
         TBLankey.setting_not_show_phone_in_my_interface : "Nombor telefon tidak ditunjukkan pada antara muka saya",
         TBLankey.setting_No_read_receipt : "Tiada resit baca",
         TBLankey.setting_No_read_receipt_des : "Jangan tunjukkan tanda baca kepada pihak lain selepas membaca mesej",
         TBLankey.setting_Online_status_is_not_displayed : "Status dalam talian tidak dipaparkan",
         TBLankey.setting_Online_status_is_not_displayed_des : "Dalam talian tidak menunjukkan masa dalam talian",
         TBLankey.settings_AddAnotherAccount_Help : "Anda boleh menambah sehingga 3 akaun berbeza", 
         
         TBLankey.commontools_scan_qrcode : "Imbas kod QR",  
         TBLankey.commontools_add_friend : "Jemput Rakan", 
         TBLankey.commontools_resource_navigation : "Panduan Sumber", 
         TBLankey.commontools_group_recommend : "Pengesyoran Kumpulan", 
         TBLankey.commontools_channel_recommend : "Pengesyoran Saluran", 
         TBLankey.commontools_official_group_ch : "Kumpulan Rasmi", 
         TBLankey.commontools_official_group_ex : "Kumpulan Rasmi", 
         
         TBLankey.commontools_oneclick_cleanup : "Bersihkan sekarang", 
         TBLankey.commontools_local_cache_size_tips : "storan digunakan", 
         
         
         TBLankey.ac_title_storage_clean : "Bersihkan Cache", 
         
         
         TBLankey.user_personal_message : "Mesej",
         TBLankey.user_personal_voice : "Suara",
         TBLankey.user_personal_video : "Video",
         TBLankey.user_personal_secret_chat : "Screct Chat",
         TBLankey.user_personal_add_friend : "Tambah Rakan",
         TBLankey.user_personal_edit_friend : "Edit",
         TBLankey.user_personal_main_page : "Home",
         TBLankey.user_personal_introduction : "Profil",
         TBLankey.user_personal_common_group : "Kumpulan yang sama",
         TBLankey.user_personal_msg_num : "menghantar %d mesej dalam kumpulan ini",
         TBLankey.user_personal_last_msg_date : "Terakhir dihantar ialah\t ",
         TBLankey.user_personal_online_time : "Terakhir dalam talian ialah",
         TBLankey.fg_textview_expand : "Buka",
         TBLankey.fg_textview_collapse : "Lipat",
         
         
         TBLankey.translate_setting_title : "Tetapan Terjemah",
         TBLankey.translate_language_auto : "Kesan bahasa",
         TBLankey.translate_switch_title : "Gelembung pertuturan untuk menterjemah",
         TBLankey.translate_switch_info : "Tunjukkan gelembung terjemahan pantas di sebelah kanan setiap mesej",
         TBLankey.translate_dialog_close : "Sahkan",
        ]
        
        return dic
    }
    
}
