/**
 * SettingsScreen.js
 * -----------------------------------------------------------------------------
 * Tela "Ajustes" — Área dos Pais.
 *
 * Conformidade alvo:
 *   - Google Play "Designed for Families" & Política de Conteúdo
 *   - LGPD-K (Lei Geral de Proteção de Dados — Crianças e Adolescentes)
 *   - GDPR-K
 *   - WCAG 2.1 AA
 *
 * Arquitetura em DUAS camadas:
 *   👶 MODO CRIANÇA: apenas "Áudio (Volume Mestre + Mudo)" exposto.
 *      Tudo o mais aparece "trancado" com cadeado.
 *   👨‍👩 ÁREA DOS PAIS: ParentalGate destrava por 5 min (settingsStore.session).
 *
 * Particularidades deste app:
 *   - 100% offline-first, sem contas, sem backend, sem PII, sem IAP.
 *     → "Excluir conta" apaga TODO o estado local (progress + consent +
 *        settings) — equivalente à deleção total, porque NÃO existem dados
 *        no servidor. O texto da UI explica isso claramente ao responsável.
 *     → Seções de Compras/Assinatura são exibidas com aviso honesto
 *        ("Versão gratuita, sem compras internas").
 *     → Notificações push: toggles persistidos, mas o app não dispara push
 *        nesta versão (rotulado como "Preferências para futura atualização").
 *   - Tema dark consistente com o restante do app (#0E2A47 / #F5C518).
 * -----------------------------------------------------------------------------
 */

import React, { useMemo, useState, useCallback } from 'react';
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  ScrollView,
  Switch,
  Linking,
  Platform,
  Share,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import Constants from 'expo-constants';

import { useProgressStore } from '../store/progressStore';
import { useConsentStore, CURRENT_POLICY_VERSION } from '../store/consentStore';
import { useSettingsStore, TEXT_SCALES, GATE_TTL_MS } from '../store/settingsStore';
import ParentalGate from '../components/ParentalGate';

// Links públicos (substituir pelos URLs reais quando publicar).
const URL_PRIVACY = 'https://alfabetizacaomagica.app/privacidade';
const URL_TOS     = 'https://alfabetizacaomagica.app/termos';
const URL_LICENSES_INTERNAL = 'oss-licenses'; // tela interna (futura)
const SUPPORT_EMAIL = 'suporte@alfabetizacaomagica.app';

// Licenças open-source declaradas (manter sincronizado com package.json).
const OSS_LICENSES = [
  { name: 'react-native',                  license: 'MIT' },
  { name: 'expo',                          license: 'MIT' },
  { name: '@react-navigation/native',      license: 'MIT' },
  { name: '@react-navigation/bottom-tabs', license: 'MIT' },
  { name: '@react-navigation/native-stack',license: 'MIT' },
  { name: '@react-native-async-storage',   license: 'MIT' },
  { name: 'zustand',                       license: 'MIT' },
  { name: 'react-native-safe-area-context',license: 'MIT' },
  { name: 'react-native-screens',          license: 'MIT' },
  { name: 'react-native-svg',              license: 'MIT' },
  { name: 'react-native-gesture-handler',  license: 'MIT' },
  { name: 'expo-av',                       license: 'MIT' },
];

export default function SettingsScreen() {
  const navigation = useNavigation();

  const consent = useConsentStore((s) => s.consent);
  const setMicrophone = useConsentStore((s) => s.setMicrophone);
  const revokeConsent = useConsentStore((s) => s.revoke);

  const progress = useProgressStore((s) => s.progress);
  const resetProgress = useProgressStore((s) => s.resetProgress);

  const settings = useSettingsStore((s) => s.settings);
  const updateSettings = useSettingsStore((s) => s.update);
  const resetSettings = useSettingsStore((s) => s.reset);
  const isGateUnlocked = useSettingsStore((s) => s.isGateUnlocked);
  const unlockGate = useSettingsStore((s) => s.unlockGate);
  const lockGate = useSettingsStore((s) => s.lockGate);
  const accessLog = useSettingsStore((s) => s.session.accessLog);

  const [gateOpen, setGateOpen]   = useState(false);
  const [pending, setPending]     = useState(null); // {action, payload?}
  const [toast, setToast]         = useState(null);

  const unlocked = isGateUnlocked();

  // ── Toast helper ───────────────────────────────────────────────────────
  const showToast = useCallback((msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2200);
  }, []);

  // ── Guarda toda ação sensível atrás do gate (1 vez por sessão de 5 min) ─
  const requireGate = useCallback((action, payload = null) => {
    if (isGateUnlocked()) {
      runAction(action, payload);
    } else {
      setPending({ action, payload });
      setGateOpen(true);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isGateUnlocked]);

  const runAction = useCallback((action, payload) => {
    switch (action) {
      case 'toggleMic':
        setMicrophone(!consent.microphoneAllowed);
        showToast(consent.microphoneAllowed ? 'Microfone desativado.' : 'Microfone ativado.');
        break;
      case 'resetProgress':
        resetProgress();
        showToast('Progresso reiniciado.');
        break;
      case 'deleteAccount':
        // Confirmação dupla (modal nativo) antes da ação destrutiva.
        Alert.alert(
          'Excluir TODOS os dados?',
          'Isto apagará permanentemente: progresso, medalhas, preferências e consentimento. ' +
          'Como este app não envia dados a servidores, esta ação é definitiva no aparelho. ' +
          'Não pode ser desfeita.',
          [
            { text: 'Cancelar', style: 'cancel' },
            {
              text: 'Excluir tudo',
              style: 'destructive',
              onPress: () => {
                resetProgress();
                resetSettings();
                revokeConsent();
                lockGate();
                navigation.reset({ index: 0, routes: [{ name: 'Consent' }] });
              },
            },
          ],
        );
        break;
      case 'revokeConsent':
        revokeConsent();
        lockGate();
        navigation.reset({ index: 0, routes: [{ name: 'Consent' }] });
        break;
      case 'updateSetting':
        updateSettings(payload);
        break;
      case 'openOsSettings':
        Linking.openSettings().catch(() => showToast('Não foi possível abrir Configurações.'));
        break;
      case 'exportData':
        exportAllData(progress, consent, settings, accessLog).then((ok) =>
          showToast(ok ? 'Arquivo compartilhado.' : 'Exportação cancelada.'),
        );
        break;
      case 'manageSubscription':
        openSubscriptionDeepLink();
        break;
      case 'restorePurchases':
        // Sem IAP nesta versão — feedback honesto.
        showToast('Nenhuma compra a restaurar (versão gratuita).');
        break;
      case 'clearAccessLog':
        useSettingsStore.getState().clearAccessLog();
        showToast('Log de acessos limpo.');
        break;
      default:
        break;
    }
    setPending(null);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [consent.microphoneAllowed, progress, settings, accessLog]);

  const handleGatePass = () => {
    unlockGate('math');
    setGateOpen(false);
    if (pending) runAction(pending.action, pending.payload);
  };

  const handleGateCancel = () => {
    setGateOpen(false);
    setPending(null);
  };

  // ── Metadados do app ───────────────────────────────────────────────────
  const appMeta = useMemo(() => {
    const expoCfg = Constants.expoConfig || {};
    const version = expoCfg.version || '0.0.0';
    const build   = Platform.select({
      ios:     expoCfg.ios?.buildNumber,
      android: String(expoCfg.android?.versionCode || ''),
    }) || '—';
    return {
      version,
      build,
      device: `${Platform.OS} ${Platform.Version}`,
    };
  }, []);

  // ── Render ─────────────────────────────────────────────────────────────
  return (
    <SafeAreaView style={styles.root}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.h1}>Ajustes</Text>
        <Text style={styles.h1Sub}>
          {unlocked
            ? `Área dos Pais destravada por ${Math.ceil(GATE_TTL_MS / 60000)} min.`
            : 'Itens com 🔒 exigem verificação do responsável.'}
        </Text>

        {/* ────────── 1. SEMPRE VISÍVEL (modo criança) ────────── */}
        <Section title="Áudio rápido">
          <SwitchRow
            label="Modo silencioso"
            hint="Mantém vibração; zera som."
            value={settings.silentMode}
            onChange={(v) => updateSettings({ silentMode: v })}
          />
          <SliderLikeRow
            label="Volume mestre"
            value={settings.volumeMaster}
            onChange={(v) => updateSettings({ volumeMaster: v })}
          />
        </Section>

        {/* ────────── 2. Privacidade e Dados ────────── */}
        <Section title="Privacidade e Dados" locked={!unlocked}>
          <Row
            label="Política de Privacidade"
            actionLabel="Abrir"
            onPress={() => Linking.openURL(URL_PRIVACY)}
          />
          <Row
            label="Termos de Uso"
            actionLabel="Abrir"
            onPress={() => Linking.openURL(URL_TOS)}
          />
          <Row
            label="Baixar meus dados (JSON)"
            hint="Exporta progresso, preferências e consentimento."
            actionLabel="Exportar"
            onPress={() => requireGate('exportData')}
          />
          <Row
            label="Excluir conta e dados"
            hint="Apaga tudo no aparelho. Este app não envia dados a servidores."
            actionLabel="Excluir"
            danger
            onPress={() => requireGate('deleteAccount')}
          />
        </Section>

        {/* ────────── 3. Permissões e Notificações ────────── */}
        <Section title="Permissões e Notificações" locked={!unlocked}>
          <KVRow
            label="Microfone (para leitura em voz alta)"
            value={consent.microphoneAllowed ? '✅ Ativado' : '⚠️ Desativado'}
          />
          <Row
            label={consent.microphoneAllowed ? 'Desativar microfone' : 'Ativar microfone'}
            actionLabel="Alternar"
            onPress={() => requireGate('toggleMic')}
          />
          <Row
            label="Gerenciar permissões do sistema"
            hint="Abre os Ajustes do seu aparelho."
            actionLabel="Abrir"
            onPress={() => requireGate('openOsSettings')}
          />

          <Divider label="Notificações push" />
          <SwitchRow
            label="🎯 Missões e desafios"
            value={settings.notifMissions}
            onChange={(v) => requireGate('updateSetting', { notifMissions: v })}
          />
          <SwitchRow
            label="✨ Novidades e conteúdos"
            value={settings.notifNews}
            onChange={(v) => requireGate('updateSetting', { notifNews: v })}
          />
          <SwitchRow
            label="📢 Marketing e promoções"
            hint="Desligado por padrão (LGPD-K)."
            value={settings.notifMarketing}
            onChange={(v) => requireGate('updateSetting', { notifMarketing: v })}
          />
          <Caption>
            Você pode alterar essas escolhas a qualquer momento nas configurações do dispositivo.
          </Caption>
        </Section>

        {/* ────────── 4. Compras e Assinaturas ────────── */}
        <Section title="Compras e Assinaturas" locked={!unlocked}>
          <Caption>
            Esta versão é <Text style={styles.captionBold}>gratuita</Text> e não possui compras internas nem assinaturas.
          </Caption>
          <Row
            label="Restaurar compras"
            actionLabel="Verificar"
            onPress={() => requireGate('restorePurchases')}
          />
          <Row
            label="Gerenciar assinatura"
            hint="Abre a loja (futuras versões pagas)."
            actionLabel="Abrir loja"
            onPress={() => requireGate('manageSubscription')}
          />
        </Section>

        {/* ────────── 5. Acessibilidade e Pedagógico ────────── */}
        <Section title="Acessibilidade" locked={!unlocked}>
          <SliderLikeRow
            label="Narração"
            value={settings.volumeNarration}
            onChange={(v) => updateSettings({ volumeNarration: v })}
          />
          <SliderLikeRow
            label="Efeitos sonoros (SFX)"
            value={settings.volumeSfx}
            onChange={(v) => updateSettings({ volumeSfx: v })}
          />
          <SliderLikeRow
            label="Trilha sonora"
            value={settings.volumeMusic}
            onChange={(v) => updateSettings({ volumeMusic: v })}
          />

          <Divider label="Visual" />
          <SegmentedRow
            label="Tamanho do texto"
            options={['P', 'M', 'G', 'GG']}
            value={settings.textScale}
            onChange={(v) => updateSettings({ textScale: v })}
          />
          <SwitchRow
            label="Fonte para dislexia"
            hint="Usa uma fonte mais legível."
            value={settings.dyslexiaFont}
            onChange={(v) => updateSettings({ dyslexiaFont: v })}
          />
          <SwitchRow
            label="Alto contraste"
            hint="≥ 7:1 (WCAG AAA)."
            value={settings.highContrast}
            onChange={(v) => updateSettings({ highContrast: v })}
          />
          <SwitchRow
            label="Reduzir movimento"
            hint="Desativa animações longas."
            value={settings.reduceMotion}
            onChange={(v) => updateSettings({ reduceMotion: v })}
          />

          <Divider label="Entrada" />
          <SegmentedRow
            label="Método de entrada"
            options={['voice_touch', 'touch_only']}
            labels={{ voice_touch: '🎙️ Voz+Toque', touch_only: '👆 Só toque' }}
            value={settings.inputMethod}
            onChange={(v) => updateSettings({ inputMethod: v })}
          />
        </Section>

        <Section title="Pedagógico" locked={!unlocked}>
          <SegmentedRow
            label="Dificuldade"
            options={['auto', 'easy', 'hard']}
            labels={{ auto: '🤖 Auto', easy: '🌱 Iniciante', hard: '🚀 Avançado' }}
            value={settings.difficulty}
            onChange={(v) => updateSettings({ difficulty: v })}
          />
          <SwitchRow
            label="Relatório semanal por email"
            hint="Indisponível nesta versão (sem backend)."
            value={false}
            onChange={() => showToast('Recurso indisponível nesta versão.')}
            disabled
          />
          <Row
            label="Reiniciar progresso"
            hint="Mantém consentimento e preferências."
            actionLabel="Reiniciar"
            danger
            onPress={() => requireGate('resetProgress')}
          />
          <Row
            label="Revogar consentimento parental"
            hint="Encerra a sessão e volta à tela inicial de consentimento."
            actionLabel="Revogar"
            danger
            onPress={() => requireGate('revokeConsent')}
          />
        </Section>

        {/* ────────── 6. Suporte e Sobre ────────── */}
        <Section title="Suporte e Sobre">
          <KVRow label="Versão"     value={`v${appMeta.version} (build ${appMeta.build})`} />
          <KVRow label="Dispositivo" value={appMeta.device} />
          <KVRow
            label="Política aceita"
            value={consent.hasConsented
              ? `v${consent.policyVersion}${consent.policyVersion !== CURRENT_POLICY_VERSION ? ` ⚠️ desatualizada (atual v${CURRENT_POLICY_VERSION})` : ''}`
              : 'Pendente'}
          />
          <Row
            label="Fale conosco / Reportar bug"
            actionLabel="Abrir email"
            onPress={() => Linking.openURL(
              `mailto:${SUPPORT_EMAIL}?subject=${encodeURIComponent('[Alfabetização Mágica] Suporte')}&body=${encodeURIComponent(
                `Versão: ${appMeta.version} (build ${appMeta.build})\nDispositivo: ${appMeta.device}\n\nDescreva o problema:\n`,
              )}`,
            )}
          />
          <Caption>Resposta em até 48h úteis.</Caption>

          <Divider label="Licenças open-source" />
          <Row
            label="Licenças de Terceiros"
            hint="Bibliotecas open-source usadas no aplicativo."
            actionLabel="Abrir"
            onPress={() => navigation.navigate('OssLicenses')}
          />
        </Section>

        {/* ────────── 7. Auditoria local (Área dos Pais) ────────── */}
        {unlocked && (
          <Section title="Auditoria (apenas no aparelho)">
            <Caption>Últimos acessos à Área dos Pais — para sua revisão.</Caption>
            {(accessLog || []).slice(0, 10).map((e, i) => (
              <KVRow
                key={i}
                label={new Date(e.ts).toLocaleString('pt-BR')}
                value={e.method}
              />
            ))}
            {(!accessLog || accessLog.length === 0) && (
              <Caption>Nenhum acesso registrado ainda.</Caption>
            )}
            {accessLog && accessLog.length > 0 && (
              <Row
                label="Limpar log de acessos"
                actionLabel="Limpar"
                onPress={() => requireGate('clearAccessLog')}
              />
            )}
          </Section>
        )}

        {toast && (
          <View style={styles.toastWrap}>
            <Text style={styles.toast}>{toast}</Text>
          </View>
        )}

        <ParentalGate
          visible={gateOpen}
          title="Confirme que você é o responsável"
          onPass={handleGatePass}
          onCancel={handleGateCancel}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

/* ============================================================================
 * Linha auxiliar — abre página de assinatura na loja correta.
 * ========================================================================= */
function openSubscriptionDeepLink() {
  // Substitua pelo SKU real quando publicar.
  const sku = 'alfabetizacao.magica.premium.monthly';
  const pkg = 'app.alfabetizacaomagica';
  const androidUrl = `https://play.google.com/store/account/subscriptions?sku=${sku}&package=${pkg}`;
  const iosUrl     = 'itms-apps://apps.apple.com/account/subscriptions';
  const url = Platform.select({ android: androidUrl, ios: iosUrl, default: androidUrl });
  Linking.openURL(url).catch(() => {});
}

/* ============================================================================
 * Exporta TODO o estado local como JSON via Share (LGPD: portabilidade Art. 18).
 * ========================================================================= */
async function exportAllData(progress, consent, settings, accessLog) {
  const payload = {
    schema: 'alfabetizacao-magica/export@1',
    exportedAt: new Date().toISOString(),
    note: 'Este app é offline-first; nenhum dado é enviado a servidores. Este arquivo contém TODO o estado salvo no aparelho.',
    progress,
    consent,
    settings,
    accessLog,
  };
  try {
    const json = JSON.stringify(payload, null, 2);
    const result = await Share.share({
      title: 'Meus dados — Alfabetização Mágica',
      message: json,
    });
    return result.action !== Share.dismissedAction;
  } catch {
    return false;
  }
}

/* ============================================================================
 * Componentes auxiliares
 * ========================================================================= */
function Section({ title, locked, children }) {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{title}</Text>
        {locked && <Text style={styles.sectionLock}>🔒 Área dos Pais</Text>}
      </View>
      <View style={locked && styles.sectionLockedBody}>{children}</View>
    </View>
  );
}

function Row({ label, hint, actionLabel = 'Abrir', onPress, danger }) {
  return (
    <Pressable
      style={({ pressed }) => [styles.row, pressed && styles.rowPressed]}
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={`${label}. ${hint || ''} Botão ${actionLabel}.`}
    >
      <View style={{ flex: 1, paddingRight: 12 }}>
        <Text style={[styles.rowLabel, danger && styles.danger]}>{label}</Text>
        {hint && <Text style={styles.rowHint}>{hint}</Text>}
      </View>
      <Text style={[styles.rowAction, danger && styles.dangerAction]}>{actionLabel}</Text>
    </Pressable>
  );
}

function SwitchRow({ label, hint, value, onChange, disabled }) {
  return (
    <View style={styles.row}>
      <View style={{ flex: 1, paddingRight: 12 }}>
        <Text style={[styles.rowLabel, disabled && styles.disabled]}>{label}</Text>
        {hint && <Text style={styles.rowHint}>{hint}</Text>}
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        disabled={disabled}
        trackColor={{ true: '#F5C518', false: 'rgba(255,255,255,0.2)' }}
        thumbColor={value ? '#fff' : '#ddd'}
        accessibilityLabel={`${label}, ${value ? 'ativado' : 'desativado'}`}
      />
    </View>
  );
}

function KVRow({ label, value }) {
  return (
    <View style={styles.kvRow}>
      <Text style={styles.kvLabel}>{label}</Text>
      <Text style={styles.kvValue}>{value}</Text>
    </View>
  );
}

/**
 * Pseudo-slider em 5 passos (0/0.25/0.5/0.75/1).
 * Evita a dependência extra @react-native-community/slider.
 * Cada passo é um botão tocável — acessível por VoiceOver/TalkBack.
 */
function SliderLikeRow({ label, value, onChange }) {
  const steps = [0, 0.25, 0.5, 0.75, 1];
  return (
    <View style={styles.row}>
      <View style={{ flex: 1, paddingRight: 12 }}>
        <Text style={styles.rowLabel}>{label}</Text>
        <Text style={styles.rowHint}>{Math.round(value * 100)}%</Text>
      </View>
      <View style={styles.stepRow}>
        {steps.map((s) => {
          const active = Math.abs(value - s) < 0.05;
          return (
            <Pressable
              key={s}
              onPress={() => onChange(s)}
              style={[styles.stepDot, active && styles.stepDotActive]}
              accessibilityRole="adjustable"
              accessibilityLabel={`${label}: ${Math.round(s * 100)}%`}
              accessibilityState={{ selected: active }}
            />
          );
        })}
      </View>
    </View>
  );
}

function SegmentedRow({ label, options, value, onChange, labels }) {
  return (
    <View style={styles.segWrap}>
      <Text style={styles.rowLabel}>{label}</Text>
      <View style={styles.segRow}>
        {options.map((opt) => {
          const active = value === opt;
          return (
            <Pressable
              key={opt}
              onPress={() => onChange(opt)}
              style={[styles.seg, active && styles.segActive]}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
            >
              <Text style={[styles.segText, active && styles.segTextActive]}>
                {labels ? labels[opt] : opt}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function Divider({ label }) {
  return (
    <View style={styles.divider}>
      <Text style={styles.dividerText}>{label}</Text>
    </View>
  );
}

function Caption({ children }) {
  return <Text style={styles.caption}>{children}</Text>;
}

/* ============================================================================
 * Styles (dark theme alinhado ao app)
 * ========================================================================= */
const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 16, paddingBottom: 60 },

  h1:    { color: '#fff', fontSize: 26, fontWeight: '800' },
  h1Sub: { color: 'rgba(255,255,255,0.7)', marginTop: 4, marginBottom: 16, fontSize: 13 },

  section: {
    backgroundColor: '#1B2B3A',
    borderRadius: 16,
    padding: 14,
    marginBottom: 12,
  },
  sectionHeader: {
    flexDirection: 'row', alignItems: 'center',
    justifyContent: 'space-between', marginBottom: 10,
  },
  sectionTitle:      { color: '#F5C518', fontSize: 14, fontWeight: '800' },
  sectionLock:       { color: 'rgba(255,255,255,0.45)', fontSize: 11, fontWeight: '600' },
  sectionLockedBody: { opacity: 0.55 },

  row: {
    flexDirection: 'row', alignItems: 'center',
    paddingVertical: 12,
    minHeight: 48,
    borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: 'rgba(255,255,255,0.08)',
  },
  rowPressed: { opacity: 0.7 },
  rowLabel:   { color: '#fff', fontSize: 15, fontWeight: '600' },
  rowHint:    { color: 'rgba(255,255,255,0.55)', fontSize: 12, marginTop: 2 },
  rowAction:  { color: '#F5C518', fontSize: 13, fontWeight: '700' },
  danger:       { color: '#ffb4b4' },
  dangerAction: { color: '#ffb4b4' },
  disabled:     { color: 'rgba(255,255,255,0.4)' },

  kvRow:   { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 6 },
  kvLabel: { color: 'rgba(255,255,255,0.7)', fontSize: 13, flex: 1, paddingRight: 8 },
  kvValue: { color: '#fff', fontSize: 13, fontWeight: '600' },

  stepRow:       { flexDirection: 'row', gap: 6 },
  stepDot:       { width: 18, height: 18, borderRadius: 9, backgroundColor: 'rgba(255,255,255,0.15)' },
  stepDotActive: { backgroundColor: '#F5C518' },

  segWrap: { paddingVertical: 10, borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: 'rgba(255,255,255,0.08)' },
  segRow:  { flexDirection: 'row', gap: 6, marginTop: 8, flexWrap: 'wrap' },
  seg:     {
    paddingHorizontal: 12, paddingVertical: 8,
    borderRadius: 10, backgroundColor: 'rgba(255,255,255,0.08)',
    minHeight: 36, justifyContent: 'center',
  },
  segActive:     { backgroundColor: '#F5C518' },
  segText:       { color: '#fff', fontSize: 13, fontWeight: '600' },
  segTextActive: { color: '#0E2A47', fontWeight: '800' },

  divider:     {
    marginTop: 12, marginBottom: 6,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(245,197,24,0.3)',
    paddingBottom: 4,
  },
  dividerText: { color: '#F5C518', fontSize: 11, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 0.5 },

  caption:     { color: 'rgba(255,255,255,0.55)', fontSize: 12, marginTop: 6, lineHeight: 17 },
  captionBold: { color: '#fff', fontWeight: '700' },

  toastWrap: {
    marginTop: 18, padding: 12,
    backgroundColor: 'rgba(154,225,154,0.12)',
    borderRadius: 12, borderWidth: 1, borderColor: 'rgba(154,225,154,0.3)',
  },
  toast: { color: '#9AE19A', textAlign: 'center', fontSize: 13, fontWeight: '600' },
});
