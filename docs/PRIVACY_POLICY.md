# Política de Privacidade — Alfabetização Mágica

**Versão:** 1.0
**Última atualização:** 23 de maio de 2026
**Aplicativo:** Alfabetização Mágica
**Público-alvo:** Crianças de 4 a 7 anos (Educação Infantil)
**Desenvolvedor / Controlador de Dados:** *[A preencher antes da publicação]*
**Contato do DPO / Encarregado:** suporte@alfabetizacaomagica.app

---

## Resumo em uma frase

> **Não coletamos, não armazenamos e não enviamos nenhum dado pessoal seu
> ou da sua criança para nenhum servidor.** O aplicativo funciona 100%
> offline, no aparelho.

---

## 1. Quem somos

"Alfabetização Mágica" é um aplicativo educacional gratuito desenvolvido
para auxiliar crianças de 4 a 7 anos no processo de alfabetização em
português brasileiro, em conformidade com a BNCC (Base Nacional Comum
Curricular).

## 2. Conformidade legal

Este documento e o tratamento de dados praticado pelo aplicativo seguem:

- **LGPD** — Lei Geral de Proteção de Dados (Lei nº 13.709/2018), Brasil
- **LGPD-K / Art. 14** — Tratamento de dados de crianças e adolescentes
- **ECA** — Estatuto da Criança e do Adolescente (Lei nº 8.069/1990)
- **GDPR-K** — Regulamento Geral de Proteção de Dados, União Europeia
- **COPPA** — Children's Online Privacy Protection Act, EUA
- **Google Play "Designed for Families"** — Política de Conteúdo
- **App Store Review Guideline 1.3 / 5.1.4** — Conteúdo infantil

## 3. Quais dados o aplicativo coleta

**Nenhum dado pessoal.** Especificamente, o aplicativo **NÃO** coleta,
armazena ou transmite:

- Nome, sobrenome, apelido, data de nascimento ou idade exata
- Email, telefone ou qualquer identificador de contato
- Foto, voz gravada, vídeo ou biometria
- Localização (GPS, IP, Wi-Fi, Bluetooth)
- Identificadores publicitários (AAID, IDFA), cookies ou fingerprints
- Histórico de navegação, lista de apps instalados, contatos ou agenda
- Qualquer dado de pagamento ou financeiro

## 4. Quais dados ficam no aparelho

Os dados abaixo são armazenados **apenas no dispositivo**, usando o
mecanismo nativo `AsyncStorage`, e **nunca saem dele**:

| Dado | Finalidade | Base legal (LGPD) |
|------|------------|-------------------|
| Progresso de jogo (mundos desbloqueados, medalhas) | Continuidade do uso educacional | Art. 7º, II — execução de serviço solicitado |
| Preferências de áudio, acessibilidade, idioma | Personalização da experiência | Art. 7º, V — interesse legítimo do titular |
| Registro de consentimento parental (versão + data) | Comprovação do consentimento | Art. 14, §1º — consentimento específico |
| Log local dos últimos 50 acessos à Área dos Pais | Auditoria local pelo responsável | Art. 9º, V — transparência |

**Tudo é apagável pelo responsável a qualquer momento** (ver seção 9).

## 5. Microfone (opcional)

Algumas atividades pedagógicas (ex.: leitura em voz alta) podem usar o
microfone. Quando isso acontecer:

- **A criança verá um aviso visual claro de gravação.**
- **O áudio é processado localmente, no aparelho, em tempo real.**
- **O áudio NÃO é gravado em arquivo, NÃO é enviado a servidores,
  NÃO é compartilhado com terceiros.**
- A permissão pode ser revogada a qualquer momento em
  *Ajustes → Permissões* ou nas configurações do sistema operacional.

## 6. Anúncios, rastreadores e SDKs de terceiros

**Não há.** O aplicativo:

- Não exibe anúncios de qualquer tipo (banner, vídeo, recompensado, etc.)
- Não integra SDKs de analytics (Google Analytics, Firebase, Mixpanel etc.)
- Não integra SDKs de crash reporting que enviem dados (Sentry, Crashlytics etc.)
- Não integra SDKs de marketing ou atribuição
- Não usa cookies de qualquer tipo

## 7. Compras dentro do aplicativo

A versão atual é **inteiramente gratuita** e **sem compras dentro do
aplicativo**. Caso isso mude no futuro, esta política será atualizada,
o responsável será notificado em destaque dentro do app, e um novo
consentimento parental será solicitado.

## 8. Consentimento parental (Art. 14 LGPD)

Antes de qualquer atividade, o aplicativo apresenta uma tela de
consentimento que **deve ser concluída por um responsável** (pai, mãe,
tutor legal ou educador autorizado). Características:

- O consentimento é **específico** para finalidade educacional.
- É **destacado** (tela cheia, em destaque, com linguagem simples).
- É **comprovável** (versão da política e timestamp são gravados).
- Pode ser **revogado a qualquer momento** em *Ajustes → Pedagógico →
  Revogar consentimento parental*.
- A **revogação apaga imediatamente todos os dados locais** e retorna
  o aplicativo à tela inicial de consentimento.

Toda área de configuração sensível é protegida por um **Portão Parental**
(desafio matemático simples, inacessível a crianças de 4-7 anos), com
janela de sessão de 5 minutos.

## 9. Direitos do titular (Art. 18 LGPD)

O responsável pela criança pode, **a qualquer momento e sem necessidade
de justificativa**, exercer os seguintes direitos diretamente pelo
aplicativo, em *Ajustes → Privacidade e Dados*:

| Direito | Como exercer no app |
|---------|---------------------|
| **Confirmação e acesso** | "Baixar meus dados" — exporta JSON via compartilhamento nativo |
| **Correção** | Alterar preferências em *Ajustes* |
| **Anonimização / eliminação** | "Excluir conta e dados" — apaga tudo no aparelho |
| **Portabilidade** | Mesmo arquivo JSON da exportação |
| **Revogação de consentimento** | "Revogar consentimento parental" |
| **Informação sobre compartilhamento** | Esta política — não há compartilhamento |

Como **não enviamos nada para nenhum servidor**, não existem cópias
remotas, backups na nuvem ou réplicas. A exclusão no aparelho é
**total e definitiva**.

## 9.1 Como excluir sua conta (passo a passo)

1. Abra o aplicativo.
2. Toque na aba **Ajustes** (ícone inferior direito).
3. Toque em **Privacidade e Dados**.
4. Toque em **Excluir conta e dados**.
5. Resolva o desafio matemático do Portão Parental (1 cálculo).
6. Confirme no alerta nativo: **Excluir tudo**.

O aplicativo apagará progresso, medalhas, preferências, consentimento
e log de auditoria, e retornará à tela inicial de consentimento.
**Esta ação não pode ser desfeita.**

## 10. Retenção de dados

| Categoria | Local | Tempo de retenção |
|-----------|-------|-------------------|
| Dados de uso (progresso, preferências) | Aparelho | Até o responsável apagar ou desinstalar o app |
| Dados pessoais | — | Não coletamos, portanto não retemos |
| Logs de servidor | — | Não temos servidor |
| Dados anonimizados para estatística | — | Não coletamos sequer dados anônimos |

Desinstalar o app remove **todos** os dados pelo mecanismo padrão do
sistema operacional.

## 11. Compartilhamento com terceiros

**Nenhum.** Não compartilhamos, vendemos, alugamos ou trocamos dados
com qualquer terceiro — pelo simples motivo de **não coletarmos dados**.

## 12. Transferência internacional

Não aplicável. Nenhum dado é transmitido para fora do aparelho.

## 13. Segurança

Apesar de não coletarmos dados, adotamos boas práticas:

- Código-fonte revisado para evitar vazamentos acidentais.
- Sem permissões desnecessárias (apenas as estritamente requeridas).
- Microfone usado apenas localmente, sem persistência.
- Lista de licenças open-source disponível em *Ajustes → Suporte e
  Sobre → Licenças open-source*.

## 14. Alterações nesta política

Mudanças significativas (especialmente que afetem dados ou consentimento)
serão comunicadas dentro do aplicativo e exigirão **novo consentimento
parental explícito** antes de qualquer nova funcionalidade ser ativada.

A versão e a data da última atualização constam no topo deste documento.

## 15. Contato

- **Encarregado / DPO:** suporte@alfabetizacaomagica.app
- **Prazo de resposta:** até 15 dias corridos (LGPD Art. 19)
- **Autoridade Nacional de Proteção de Dados (ANPD):** https://www.gov.br/anpd/

---

*Este documento é publicado também em
[https://alfabetizacaomagica.app/privacidade](https://alfabetizacaomagica.app/privacidade)
e referenciado dentro do aplicativo em
*Ajustes → Privacidade e Dados → Política de Privacidade*.*
