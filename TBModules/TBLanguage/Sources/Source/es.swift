






import Foundation

extension TBLanguage {
    
    
    func dic_es() -> [String:String]{
        let dic:[String:String] =
        ["Login_PhoneTitle":"login Telegram account",
         "login_language_text_en":"Inglés",
         "login_language_text_cn":"Chino (simplificado)",
         "login_language_text_hk":"Chino tradicional (Hong Kong)",
         "login_language_text_tw":"Chino tradicional (Taiwán)",
         TBLankey.Comprehensive_Telegram_social:"Comprehensive Telegram social",
         TBLankey.Comprehensive_Telegram_social1:"Recopilación de feeds de mis canales",
         TBLankey.Comprehensive_Telegram_social2:"Haga más cosas con menos esfuerzo",
         TBLankey.splash_btn_login:"Iniciar sesión con cuenta de Telegram",
         TBLankey.splash_btn_register_tip:"¿No tienes cuenta de Telegram?",
         TBLankey.splash_btn_register:"Iniciar sesión",
         TBLankey.login_phone_view_title:"Inicia sesión en Telegram con número de teléfono",
         TBLankey.login_phone_view_subtitle:"Seleccione el código de su país e ingrese su número de teléfono",
         TBLankey.bot_token_login_text:"Iniciar sesión con token de bot",
         TBLankey.login_see_phone_title:"Nadie puede ver mi número de teléfono",
         TBLankey.login_see_phone_desc:"Recomiendo encarecidamente seleccionar esto para la protección de la privacidad",
         TBLankey.stealth_login_title:"Habilitar incógnito",
         TBLankey.stealth_login_tips:"Los mensajes no se marcarán como vistos por ti.",
         TBLankey.language_text:"Seleccione un idioma",
         TBLankey.home_contact:"Contactos",
         TBLankey.home_relatedme:"Para mí",
         TBLankey.home_unknown_sender:"Extraños",
         TBLankey.message_center_content:"Centro de información",
         TBLankey.message_center_myjoin_group:"Grupos a los que me uní",
         TBLankey.message_center_archiveortop:"Archivar y anclado",
         TBLankey.home_commontools:"Herramientas",

         
         TBLankey.homeoption_pop_qrcode:"Escanear",
         TBLankey.homeoption_pop_addfriend:"Nuevo contacto",
         TBLankey.homeoption_pop_creategroup:"Nuevo grupo",
         TBLankey.homeoption_pop_createchannel:"Nuevo canal",
         TBLankey.homeoption_pop_encryptedchat:"Iniciar chat secreto",
         
         TBLankey.dialog_clean_tv_cancel:"Cancelar",
         TBLankey.dialog_clean_tv_ok:"Claro",
         TBLankey.dialog_clean_all:"¿Marcar todo como leído?",

         TBLankey.view_home_message_folder:"Carpetas de chat",
         
         
         TBLankey.launch_guide_v1_1:"Self-Oriented Chat Folders",
         TBLankey.launch_guide_v1_2:"Traducir con un clic",
         TBLankey.launch_guide_v1_3:"Safe Encrypted Chats",
         
         
         TBLankey.setting_my_wallet : "mi billetera digital", 
         TBLankey.setting_my_nft_avatar : "Editar avatar NFT", 
         TBLankey.setting_connect_wallet: "conectar billetera", 
         TBLankey.setting_go_to_setting : "ir a la configuración", 
         TBLankey.setting_connected : "conectado", 
         TBLankey.setting_select_nft_avatar: "Elige tu avatar NFT", 
         TBLankey.setting_use_NFTs_in_your_wallet:"Use NFT en su billetera",
         TBLankey.setting_Please_install_the_wallet_before_connecting:"Instale la billetera antes de conectar", 
         TBLankey.setting_Please_connect_the_wallet_first:"Primero conecte la billetera", 
         TBLankey.setting_there_is_no_nft_in_wallet:"Actualmente no hay NFT en la billetera para elegir",
         TBLankey.setting_Downloading_original_image_please_wait:"Descargando la imagen original, por favor espere...",
         
         TBLankey.setting_Do_you_want_to_disconnect_the_wallet:"¿Quieres desconectar la billetera?", 
         
         TBLankey.setting_commontools : "Herramientas",
         TBLankey.setting_privacy_setting : "configuración de privacidad",
         TBLankey.setting_incognito_settings : "Configuración de incógnito",
         TBLankey.setting_not_show_phone_in_my_interface : "El número de teléfono no aparece en mi interfaz",
         TBLankey.setting_No_read_receipt : "Sin recibo de lectura",
         TBLankey.setting_No_read_receipt_des : "No mostrar la marca de lectura a la otra parte después de leer el mensaje",
         TBLankey.setting_Online_status_is_not_displayed : "No se muestra el estado en línea",
         TBLankey.setting_Online_status_is_not_displayed_des : "En línea no muestra el tiempo en línea",
         TBLankey.settings_AddAnotherAccount_Help : "Puedes agregar hasta 3 cuentas diferentes", 
         
         
         TBLankey.commontools_scan_qrcode : "Escanear código QR",  
         TBLankey.commontools_add_friend : "Invitar amigos", 
         TBLankey.commontools_resource_navigation : "Guía de recursos", 
         TBLankey.commontools_group_recommend : "Recomendación de grupo", 
         TBLankey.commontools_channel_recommend : "Recomendación de canal", 
         TBLankey.commontools_official_group_ch : "Grupo oficial", 
         TBLankey.commontools_official_group_ex : "Grupo oficial", 
         
         TBLankey.commontools_oneclick_cleanup : "Limpiar ahora", 
         TBLankey.commontools_local_cache_size_tips : "se usa almacenamiento", 
         
         
         TBLankey.ac_title_storage_clean : "Limpiar caché", 
         
         
         TBLankey.user_personal_message : "Mensaje",
         TBLankey.user_personal_voice : "Voz",
         TBLankey.user_personal_video : "Video",
         TBLankey.user_personal_secret_chat : "Chat secreto",
         TBLankey.user_personal_add_friend : "Agregar amigos",
         TBLankey.user_personal_edit_friend : "Editar",
         TBLankey.user_personal_main_page : "Inicio",
         TBLankey.user_personal_introduction : "Perfil",
         TBLankey.user_personal_common_group : "Grupos en común",
         TBLankey.user_personal_msg_num : "envió %d mensajes en este grupo",
         TBLankey.user_personal_last_msg_date : "El último envío fue\t ",
         TBLankey.user_personal_online_time : "El último en línea fue",
         TBLankey.fg_textview_expand : "Desplegar",
         TBLankey.fg_textview_collapse : "Doblar",
         
         
         TBLankey.translate_setting_title : "Configuración de traducción",
         TBLankey.translate_language_auto : "Detectar idioma",
         TBLankey.translate_switch_title : "Bocadillo de diálogo para traducir",
         TBLankey.translate_switch_info : "Mostrar la burbuja de traducción rápida a la derecha de cada mensaje",
         TBLankey.translate_dialog_close : "Confirmar",
        ]
        
        return dic
    }
}
