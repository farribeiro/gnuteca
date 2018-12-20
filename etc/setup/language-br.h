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
#define NEXT "Pr�ximo >>"
#define BACK "<< Anterior"
#define FINISH "Finalizar"
#define INSTALL "Instalar"

// Page 1
#define WELCOME "Bem Vindo"
#define PAGE1_INFO "\n\n       PROGRAMA DE INSTALA��O DO MIOLO\n\n\n\n\n\n                        MIOLO vers�o 1.0 RC4\n\n\n\n\n\n\n\nAutor: Vilson Cristiano G�rtner - vgartner@univates.br\n\nhttp://miolo.codigolivre.org.br"

// Page 2
#define FILE_PATH "Localiza��o dos Arquivos"
#define PAGE2_INFO  "\n Informe as configura��es \n de localiza��o dos arquivos.  \n\n Todos os campos devem ser  \n informados.  \n Por padr�o os arquivo s�o \n instalados nesses diret�rios. \n\n
 Observa��o: � aconselh�-\n vel que voc� efetue a insta-\n la��o utilizando o usu�rio\n root. Tamb�m � poss�vel uti- \n lizar outro usu�rio, mas lem-\n bre que ser� necess�rio ter\n permiss�o de grava��o nos\n diret�rios."
#define LBL_MODULES " M�dulos: "
#define LBL_THEMES " Temas: "
#define LBL_URL_THEMES " URL Temas: "

// Page 3
#define DB_SETTINGS "Configura��es de Base de Dados"
#define PAGE3_INFO "\n Informe as configura��es  \n de Base de Dados.  \n\n Informe o tipo de base, o \n nome da base, usu�rio e\n senha para acess�-la.\n\n O ideal � que voc� mante-\n nha essas duas configura-\n ��es iguais.\n\n A configura��o common\n mant�m as tabelas:\n cmn_users e cmn_access\n utilizadas pelo MIOLO pa-\n ra controle de usu�rios  e\n senhas."
#define BASE_TYPE " Tipo de Base: "
#define HOST_IP " IP Host: "
#define BASE_NAME " Nome Base: "  
#define BASE_USER " Usu�rio: "
#define BASE_PASSWD " Senha: "

// Page 4
#define LOGIN_SETTINGS "Configura��es de Login"
#define PAGE4_INFO "\n Informe as configura��es\n para o controle de Login\n no MIOLO.\n\n Para obter maiores explica-\n ��es, utilize a ajuda sensi-\n tiva ao campo: \n -clique sobre o bot�o com\n o ponto de interroga��o e\n cursor do mouse e em se-\n guida sobre o campo."
 
#define ALWAYS_CHECK_LOGIN "Sempre � necess�rio efetuar Login"
#define MIOLO_CONTROLS_LOGIN "O Login � controlado pelo MIOLO e n�o pelo Banco de Dados"
#define AUTO_LOGIN "Utilizar um Login Autom�tico"
#define AUTO_LOGIN_ID " ID Login Auto: "
#define AUTO_LOGIN_PASS " Senha Login Auto: "
#define USER_NAME " Nome do Usu�rio: "

// Page4a
#define INSTALL_OPTIONS "Op��es de Instala��o"
#define PAGE4A_INFO "\n Selecione quais op��es\n deseja instalar.\n\n Se alguma op��o estiver\n desabilitada, indica que a\n op��o n�o acompanha\n o instalador. Isso po-\n de ocorrer em caso de\n atualiza��es (quando n�o\n � necess�rio instalar todos\n os arquivos) ou em caso do\n arquivo n�o estar no diret�-\n rio do instalador.\n\n Importante: os arquivos\n existentes ser�o sobrescritos por isso � aconselh�vel\n manter uma c�pia dos ar-\n quivos atuais."
#define INSTALL_MIOLO_CLASSES "Instalar classes do MIOLO"
#define INSTALL_COMMON "Instalar M�dulo Common (Login e Tela/Menu Principal)"
#define INSTALL_EXAMPLES "Instalar M�dulos de Exemplos e Tutorial"
#define INSTALL_THEMES "Instalar Temas"
#define CREATE_CONF_FILE "Criar arquivo de configura��o: miolo.conf"
#define SHOW_APACHE_EXAMPLE "Mostrar sugest�o de VirtualHost para Apache"

// Page 5
#define APACHE_EXAMPLE "Configura��o do Apache" 
#define PAGE5_INFO "\n  Configura��o do Apache.  \n\n  De acordo com as configu-\n ra��es indicadas anterior-\n mente, apresentamos aqui\n um exemplo de Virtual Host\n que voc� poderia utilizar\n para o Apache.\n\n  Dica: Voc� pode copiar e \n colar o exemplo.\n\n  Observa��o: \n se j� existir uma configura-\n ��o para este dom�nio, n�o \n � necess�rio criar outra."
#define SUGESTION_APACHE "Sugest�o de Virtual Host para Apache: \n"

// Page 6
#define WAITING_INSTALL_TO_START "AGUARDANDO IN�CIO DA INSTALA��O DO MIOLO: "
#define PAGE6_INFO "\n   O instalador do MIOLO\n est� pronto para iniciar\n a Instala��o. \n\n Pressione o bot�o para\n iniciar o processo...\n"
#define INSTALL_PROCESS "Processo de Instala��o"
#define BTN_START_INSTALL "Iniciar Instala��o do MIOLO"

// Methods
#define SELE_DIR "Selecione o Diret�rio..."
#define CREATING_DIRS "Criando diret�rios..."
#define INSTALLING_MIOLO_FILES "Instalando arquivos do MIOLO..."
#define MSG_MIOLO_FILE_NOT_FOUND "Diret�rio: miolo (classes do MIOLO) n�o encontrado."
#define MSG_LOCALE_FILE_NOT_FOUND "Diret�rio: locale (tradu��es) n�o encontrado."
#define INSTALLING_HTDOCS "Instalando arquivos htdocs..."
#define MSG_HTDOCS_FILE_NOT_FOUND "Diret�rio: html (arquivo necess�rio pelo MIOLO) n�o encontrado."
#define INSTALLING_COMMON "Instalando arquivos m�dulo common..."
#define MSG_COMMON_FILE_NOT_FOUND "Diret�rio: common (Login, Menu/Tela Principal) n�o encontrado."
#define INSTALLING_EXAMPLES "Instalando arquivos m�dulo exemplos..."
#define MSG_EXAMPLES_FILE_NOT_FOUND "Diret�rio: sample (Exemplos de m�dulos/programas) n�o encontrado."
#define INSTALLING_THEMES "Instalando Temas do MIOLO..."
#define MSG_THEMES_FILE_NOT_FOUND "Diret�rio: themes (Temas do MIOLO) n�o encontrado."
#define MSG_MIOLOCONF_EXISTS "O arquivo <b>miolo.conf</b> j� existe.<br><br>� aconselh�vel que voc� fa�a uma c�pia do arquivo atual ou desmarque esta op��o, pois o arquivo existente ser� sobrescrito.<br><br>Localiza��o: "
#define CREATING_MIOLOCONF "Criando arquivo de configura��o miolo.conf..."
#define INSTALLATION_FINISHED "Instala��o Conclu�da.  Arquivo de log criado em /tmp/miolo_install.log"
#define INSTALL_END "Instala��o conclu�da."
#define MSG_ERROR_CREATING_MIOLOCONF "N�o foi poss�vel criar o arquivo miolo.conf com as \nconfigura��es informadas.\nN�o esque�a que voc� deve executar o instalador \ncomo root (preferencialmente) ou ter permiss�o de\ngrava��o no diret�rio."

// WhatsThis Help
  // Page 2
#define WT_DIRBUTTON "Clique aqui para selecionar e/ou criar um diret�rio. <br> <b>Importante:</b> para criar um diret�rio, voc� deve ter permiss�o de grava��o.";
#define WT_EDTHTML "Informe o diret�rio que estar� vis�vel na WEB. <br> Voc� tamb�m dever� configurar corretamente o <b>Apache</b>, para que o <em>DocumentRoot</em> (ou <em>Virtual Host</em>) apontem para este diret�rio e o browser encontre os arquivos corretamente.";
#define WT_EDTMIOLO "Neste campo informe o diret�rio onde dever�o ser instalados os arquivos do <b>MIOLO</b>.";
#define WT_EDTMODULES "Aqui, informe o diret�rio onde estar�o localizados os arquivos dos M�dulos/Sistemas desenvolvidos com o MIOLO.";
#define WT_EDTLOCALE "Informe o diret�rio onde ser�o instalados os arquivos de tradu��es das mensagens dos M�dulos/Sistemas e do MIOLO."
#define WT_EDTLOGS "Informe onde o MIOLO dever� gravar os arquivos de logs dos M�dulos/Sistemas. <br> <b>Muito Importante:</b> o <em>Apache</em> dever� ter direito de grava��o nesse diret�rio.";
#define WT_EDTTHEMES "Diret�rio onde ser�o instalados os temas dos M�dulos/Sistemas e MIOLO"
#define WT_EDTURL "Informe aqui o endere�o URL do site.<br><b>Importante:</b> o endere�o aqui informado deve ser corretamente configurado no <em>Apache</em> (DocumentRoot ou Virtual Host)"
#define WT_EDTURL_THEMES "Informe o endere�o WEB que aponte para o diret�rio dos temas. Este endere�o estar� abaixo do URL do Site identificado no item anterior"
#define WT_EDTTRACE_PORT "Atrav�s desta porta, o MIOLO envia informa��es como erros, sqls,... Informa��es essas que podem ser capturadas por programas com o objetivo de debug. Um exemplo disso � o plugin MIOLO para o editor JEdit, que recebe essas informa��es."

  // Page 3
#define WT_BASE_TIPO "Tipo de Base de Dados que ser� utilizado"
#define WT_BASE_HOST "IP da m�quina onde est� localizada a Base."
#define WT_BASE_BASE "Nome da Base que armazenar� as tabelas do MIOLO"
#define WT_BASE_USER "Nome do usu�rio para acessar a Base"
#define WT_BASE_PASSWD "Senha do usu�rio para acesso � Base"

  // Page 4
#define WT_MKLOGIN "Ative esta op��o para que o MIOLO sempre solicite o Login ao usu�rio. <br>Nesta situa��o, o MIOLO sempre abrir� a tela de login quando algu�m acessar o site."
#define WT_MIOLOLOGIN "Existem duas maneiras de fazer o controle de login no sistema.<br> A primeira delas � deixar que o MIOLO controle este processo e para tal, o usu�rio e a senha devem ser cadastrados na tabela cmn_users. <br>Na segunda, a pr�pria Base se encarrega de validar o usu�rio que dever� estar <em>obrigatoriamente</em> cadastrado na mesma. Mesmo nessa situa��o, o usu�rio dever� constar na cmn_users, com a diferen�a que a senha n�o ser� necess�ria.<br>Para deixar o MIOLO controlar o acesso dos usu�rios (<em>padr�o</em>) ative esta op��o."
#define WT_AUTOLOGIN "O MIOLO oferece a possibilidade de criar login's autom�ticos. Estes logins podem ser, em conjunto com as permiss�es atribu�das na tabela cmn_access, utilizadas para permitir o acesso a certas p�ginas e op��es de um sistema para as quais n�o � necess�rio efetuar login de forma expl�cita. <br>Em outras palavras, o MIOLO efetua login no sistema utilizando o usu�rio e senhas definidas no login autom�tico."
#define WT_LOGINID "Nome do usu�rio para login autom�tico. As permiss�es deste usu�rio devem ser colocadas posteriormente na tabela cmn_access"
#define WT_LOGINPWD "A senha que ser� utilizada para o login autom�tico"
#define WT_LOGINNAME "O nome por extenso do usu�rio"

  // Page 4a
#define WT_INSTALL_MIOLO "Ative esta op��o para instalar as classes do MIOLO."
#define WT_INSTALL_COMMON "Ative esta op��o para instalar o m�dulo common. <br> O m�dulo common � utilizado pelo MIOLO para as tarefas de login, al�m da cria��o do Menu e Tela Principal. "
#define WT_INSTALL_EXAMPLES "Com esta op��o marcada, ser� instalado o m�dulo de exemplos e tutoriais."
#define WT_INSTALL_THEMES "Ative esta op��o para instalar os Temas. <br> Para alterar o tema padr�o utilizado nos sistemas, altere a configura��o no arquivo miolo.conf.<br> Para criar ou alterar temas, d� uma olhada nos diret�rios dos temas (abaixo de themes)."
#define WT_CREATE_CONF "O miolo.conf � o arquivo que mant�m todas as configura��es do MIOLO, portanto, � necess�rio que ele seja criado. <br> <em>Importante:</em> em caso de atualiza��o do MIOLO, <b>n�o</b> � necess�rio cri�-lo novamente."
#define WT_SHOW_APACHE "Para ver uma sugest�o para configura��o de VirtualHost  no Apache de acordo com os dados informados para a instala��o, ative esta op��o."
