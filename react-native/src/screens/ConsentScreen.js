/**
 * ConsentScreen.js
 * -----------------------------------------------------------------------------
 * Tela de consentimento parental + aviso LGPD.
 *
 * Exibida no primeiro acesso e sempre que a política for atualizada
 * (CURRENT_POLICY_VERSION). Bloqueia o acesso ao app até um adulto
 * confirmar via ParentalGate.
 *
 * Princípios:
 *   - Texto curto, direto, sem juridiquês inútil.
 *   - Destaque para: "dados ficam no aparelho", "sem cadastro", "sem anúncios".
 *   - Microfone é opt-in SEPARADO (não acoplado ao consentimento geral).
 *   - Cancelar mantém usuário na tela (não há "app demo sem consentimento").
 * -----------------------------------------------------------------------------
 */

import React, { useState } from 'react';
import { View, Text, Pressable, StyleSheet, ScrollView, Switch } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

import ParentalGate from '../components/ParentalGate';
import { useConsentStore, CURRENT_POLICY_VERSION } from '../store/consentStore';

export default function ConsentScreen() {
  const navigation = useNavigation();
  const grant = useConsentStore((s) => s.grant);
  const setMicrophone = useConsentStore((s) => s.setMicrophone);

  const [gateOpen, setGateOpen] = useState(false);
  const [micOptIn, setMicOptIn] = useState(false);

  const handleAccept = () => setGateOpen(true);

  const handleGatePass = () => {
    grant();
    setMicrophone(micOptIn);
    setGateOpen(false);
    navigation.reset({ index: 0, routes: [{ name: 'MainTabs' }] });
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Bem-vindo(a)!</Text>
        <Text style={styles.subtitle}>
          Antes de começar, precisamos da confirmação de um adulto responsável.
        </Text>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Como cuidamos dos dados da criança</Text>

          <Row icon="📱" text="Tudo fica salvo apenas neste aparelho — nenhum dado vai para servidores." />
          <Row icon="🚫" text="Sem cadastro, sem login, sem coleta de e-mail, nome ou telefone." />
          <Row icon="🛡️" text="Sem anúncios, sem rastreadores, sem compras dentro do app." />
          <Row icon="🎤" text="O microfone fica DESLIGADO por padrão. Você decide ativar ou não, abaixo." />
          <Row icon="↩️" text="Você pode revogar o consentimento a qualquer momento em Perfil." />

          <Text style={styles.lgpd}>
            Conformidade com a LGPD (Lei nº 13.709/2018). Política versão {CURRENT_POLICY_VERSION}.
          </Text>
        </View>

        <Pressable
          style={styles.micRow}
          onPress={() => setMicOptIn(!micOptIn)}
          accessibilityRole="switch"
          accessibilityState={{ checked: micOptIn }}
          accessibilityLabel="Permitir uso do microfone para atividades de leitura em voz alta"
        >
          <View style={{ flex: 1 }}>
            <Text style={styles.micTitle}>Permitir uso do microfone</Text>
            <Text style={styles.micHint}>
              Usado apenas durante atividades de leitura em voz alta. O áudio é
              processado no aparelho e descartado em seguida.
            </Text>
          </View>
          <Switch
            value={micOptIn}
            onValueChange={setMicOptIn}
            trackColor={{ false: 'rgba(255,255,255,0.2)', true: '#F5C518' }}
            thumbColor="#fff"
          />
        </Pressable>

        <Pressable
          style={styles.btn}
          onPress={handleAccept}
          accessibilityRole="button"
          accessibilityLabel="Confirmar como responsável e aceitar"
        >
          <Text style={styles.btnText}>Sou responsável e concordo</Text>
        </Pressable>

        <Text style={styles.footnote}>
          Toque acima para abrir a verificação para adultos.
        </Text>

        <ParentalGate
          visible={gateOpen}
          title="Confirme que você é o responsável"
          onCancel={() => setGateOpen(false)}
          onPass={handleGatePass}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

function Row({ icon, text }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowIcon}>{icon}</Text>
      <Text style={styles.rowText}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  safe:   { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 20, paddingBottom: 40 },

  title:    { color: '#fff', fontSize: 26, fontWeight: '800', textAlign: 'center', marginTop: 12 },
  subtitle: { color: 'rgba(255,255,255,0.75)', fontSize: 14, textAlign: 'center', marginTop: 6, marginBottom: 20 },

  card: {
    backgroundColor: '#1B2B3A',
    borderRadius: 18, padding: 18,
    marginBottom: 20,
  },
  cardTitle: { color: '#F5C518', fontSize: 16, fontWeight: '800', marginBottom: 12 },
  row:       { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 10, gap: 10 },
  rowIcon:   { fontSize: 18, width: 24, textAlign: 'center' },
  rowText:   { color: '#fff', flex: 1, fontSize: 13, lineHeight: 18 },
  lgpd:      { color: 'rgba(255,255,255,0.55)', fontSize: 11, marginTop: 8, fontStyle: 'italic' },

  micRow: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: '#1B2B3A', borderRadius: 14,
    padding: 14, marginBottom: 20, minHeight: 48,
  },
  micTitle: { color: '#fff', fontSize: 14, fontWeight: '700' },
  micHint:  { color: 'rgba(255,255,255,0.65)', fontSize: 11, lineHeight: 14, marginTop: 4 },

  btn: {
    backgroundColor: '#F5C518',
    paddingHorizontal: 24, paddingVertical: 14,
    borderRadius: 28, minHeight: 48, alignItems: 'center',
  },
  btnText: { color: '#0E2A47', fontWeight: '800', fontSize: 16 },
  footnote: { color: 'rgba(255,255,255,0.5)', fontSize: 11, textAlign: 'center', marginTop: 10 },
});
