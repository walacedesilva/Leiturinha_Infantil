/**
 * PerfilScreen.js
 * -----------------------------------------------------------------------------
 * Tela de perfil. Ações sensíveis (reset, revogar consentimento, alternar
 * microfone) ficam atrás do ParentalGate (QA P0 / CRIT-001).
 * Exibe estado atual de consentimento e LGPD.
 * -----------------------------------------------------------------------------
 */

import React, { useState } from 'react';
import { View, Text, Pressable, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

import { useProgressStore } from '../store/progressStore';
import { useConsentStore, CURRENT_POLICY_VERSION } from '../store/consentStore';
import ParentalGate from '../components/ParentalGate';

export default function PerfilScreen() {
  const navigation = useNavigation();
  const reset = useProgressStore((s) => s.resetProgress);
  const consent = useConsentStore((s) => s.consent);
  const setMicrophone = useConsentStore((s) => s.setMicrophone);
  const revoke = useConsentStore((s) => s.revoke);

  const [gateOpen, setGateOpen] = useState(false);
  const [pendingAction, setPendingAction] = useState(null); // 'reset' | 'revoke' | 'toggleMic'
  const [toast, setToast] = useState(null);

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2000);
  };

  const requestAction = (action) => {
    setPendingAction(action);
    setGateOpen(true);
  };

  const handleGatePass = () => {
    setGateOpen(false);
    switch (pendingAction) {
      case 'reset':
        reset();
        showToast('Progresso reiniciado.');
        break;
      case 'revoke':
        revoke();
        navigation.reset({ index: 0, routes: [{ name: 'Consent' }] });
        break;
      case 'toggleMic':
        setMicrophone(!consent.microphoneAllowed);
        showToast(consent.microphoneAllowed ? 'Microfone desligado.' : 'Microfone ativado.');
        break;
    }
    setPendingAction(null);
  };

  const gateTitle = {
    reset:     'Reiniciar a jornada apagará todo o progresso',
    revoke:    'Revogar consentimento e sair do app',
    toggleMic: consent.microphoneAllowed ? 'Desativar microfone' : 'Ativar microfone',
  }[pendingAction] || 'Confirme que você é o responsável';

  return (
    <SafeAreaView style={styles.root}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Perfil</Text>
        <Text style={styles.sub}>
          Ações sensíveis exigem verificação para adultos.
        </Text>

        <Section title="Privacidade e LGPD">
          <Row label="Consentimento parental" value={consent.hasConsented ? 'Concedido' : 'Pendente'} />
          {consent.consentedAt && (
            <Row label="Em" value={new Date(consent.consentedAt).toLocaleDateString('pt-BR')} />
          )}
          <Row label="Versão da política" value={`v${consent.policyVersion ?? '—'} (atual: v${CURRENT_POLICY_VERSION})`} />
          <Row label="Microfone" value={consent.microphoneAllowed ? 'Ativado' : 'Desativado'} />
        </Section>

        <Pressable
          style={styles.btnRow}
          onPress={() => requestAction('toggleMic')}
          accessibilityRole="button"
          accessibilityLabel={consent.microphoneAllowed ? 'Desativar microfone' : 'Ativar microfone'}
        >
          <Text style={styles.btnRowText}>
            {consent.microphoneAllowed ? '🎤 Desativar microfone' : '🎤 Ativar microfone'}
          </Text>
        </Pressable>

        <Pressable
          style={styles.btnRow}
          onPress={() => requestAction('reset')}
          accessibilityRole="button"
          accessibilityLabel="Reiniciar jornada (requer verificação para adultos)"
        >
          <Text style={styles.btnRowText}>♻️ Reiniciar jornada</Text>
        </Pressable>

        <Pressable
          style={[styles.btnRow, styles.btnDanger]}
          onPress={() => requestAction('revoke')}
          accessibilityRole="button"
          accessibilityLabel="Revogar consentimento parental"
        >
          <Text style={[styles.btnRowText, { color: '#ffb4b4' }]}>
            ⛔ Revogar consentimento
          </Text>
        </Pressable>

        {toast && <Text style={styles.toast}>{toast}</Text>}

        <ParentalGate
          visible={gateOpen}
          title={gateTitle}
          onCancel={() => { setGateOpen(false); setPendingAction(null); }}
          onPass={handleGatePass}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

function Section({ title, children }) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {children}
    </View>
  );
}

function Row({ label, value }) {
  return (
    <View style={styles.kvRow}>
      <Text style={styles.kvLabel}>{label}</Text>
      <Text style={styles.kvValue}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 20, paddingBottom: 40 },

  title: { color: '#fff', fontSize: 24, fontWeight: '800' },
  sub:   { color: 'rgba(255,255,255,0.7)', marginTop: 6, marginBottom: 18, fontSize: 13 },

  section: {
    backgroundColor: '#1B2B3A',
    borderRadius: 14, padding: 14, marginBottom: 16,
  },
  sectionTitle: { color: '#F5C518', fontSize: 14, fontWeight: '800', marginBottom: 10 },
  kvRow:    { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 },
  kvLabel:  { color: 'rgba(255,255,255,0.7)', fontSize: 13 },
  kvValue:  { color: '#fff', fontSize: 13, fontWeight: '600' },

  btnRow: {
    backgroundColor: '#1B2B3A', borderRadius: 14,
    padding: 14, marginBottom: 10, minHeight: 48,
    justifyContent: 'center',
  },
  btnRowText: { color: '#fff', fontSize: 15, fontWeight: '700' },
  btnDanger:  { borderWidth: 1, borderColor: 'rgba(255,180,180,0.4)' },

  toast: { color: '#9AE19A', marginTop: 14, fontSize: 13, textAlign: 'center' },
});
