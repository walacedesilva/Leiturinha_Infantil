# Publicação na Google Play — o que falta (Leiturinha)

Auditoria do projeto + requisitos atuais da Play (junho/2026). Itens marcados ✅ já estão prontos/feitos nesta sessão; ⛔ são **bloqueadores** (a Play recusa sem isso); ⚠️ são exigências da loja a preencher no Console.

---

## 1. Bloqueadores técnicos (no código/projeto)

✅ **applicationId** — definido como **`br.com.wpghub.leiturinhainfantil`** (reverso do domínio `leiturinhainfantil.wpghub.com.br`) em `android/app/build.gradle.kts`. *(O `namespace` interno segue `com.example...`, o que é inofensivo — a Play só usa o applicationId.)*
   - ⚠️ Atenção: o novo package afeta o **Google Sign-In** — recrie/atualize o **OAuth client Android** no Google Cloud com packageName `br.com.wpghub.leiturinha` + a **SHA-1** da keystore de upload (e a SHA do App Signing da Play).

✅ **Assinatura de release** — antes usava a **chave de debug** (a Play recusa). Configurei o Gradle para assinar com uma keystore de upload via `android/key.properties` (com fallback para debug enquanto a keystore não existe).
   - Falta **você gerar a keystore** (tem senha; só você cria) e criar o `android/key.properties` a partir do `android/key.properties.example`. Comando:
     ```
     keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
     ```
   - Guarde a keystore e as senhas com backup — perdê-las impede futuras atualizações.

⛔ **Target SDK / formato** — Play exige (2026) **target API 35 (Android 15)** para apps novos (e **API 36** a partir de 31/08/2026), e publicação em **AAB** (não APK).
   - Ação: confirmar `targetSdk = 35` (se o seu Flutter resolver para 34, fixe explicitamente em `build.gradle.kts`).
   - Build de produção: `flutter build appbundle --release` → gera `build/app/outputs/bundle/release/app-release.aab`.

✅ **Nome de exibição** — corrigido de `leiturinha_infantil` para **"Leiturinha"** no `AndroidManifest`.

⚠️ **`usesCleartextTraffic="true"`** no manifesto — permite HTTP sem TLS; a Play pode questionar num app infantil. Se o WebView não precisar de HTTP puro, troque para `false`. Verificar.

⚠️ **Ícone** — usa `assets/images/logo.png` (flutter_launcher_icons). Confirme que o ícone final está bom em todas as densidades e gere o **512×512** para a loja.

---

## 2. Conta e configuração na Play Console

⚠️ **Conta de desenvolvedor**: taxa única de **US$ 25** + **verificação em 2 etapas** obrigatória.

⚠️ **Teste fechado obrigatório (contas pessoais novas)**: antes de liberar em produção, a Google exige **12 testadores** rodando o app por **14 dias consecutivos** em teste fechado. Planeje isso no cronograma (é o que mais atrasa).

⚠️ **Listagem da loja**: título (≤30), descrição curta (≤80), descrição completa (≤4000), **ícone 512×512**, **feature graphic 1024×500**, **2–8 screenshots** (capture as telas em retrato já ajustadas).

---

## 3. App infantil — "Designed for Families" (crítico aqui)

O Leiturinha é para crianças → cai na política **Famílias/Designed for Families** (mais rígida).

⚠️ **Público-alvo e conteúdo**: declarar faixa etária infantil; o app precisa cumprir a política de Famílias.
⚠️ **Política de Privacidade (obrigatória e pública)**: já existe `docs/PRIVACY_POLICY.md` e `docs/TERMS.md` — falta **hospedar numa URL pública** (site/GitHub Pages) e colar o link no Console e na ficha.
⚠️ **Data Safety (Segurança dos dados)**: declarar o que é coletado. O app coleta/usa:
   - **Microfone (RECORD_AUDIO)** — para a pronúncia (declarar uso; idealmente processado no device, não enviado).
   - **E-mail/perfil Google** — no login dos pais (Google Sign-In).
   - Declarar finalidade, se há compartilhamento e se há coleta de menores.
⚠️ **Classificação de conteúdo (questionário IARC)**: responder; deve sair "Livre/3+".
⚠️ **Anúncios/compras**: declarar que **não há anúncios** nem compras (ou, se houver, seguir regras de Famílias — sem ads comportamentais para crianças).
⚠️ **Login que coleta dados de crianças**: o login Google é **só para os pais** (atrás do portão dos pais) — isso é aceitável, mas precisa estar claro na Data Safety e na política.

---

## 4. Acesso para os revisores (campo "Acesso ao app") ✅

A Play exige credenciais/instruções quando há login. O app **não trava** o conteúdo atrás de login obrigatório, e adicionei um acesso de demonstração explícito.

**Como preencher o campo "Acesso ao app" na Play Console:**
- Marque que **parte do app** tem login (área dos pais via Google).
- Forneça estas instruções (sem senha):
  > Na tela inicial, toque em **"Acesso de demonstração"** (ou em "Já tenho uma conta") para entrar como visitante e acessar todo o app, sem necessidade de conta Google. A "Área dos Pais" abre resolvendo a continha do portão parental exibida na tela.
- Conta demo exibida: **Visitante / revisor@leiturinha.app** (login simulado interno; não requer senha).

> Observação: como o conteúdo principal é acessível sem login, você também pode marcar "Todas as funcionalidades disponíveis sem acesso especial" e citar o botão de demonstração como atalho.

---

## 5. Comandos úteis

```
# Gerar a keystore de upload (uma vez)
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build de produção (AAB) para enviar à Play
flutter build appbundle --release

# Conferir versão antes de subir: pubspec.yaml -> version: 1.0.0+1
# (suba o +N a cada envio; ex.: 1.0.0+2)
```

---

## 6. Resumo do que falta (ordem sugerida)

1. ⛔ Definir o **applicationId** definitivo *(me informe o ID)*.
2. ⛔ **Gerar a keystore** + criar `android/key.properties`.
3. ⛔ Garantir **targetSdk 35** e gerar o **AAB**.
4. ⚠️ Atualizar/recriar o **OAuth client** do Google Sign-In com o novo package + SHA-1 da keystore.
5. ⚠️ **Hospedar a política de privacidade** e pegar a URL.
6. ⚠️ Criar conta na Play ($25, 2FA) e preencher: listagem, Data Safety, classificação, público (Famílias), Acesso ao app.
7. ⚠️ Rodar o **teste fechado (12 testadores / 14 dias)**.
8. ✅ Acesso de demonstração para revisão — já no app.

O que já ficou pronto nesta sessão: assinatura de release configurada (falta a keystore), nome do app, acesso de demonstração e proteção da keystore no `.gitignore`.
