






import Foundation

extension TBLanguage {
    
    
    func dic_pt() -> [String:String]{
        let dic:[String:String] =
        ["Login_PhoneTitle":"login Telegram account",
         "login_language_text_en":"Inglês",
         "login_language_text_cn":"Chinês (simplificado)",
         "login_language_text_hk":"Chinês tradicional (Hong Kong)",
         "login_language_text_tw":"Chinês tradicional (Taiwan)",
         TBLankey.Comprehensive_Telegram_social:"Comprehensive Telegram social",
         TBLankey.Comprehensive_Telegram_social1:"Reunindo os feeds dos meus canais",
         TBLankey.Comprehensive_Telegram_social2:"Faça mais com menos esforço",
         TBLankey.splash_btn_login:"Login com a conta do Telegram",
         TBLankey.splash_btn_register_tip:"Nenhuma conta do Telegram? ",
         TBLankey.splash_btn_register:"Login",
         TBLankey.login_phone_view_title:"Faça login no Telegram com número de telefone",
         TBLankey.login_phone_view_subtitle:"Selecione o código do seu país e digite seu número de telefone",
         TBLankey.bot_token_login_text:"Login com Bot Token",
         TBLankey.login_see_phone_title:"Ninguém pode ver meu número de telefone",
         TBLankey.login_see_phone_desc:"Sugiro fortemente selecionar isso para proteção de privacidade",
         TBLankey.stealth_login_title:"Ativar navegação anônima",
         TBLankey.stealth_login_tips:"As mensagens não serão marcadas como vistas por você.",
         TBLankey.language_text:"Selecione um idioma",
         TBLankey.home_contact:"Contatos",
         TBLankey.home_relatedme:"Para mim",
         TBLankey.home_unknown_sender:"Estranhos",
         TBLankey.message_center_content:"Centro de informações",
         TBLankey.message_center_myjoin_group:"Grupos dos quais participei",
         TBLankey.message_center_archiveortop:"Arquivar e Fixar",
         TBLankey.home_commontools:"Ferramentas",
         
         
         TBLankey.homeoption_pop_qrcode:"Verificar",
         TBLankey.homeoption_pop_addfriend:"Novo contato",
         TBLankey.homeoption_pop_creategroup:"Novo Grupo",
         TBLankey.homeoption_pop_createchannel:"Novo canal",
         TBLankey.homeoption_pop_encryptedchat:"Iniciar chat secreto",
         
         TBLankey.dialog_clean_tv_cancel:"Cancelar",
         TBLankey.dialog_clean_tv_ok:"Claro",
         TBLankey.dialog_clean_all:"Marcar tudo como lido?",
         TBLankey.view_home_message_folder:"Pastas de chat",
         
         
         TBLankey.launch_guide_v1_1:"Self-Oriented Chat Folders",
         TBLankey.launch_guide_v1_2:"Traduzir com um clique",
         TBLankey.launch_guide_v1_3:"Safe Encrypted Chats",
         
         
         TBLankey.setting_my_wallet : "minha carteira digital", 
         TBLankey.setting_my_nft_avatar : "Editar avatar NFT", 
         TBLankey.setting_connect_wallet: "conectar carteira", 
         TBLankey.setting_go_to_setting : "vá para as configurações", 
         TBLankey.setting_connected : "conectado", 
         TBLankey.setting_select_nft_avatar: "Escolha seu avatar NFT", 
         TBLankey.setting_use_NFTs_in_your_wallet:"Use NFTs em sua carteira",
         TBLankey.setting_Please_install_the_wallet_before_connecting:"Por favor, instale a carteira antes de conectar", 
         TBLankey.setting_Please_connect_the_wallet_first:"Por favor, conecte a carteira primeiro", 
         TBLankey.setting_there_is_no_nft_in_wallet:"Atualmente não há NFT na carteira para escolher",
         TBLankey.setting_Downloading_original_image_please_wait:"Baixando a imagem original, aguarde...",
         
         TBLankey.setting_Do_you_want_to_disconnect_the_wallet:"Deseja desconectar a carteira?", 
         
         TBLankey.setting_commontools : "Ferramentas",
         TBLankey.setting_privacy_setting : "configuração de privacidade",
         TBLankey.setting_incognito_settings : "Configurações de navegação anônima",
         TBLankey.setting_not_show_phone_in_my_interface : "O número de telefone não está aparecendo na minha interface",
         TBLankey.setting_No_read_receipt : "Sem recibo de leitura",
         TBLankey.setting_No_read_receipt_des : "Não mostre a marca de leitura para a outra parte depois de ler a mensagem",
         TBLankey.setting_Online_status_is_not_displayed : "O status online não é exibido",
         TBLankey.setting_Online_status_is_not_displayed_des : "Online não mostra o tempo online",
         TBLankey.settings_AddAnotherAccount_Help : "Você pode adicionar até 3 contas diferentes", 
         
         
         TBLankey.commontools_scan_qrcode : "Ler código QR",  
         TBLankey.commontools_add_friend : "Convidar amigos", 
         TBLankey.commontools_resource_navigation : "Guia de recursos", 
         TBLankey.commontools_group_recommend : "Recomendação de Grupo", 
         TBLankey.commontools_channel_recommend : "Recomendação de canal", 
         TBLankey.commontools_official_group_ch : "Grupo Oficial", 
         TBLankey.commontools_official_group_ex : "Grupo Oficial", 
         
         TBLankey.commontools_oneclick_cleanup : "Limpe agora", 
         TBLankey.commontools_local_cache_size_tips : "o armazenamento é usado", 
         
         
         TBLankey.ac_title_storage_clean : "Limpar cache", 
         
         
         TBLankey.user_personal_message : "Mensagem",
         TBLankey.user_personal_voice : "Voz",
         TBLankey.user_personal_video : "Vídeo",
         TBLankey.user_personal_secret_chat : "Chat Screct",
         TBLankey.user_personal_add_friend : "Adicionar amigos",
         TBLankey.user_personal_edit_friend : "Editar",
         TBLankey.user_personal_main_page : "Início",
         TBLankey.user_personal_introduction : "Perfil",
         TBLankey.user_personal_common_group : "Grupos em comum",
         TBLankey.user_personal_msg_num : "enviou %d mensagens neste grupo",
         TBLankey.user_personal_last_msg_date : "Último envio foi\t ",
         TBLankey.user_personal_online_time : "O último on-line foi",
         TBLankey.fg_textview_expand : "Desdobrar",
         TBLankey.fg_textview_collapse : "Dobrar",
         
         
         TBLankey.translate_setting_title : "Configurações de tradução",
         TBLankey.translate_language_auto : "Detectar idioma",
         TBLankey.translate_switch_title : "Bolha de fala para tradução",
         TBLankey.translate_switch_info : "Mostrar o balão de tradução rápida à direita de cada mensagem",
         TBLankey.translate_dialog_close : "Confirmar",
        ]
        
        return dic
    }
    
    
}
