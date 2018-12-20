/*************************************************
*                                                * 
*          MIOLO Installation Program            *
*                                                *
*    Author: Vilson Cristiano Gartner  -         *
*            MIOLO Development Coordinator       *
*    E-mail: vgartner@univates.br                *
*                                                *
*    Date: August/2002                           *
*                                                *
*    $Id: language.h,v 1.2 2005/04/03 15:51:48 ematos Exp $
*                                                *
*************************************************/

// MIOLO Default Language: Portuguese
#define LANGUAGE "pt_BR"

// Wizard
#define CANCEL "Cancelar"
#define NEXT "Próximo >>"
#define BACK "<< Anterior"
#define FINISH "Finalizar"
#define INSTALL "Instalar"

// Page 1
#define WELCOME "Bem Vindo"
#define PAGE1_INFO "\n\n       PROGRAMA DE INSTALAÇÃO DO MIOLO\n\n\n\n\n\n                        MIOLO versão 1.0 RC4\n\n\n\n\n\n\n\nAutor: Vilson Cristiano Gärtner - vgartner@univates.br\n\nhttp://miolo.codigolivre.org.br"

// Page 2
#define FILE_PATH "Localização dos Arquivos"
#define PAGE2_INFO  "\n Informe as configurações \n de localização dos arquivos.  \n\n Todos os campos devem ser  \n informados.  \n Por padrão os arquivo são \n instalados nesses diretórios. \n\n
 Observação: É aconselhá-\n vel que você efetue a insta-\n lação utilizando o usuário\n root. Também é possível uti- \n lizar outro usuário, mas lem-\n bre que será necessário ter\n permissão de gravação nos\n diretórios."
#define LBL_MODULES " Módulos: "
#define LBL_THEMES " Temas: "
#define LBL_URL_THEMES " URL Temas: "

// Page 3
#define DB_SETTINGS "Configurações de Base de Dados"
#define PAGE3_INFO "\n Informe as configurações  \n de Base de Dados.  \n\n Informe o tipo de base, o \n nome da base, usuário e\n senha para acessá-la.\n\n O ideal é que você mante-\n nha essas duas configura-\n ções iguais.\n\n A configuração common\n mantém as tabelas:\n cmn_users e cmn_access\n utilizadas pelo MIOLO pa-\n ra controle de usuários  e\n senhas."
#define BASE_TYPE " Tipo de Base: "
#define HOST_IP " IP Host: "
#define BASE_NAME " Nome Base: "  
#define BASE_USER " Usuário: "
#define BASE_PASSWD " Senha: "

// Page 4
#define LOGIN_SETTINGS "Configurações de Login"
#define PAGE4_INFO "\n Informe as configurações\n para o controle de Login\n no MIOLO.\n\n Para obter maiores explica-\n ções, utilize a ajuda sensi-\n tiva ao campo: \n -clique sobre o botão com\n o ponto de interrogação e\n cursor do mouse e em se-\n guida sobre o campo."
 
#define ALWAYS_CHECK_LOGIN "Sempre é necessário efetuar Login"
#define MIOLO_CONTROLS_LOGIN "O Login é controlado pelo MIOLO e não pelo Banco de Dados"
#define AUTO_LOGIN "Utilizar um Login Automático"
#define AUTO_LOGIN_ID " ID Login Auto: "
#define AUTO_LOGIN_PASS " Senha Login Auto: "
#define USER_NAME " Nome do Usuário: "

// Page4a
#define INSTALL_OPTIONS "Opções de Instalação"
#define PAGE4A_INFO "\n Selecione quais opções\n deseja instalar.\n\n Se alguma opção estiver\n desabilitada, indica que a\n opção não acompanha\n o instalador. Isso po-\n de ocorrer em caso de\n atualizações (quando não\n é necessário instalar todos\n os arquivos) ou em caso do\n arquivo não estar no diretó-\n rio do instalador.\n\n Importante: os arquivos\n existentes serão sobrescritos por isso é aconselhável\n manter uma cópia dos ar-\n quivos atuais."
#define INSTALL_MIOLO_CLASSES "Instalar classes do MIOLO"
#define INSTALL_COMMON "Instalar Módulo Common (Login e Tela/Menu Principal)"
#define INSTALL_EXAMPLES "Instalar Módulos de Exemplos e Tutorial"
#define INSTALL_THEMES "Instalar Temas"
#define CREATE_CONF_FILE "Criar arquivo de configuração: miolo.conf"
#define SHOW_APACHE_EXAMPLE "Mostrar sugestão de VirtualHost para Apache"

// Page 5
#define APACHE_EXAMPLE "Configuração do Apache" 
#define PAGE5_INFO "\n  Configuração do Apache.  \n\n  De acordo com as configu-\n rações indicadas anterior-\n mente, apresentamos aqui\n um exemplo de Virtual Host\n que você poderia utilizar\n para o Apache.\n\n  Dica: Você pode copiar e \n colar o exemplo.\n\n  Observação: \n se já existir uma configura-\n ção para este domínio, não \n é necessário criar outra."
#define SUGESTION_APACHE "Sugestão de Virtual Host para Apache: \n"

// Page 6
#define WAITING_INSTALL_TO_START "AGUARDANDO INÍCIO DA INSTALAÇÃO DO MIOLO: "
#define PAGE6_INFO "\n   O instalador do MIOLO\n está pronto para iniciar\n a Instalação. \n\n Pressione o botão para\n iniciar o processo...\n"
#define INSTALL_PROCESS "Processo de Instalação"
#define BTN_START_INSTALL "Iniciar Instalação do MIOLO"

// Methods
#define SELE_DIR "Selecione o Diretório..."
#define CREATING_DIRS "Criando diretórios..."
#define INSTALLING_MIOLO_FILES "Instalando arquivos do MIOLO..."
#define MSG_MIOLO_FILE_NOT_FOUND "Diretório: miolo (classes do MIOLO) não encontrado."
#define MSG_LOCALE_FILE_NOT_FOUND "Diretório: locale (traduções) não encontrado."
#define INSTALLING_HTDOCS "Instalando arquivos htdocs..."
#define MSG_HTDOCS_FILE_NOT_FOUND "Diretório: html (arquivo necessário pelo MIOLO) não encontrado."
#define INSTALLING_COMMON "Instalando arquivos módulo common..."
#define MSG_COMMON_FILE_NOT_FOUND "Diretório: common (Login, Menu/Tela Principal) não encontrado."
#define INSTALLING_EXAMPLES "Instalando arquivos módulo exemplos..."
#define MSG_EXAMPLES_FILE_NOT_FOUND "Diretório: sample (Exemplos de módulos/programas) não encontrado."
#define INSTALLING_THEMES "Instalando Temas do MIOLO..."
#define MSG_THEMES_FILE_NOT_FOUND "Diretório: themes (Temas do MIOLO) não encontrado."
#define MSG_MIOLOCONF_EXISTS "O arquivo <b>miolo.conf</b> já existe.<br><br>É aconselhável que você faça uma cópia do arquivo atual ou desmarque esta opção, pois o arquivo existente será sobrescrito.<br><br>Localização: "
#define CREATING_MIOLOCONF "Criando arquivo de configuração miolo.conf..."
#define INSTALLATION_FINISHED "Instalação Concluída.  Arquivo de log criado em /tmp/miolo_install.log"
#define INSTALL_END "Instalação concluída."
#define MSG_ERROR_CREATING_MIOLOCONF "Não foi possível criar o arquivo miolo.conf com as \nconfigurações informadas.\nNão esqueça que você deve executar o instalador \ncomo root (preferencialmente) ou ter permissão de\ngravação no diretório."

// WhatsThis Help
  // Page 2
#define WT_DIRBUTTON "Clique aqui para selecionar e/ou criar um diretório. <br> <b>Importante:</b> para criar um diretório, você deve ter permissão de gravação.";
#define WT_EDTHTML "Informe o diretório que estará visível na WEB. <br> Você também deverá configurar corretamente o <b>Apache</b>, para que o <em>DocumentRoot</em> (ou <em>Virtual Host</em>) apontem para este diretório e o browser encontre os arquivos corretamente.";
#define WT_EDTMIOLO "Neste campo informe o diretório onde deverão ser instalados os arquivos do <b>MIOLO</b>.";
#define WT_EDTMODULES "Aqui, informe o diretório onde estarão localizados os arquivos dos Módulos/Sistemas desenvolvidos com o MIOLO.";
#define WT_EDTLOCALE "Informe o diretório onde serão instalados os arquivos de traduções das mensagens dos Módulos/Sistemas e do MIOLO."
#define WT_EDTLOGS "Informe onde o MIOLO deverá gravar os arquivos de logs dos Módulos/Sistemas. <br> <b>Muito Importante:</b> o <em>Apache</em> deverá ter direito de gravação nesse diretório.";
#define WT_EDTTHEMES "Diretório onde serão instalados os temas dos Módulos/Sistemas e MIOLO"
#define WT_EDTURL "Informe aqui o endereço URL do site.<br><b>Importante:</b> o endereço aqui informado deve ser corretamente configurado no <em>Apache</em> (DocumentRoot ou Virtual Host)"
#define WT_EDTURL_THEMES "Informe o endereço WEB que aponte para o diretório dos temas. Este endereço estará abaixo do URL do Site identificado no item anterior"
#define WT_EDTTRACE_PORT "Através desta porta, o MIOLO envia informações como erros, sqls,... Informações essas que podem ser capturadas por programas com o objetivo de debug. Um exemplo disso é o plugin MIOLO para o editor JEdit, que recebe essas informações."

  // Page 3
#define WT_BASE_TIPO "Tipo de Base de Dados que será utilizado"
#define WT_BASE_HOST "IP da máquina onde está localizada a Base."
#define WT_BASE_BASE "Nome da Base que armazenará as tabelas do MIOLO"
#define WT_BASE_USER "Nome do usuário para acessar a Base"
#define WT_BASE_PASSWD "Senha do usuário para acesso à Base"

  // Page 4
#define WT_MKLOGIN "Ative esta opção para que o MIOLO sempre solicite o Login ao usuário. <br>Nesta situação, o MIOLO sempre abrirá a tela de login quando alguém acessar o site."
#define WT_MIOLOLOGIN "Existem duas maneiras de fazer o controle de login no sistema.<br> A primeira delas é deixar que o MIOLO controle este processo e para tal, o usuário e a senha devem ser cadastrados na tabela cmn_users. <br>Na segunda, a própria Base se encarrega de validar o usuário que deverá estar <em>obrigatoriamente</em> cadastrado na mesma. Mesmo nessa situação, o usuário deverá constar na cmn_users, com a diferença que a senha não será necessária.<br>Para deixar o MIOLO controlar o acesso dos usuários (<em>padrão</em>) ative esta opção."
#define WT_AUTOLOGIN "O MIOLO oferece a possibilidade de criar login's automáticos. Estes logins podem ser, em conjunto com as permissões atribuídas na tabela cmn_access, utilizadas para permitir o acesso a certas páginas e opções de um sistema para as quais não é necessário efetuar login de forma explícita. <br>Em outras palavras, o MIOLO efetua login no sistema utilizando o usuário e senhas definidas no login automático."
#define WT_LOGINID "Nome do usuário para login automático. As permissões deste usuário devem ser colocadas posteriormente na tabela cmn_access"
#define WT_LOGINPWD "A senha que será utilizada para o login automático"
#define WT_LOGINNAME "O nome por extenso do usuário"

  // Page 4a
#define WT_INSTALL_MIOLO "Ative esta opção para instalar as classes do MIOLO."
#define WT_INSTALL_COMMON "Ative esta opção para instalar o módulo common. <br> O módulo common é utilizado pelo MIOLO para as tarefas de login, além da criação do Menu e Tela Principal. "
#define WT_INSTALL_EXAMPLES "Com esta opção marcada, será instalado o módulo de exemplos e tutoriais."
#define WT_INSTALL_THEMES "Ative esta opção para instalar os Temas. <br> Para alterar o tema padrão utilizado nos sistemas, altere a configuração no arquivo miolo.conf.<br> Para criar ou alterar temas, dê uma olhada nos diretórios dos temas (abaixo de themes)."
#define WT_CREATE_CONF "O miolo.conf é o arquivo que mantém todas as configurações do MIOLO, portanto, é necessário que ele seja criado. <br> <em>Importante:</em> em caso de atualização do MIOLO, <b>não</b> é necessário criá-lo novamente."
#define WT_SHOW_APACHE "Para ver uma sugestão para configuração de VirtualHost  no Apache de acordo com os dados informados para a instalação, ative esta opção."
