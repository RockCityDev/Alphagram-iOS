






import Foundation

extension TBLanguage {
    
    
    func dic_in() -> [String:String]{
        let dic:[String:String] =
        ["Login_PhoneTitle":"login Telegram account",
         "login_language_text_en":"Bahasa Inggris",
         "login_language_text_cn":"Cina (Sederhana)",
         "login_language_text_hk":"Cina Tradisional (Hong Kong)",
         "login_language_text_tw":"Cina Tradisional (Taiwan)",
         TBLankey.Comprehensive_Telegram_social:"Sosial Telegram yang Komprehensif",
         TBLankey.Comprehensive_Telegram_social1:"Mengumpulkan umpan saluran saya",
         TBLankey.Comprehensive_Telegram_social2:"Selesaikan lebih banyak dengan sedikit usaha",
         TBLankey.splash_btn_login:"Masuk dengan akun Telegram",
         TBLankey.splash_btn_register_tip:"Tidak ada akun Telegram? ",
         TBLankey.splash_btn_register:"Masuk",
         TBLankey.login_phone_view_title:"Masuk Telegram dengan nomor telepon",
         TBLankey.login_phone_view_subtitle:"Silahkan pilih kode negara Anda dan masukkan nomor telepon Anda",
         TBLankey.bot_token_login_text:"Masuk dengan Token Bot",
         TBLankey.login_see_phone_title:"Tidak ada yang bisa melihat nomor telepon saya",
         TBLankey.login_see_phone_desc:"Sangat disarankan untuk memilih ini untuk perlindungan privasi",
         TBLankey.stealth_login_title:"Aktifkan penyamaran",
         TBLankey.stealth_login_tips:"Pesan tidak akan ditandai seperti yang Anda lihat.",
         TBLankey.language_text:"Pilih bahasa",
         TBLankey.home_contact:"Kontak",
         TBLankey.home_relatedme:"Untuk Saya",
         TBLankey.home_unknown_sender:"Orang Asing",
         TBLankey.message_center_content:"Pusat Info",
         TBLankey.message_center_myjoin_group:"Grup tempat saya bergabung",
         TBLankey.message_center_archiveortop:"Arsipkan dan Sematkan",
         TBLankey.home_commontools:"Alat",
         
         TBLankey.homeoption_pop_qrcode:"Pindai",
         TBLankey.homeoption_pop_addfriend:"Kontak Baru",
         TBLankey.homeoption_pop_creategroup:"Grup Baru",
         TBLankey.homeoption_pop_createchannel:"Saluran Baru",
         TBLankey.homeoption_pop_encryptedchat:"Mulai obrolan Rahasia",
         
         
         TBLankey.dialog_clean_tv_cancel:"Cancelar",
         TBLankey.dialog_clean_tv_ok:"Claro",
         TBLankey.dialog_clean_all:"¿Marcar todo como leído?",
             
         TBLankey.view_home_message_folder:"Folder Obrolan",
         
         
         TBLankey.launch_guide_v1_1:"Self-Oriented Chat Folders",
         TBLankey.launch_guide_v1_2:"Terjemahkan dengan satu klik",
         TBLankey.launch_guide_v1_3:"Safe Encrypted Chats",
         
         
         TBLankey.setting_my_wallet : "dompet digital saya", 
         TBLankey.setting_my_nft_avatar : "Edit Avatar NFT", 
         TBLankey.setting_connect_wallet: "hubungkan dompet", 
         TBLankey.setting_go_to_setting : "pergi ke pengaturan", 
         TBLankey.setting_connected : "terhubung", 
         TBLankey.setting_select_nft_avatar: "Pilih avatar NFT Anda", 
         TBLankey.setting_use_NFTs_in_your_wallet:"Gunakan NFT di dompet Anda",
         TBLankey.setting_Please_install_the_wallet_before_connecting:"Silakan instal dompet sebelum menghubungkan", 
         TBLankey.setting_Please_connect_the_wallet_first:"Silakan hubungkan dompet terlebih dahulu", 
         TBLankey.setting_there_is_no_nft_in_wallet:"Saat ini tidak ada NFT di dompet untuk dipilih",
         TBLankey.setting_Downloading_original_image_please_wait:"Mengunduh gambar asli, harap tunggu...",
         
         TBLankey.setting_Do_you_want_to_disconnect_the_wallet:"Apakah Anda ingin memutuskan dompet?", 
         
         TBLankey.setting_commontools : "Alat",
         TBLankey.setting_privacy_setting : "pengaturan Privasi",
         TBLankey.setting_incognito_settings : "Pengaturan penyamaran",
         TBLankey.setting_not_show_phone_in_my_interface : "Nomor telepon tidak muncul di antarmuka saya",
         TBLankey.setting_No_read_receipt : "Tidak ada tanda terima baca",
         TBLankey.setting_No_read_receipt_des : "Jangan tunjukkan tanda baca ke pihak lain setelah membaca pesan",
         TBLankey.setting_Online_status_is_not_displayed : "Status online tidak ditampilkan",
         TBLankey.setting_Online_status_is_not_displayed_des : "Online tidak menunjukkan waktu online",
         TBLankey.settings_AddAnotherAccount_Help : "Anda dapat menambahkan hingga 3 akun berbeda", 
         
         
         TBLankey.commontools_scan_qrcode : "Pindai kode QR",  
         TBLankey.commontools_add_friend : "Undang Teman", 
         TBLankey.commontools_resource_navigation : "Panduan Sumber Daya", 
         TBLankey.commontools_group_recommend : "Rekomendasi Grup", 
         TBLankey.commontools_channel_recommend : "Rekomendasi Saluran", 
         TBLankey.commontools_official_group_ch : "Grup Resmi", 
         TBLankey.commontools_official_group_ex : "Grup Resmi", 
         
         TBLankey.commontools_oneclick_cleanup : "Bersihkan sekarang", 
         TBLankey.commontools_local_cache_size_tips : "penyimpanan digunakan", 
         
         
         TBLankey.ac_title_storage_clean : "Bersihkan Cache", 
         
         
         TBLankey.user_personal_message : "Pesan",
         TBLankey.user_personal_voice : "Suara",
         TBLankey.user_personal_video : "Video",
         TBLankey.user_personal_secret_chat : "Obrolan Singkat",
         TBLankey.user_personal_add_friend : "Tambahkan Teman",
         TBLankey.user_personal_edit_friend : "Edit",
         TBLankey.user_personal_main_page : "Beranda",
         TBLankey.user_personal_introduction : "Profil",
         TBLankey.user_personal_common_group : "Grup yang sama",
         TBLankey.user_personal_msg_num : "mengirim %d pesan di grup ini",
         TBLankey.user_personal_last_msg_date : "Terakhir dikirim adalah\t ",
         TBLankey.user_personal_online_time : "Online terakhir adalah",
         TBLankey.fg_textview_expand : "Terbuka",
         TBLankey.fg_textview_collapse : "Lipat",
         
         
         TBLankey.translate_setting_title : "Setelan Terjemahan",
         TBLankey.translate_language_auto : "Deteksi bahasa",
         TBLankey.translate_switch_title : "Gelembung ucapan untuk diterjemahkan",
         TBLankey.translate_switch_info : "Tampilkan gelembung terjemahan cepat di sebelah kanan setiap pesan",
         TBLankey.translate_dialog_close : "Konfirmasi",
        ]
        
        return dic
    }
    
}
