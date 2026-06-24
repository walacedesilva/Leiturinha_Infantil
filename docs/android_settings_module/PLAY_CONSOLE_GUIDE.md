# Guia de Configuração e Publicação: Google Cloud Console & Play Console

Este guia detalha as etapas estratégicas e de conformidade necessárias para publicar com sucesso um aplicativo Android moderno que utiliza login social do Google (Credential Manager) e coleta preferências do usuário, atendendo a todos os requisitos do **Google Play Console**, regulamentações de privacidade (**LGPD/GDPR**) e políticas familiares.

---

## 🛠️ PARTE 1: Google Cloud Console (OAuth & Credenciais)

Para que o **Credential Manager** consiga obter com sucesso os ID Tokens das contas Google dos usuários do dispositivo, é obrigatório registrar o aplicativo no console de desenvolvimento do Google Cloud.

### 📋 Checklist de Passos no Cloud Console:

1. **Criar ou Selecionar um Projeto**:
   - Acesse o [Google Cloud Console](https://console.cloud.google.com/).
   - Crie um novo projeto dedicado ao seu aplicativo ou selecione o existente vinculado ao Firebase.

2. **Configurar a Tela de Consentimento OAuth**:
   - No menu lateral esquerdo, vá em **APIs e Serviços** > **Tela de consentimento OAuth**.
   - Escolha o tipo de usuário: **Externo** (External) para aplicativos de produção abertos ao público.
   - Preencha os campos obrigatórios básicos de branding:
     - **Nome do App**, **E-mail de suporte ao usuário** e **Logotipo**.
     - **Domínio Autorizado**: adicione o domínio do seu site onde as políticas de privacidade estão hospedadas.
     - **Link da Política de Privacidade** e **Link dos Termos de Serviço**.

3. **Definição de Escopos (Scopes)**:
   - Na etapa de escopos, adicione apenas os escopos não sensíveis necessários para a experiência do usuário:
     - `.../auth/userinfo.profile` (para obter nome e foto do perfil).
     - `.../auth/userinfo.email` (para identificador único e comunicação de suporte).
     - `openid` (protocolo OpenID Connect básico).
   - > [!IMPORTANT]
     > Não solicite escopos adicionais desnecessários (como acesso ao Google Drive ou Agenda), a menos que o app realmente precise. Escopos sensíveis ou restritos exigem um longo processo de verificação independente que custa tempo e pode atrasar o lançamento do seu app.

4. **Adicionar Usuários de Teste (Modo "Testing")**:
   - Enquanto o status do seu consentimento OAuth estiver em **Teste (Testing)**, o login só funcionará para os e-mails registrados nesta lista.
   - Adicione todos os seus e-mails de teste corporativos e pessoais de homologação.

5. **Criar Credenciais OAuth (A Chave de Integração)**:
   - Vá para a aba **Credenciais** > **Criar Credenciais** > **ID do cliente OAuth**.
   - **PASSO A: Criar o ID Web (Web Application ID)**:
     - Selecione **Aplicativo da Web** (Web Application).
     - Dê o nome de: `Servidor Backend - Produção`.
     - Deixe as URIs vazias.
     - Clique em criar e salve o **ID do Cliente** gerado. Este é o seu `OAUTH_WEB_CLIENT_ID` que deve ser inserido no código fonte nativo (`AuthRepository.kt`).
   - **PASSO B: Criar o ID Android (Android Client ID)**:
     - Clique novamente em **Criar Credenciais** > **ID do cliente OAuth**.
     - Selecione **Android**.
     - Insira o nome do pacote exato do seu aplicativo (`packageName` declarado no `build.gradle` ou manifest nativo).
     - Insira a assinatura digital **SHA-1** do certificado.
       - *Assinatura de Debug*: Extraia localmente rodando no terminal do projeto: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`
       - *Assinatura de Produção*: Obtenha diretamente do Google Play Console sob o menu **Assinatura de apps** (App Signing). O Google gerencia sua chave de produção, então a chave SHA-1 da Play Store é a que deve estar cadastrada aqui!

---

## 📥 PARTE 2: Declaração de Segurança dos Dados (Data Safety Form)

A declaração correta das práticas de coleta de dados no formulário de **Segurança dos Dados (Data Safety)** é eliminatória. Declarações incorretas levam à **rejeição da atualização** ou até mesmo à **suspensão** do aplicativo na loja.

### 📝 Respostas Corretas para o Formulário:

Ao preencher o questionário no Play Console, marque as seguintes opções para o módulo implementado:

1. **Coleta e Compartilhamento de Dados**:
   - O aplicativo coleta ou compartilha algum dos tipos de dados de usuário obrigatórios? **Sim**.
   - Todos os dados coletados pelo app são criptografados em trânsito? **Sim** (Toda a comunicação com a API Google Identity é criptografada sob HTTPS).
   - O aplicativo fornece um meio para que os usuários solicitem a exclusão de seus dados? **Sim** (Implementado via botão "Excluir minha conta" nas configurações em conformidade com a LGPD/GDPR).

2. **Categorias de Dados Coletados**:
   - **Dados Pessoais**:
     - *Nome*: Coletado para fins de personalização e identificação do perfil (Autenticação do usuário).
     - *Endereço de E-mail*: Coletado para fins de autenticação e comunicação de segurança/suporte.
   - **Fotos e Vídeos**:
     - *Fotos*: A foto do perfil fornecida pelo Google é acessada temporariamente para exibição visual do avatar logado.
   - **Informações do App e Desempenho**:
     - *Dados de Diagnóstico / Interações no App*: Coletado de forma anônima (somente se o usuário mantiver o toggle "Compartilhar dados de uso" habilitado).

3. **Uso dos Dados Coletados**:
   - Para cada tipo de dados acima (Nome, E-mail e Foto), declare que:
     - Os dados são processados de forma efêmera? **Não** (Ficam armazenados na nuvem para manter o perfil salvo).
     - A coleta é obrigatória ou opcional? **Opcional** (O usuário pode escolher navegar de forma anônima / deslogado no app de configurações).
     - **Finalidades do Uso**: Marque **Funcionalidade do aplicativo** (App Functionality) e **Gerenciamento de Contas** (Account Management).

---

## 👪 PARTE 3: Questionário de Acesso e Diretrizes de Famílias

Se o seu aplicativo estiver sob a categoria de **Famílias ou Crianças (Designed for Families)** ou se tiver um público-alvo infantil (como o ecossistema "Leiturinha"):

1. **Autenticação Padrão para Menores**:
   - > [!WARNING]
     > A política de Famílias do Google proíbe a obrigatoriedade de login social para crianças. O aplicativo **deve** permitir acesso a todas as funcionalidades principais sem exigir login. A autenticação do Google serve apenas como salvamento de progresso opcional para os pais.
   - A tela de login do Google deve ser precedida de um **Controle Parental** (Gate) que exija que o responsável resolva um desafio matemático simples ou insira o ano de nascimento para validar que é um adulto efetuando o login.

2. **Questionário de Acesso do Play Console**:
   - Responda honestamente que o app se destina a crianças e pais, e detalhe que o fluxo de autenticação foi projetado apenas para gerenciamento parental de progresso, com exclusão segura disponível.

---

## 🧪 PARTE 4: Dicas de Teste em Ambiente de Teste Fechado (Closed Testing)

A melhor maneira de garantir que o Credential Manager e o fluxo de login do Google funcionem perfeitamente em produção é utilizando as faixas de **Teste Fechado** ou **Teste Interno** da Google Play.

### 💡 Recomendações Críticas para Testes Rápidos:

* **Contas de Teste GMS (Google Mobile Services)**:
  - Adicione o e-mail que você vai testar no aparelho como um "Testador" no circuito fechado da Play Store.
  - Certifique-se de que a conta Google está devidamente logada no aparelho Android que está executando os testes físicos.
  - O e-mail de teste deve ser registrado como **Testador OAuth** no Google Cloud Console (Parte 1, Passo 4) para evitar a tela de aviso de erro "App não verificado".

* **Cuidado com Logs de Autenticação**:
  - Evite exibir o valor completo do `idToken` ou `accessToken` no console do Logcat do Android Studio (`Log.d`). 
  - Exibir PII (Personally Identifiable Information) ou tokens em texto plano no console de logs pode violar regras internas de segurança da Google Play Protection e reprovar o app durante a verificação estática do robo da Play Store.
  - No código fornecido na arquitetura nativa, nós omitimos logs que expõem o token diretamente por questões de conformidade de segurança e LGPD.

* **Assinatura Google Play App Signing**:
  - Em homologação local (rodando do Android Studio direto para o celular), o app é assinado com o seu `debug.keystore` local.
  - Quando você envia o APK/AAB para a Play Store, o Google assina o app com um certificado diferente.
  - **Sempre cadastre as duas chaves SHA-1 (a de debug local e a de produção da Play Console) no Console do Google Cloud**, caso contrário, o login retornará o erro genérico de API `12500` ou `API_EXCEPTION` ao baixar o app da loja de teste fechado!
