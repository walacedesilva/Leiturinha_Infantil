/**
 * OssLicensesScreen.js
 * -----------------------------------------------------------------------------
 * Tela "Licenças de Terceiros" — exigência de Google Play / App Store e
 * boa prática de compliance (LGPD-K: transparência).
 *
 * Estratégia adotada:
 *   - Mantemos um arquivo estático em `src/data/ossLicenses.js` gerado
 *     manualmente (ou via script futuro `scripts/gen-oss-licenses.js`).
 *   - Não usamos `react-native-oss-licenses` direto porque ele depende de
 *     processo Node em runtime de build; o arquivo estático é mais simples
 *     e auditável.
 *   - Cada item: { name, version, license, url, licenseText? }
 *   - Botão "Abrir repositório" → Linking.openURL.
 *   - Texto integral da licença disponível em modal (quando presente).
 * -----------------------------------------------------------------------------
 */

import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  ScrollView,
  Linking,
  Modal,
  TextInput,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import OSS_LICENSES from '../data/ossLicenses';

export default function OssLicensesScreen() {
  const [query, setQuery] = useState('');
  const [selected, setSelected] = useState(null); // item completo

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return OSS_LICENSES;
    return OSS_LICENSES.filter(
      (l) =>
        l.name.toLowerCase().includes(q) ||
        (l.license || '').toLowerCase().includes(q),
    );
  }, [query]);

  return (
    <SafeAreaView style={styles.root} edges={['top']}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Licenças de Terceiros</Text>
        <Text style={styles.subtitle}>
          Este aplicativo é construído sobre projetos de código aberto.
          Listamos abaixo as bibliotecas usadas e suas respectivas licenças.
        </Text>

        <TextInput
          value={query}
          onChangeText={setQuery}
          placeholder="Buscar (ex: react, MIT)…"
          placeholderTextColor="rgba(255,255,255,0.45)"
          style={styles.search}
          autoCapitalize="none"
          autoCorrect={false}
          accessibilityLabel="Buscar licenças"
        />

        <Text style={styles.counter}>
          {filtered.length} de {OSS_LICENSES.length} pacote(s)
        </Text>

        {filtered.map((item) => (
          <Pressable
            key={item.name}
            style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
            onPress={() => setSelected(item)}
            accessibilityRole="button"
            accessibilityLabel={`${item.name} versão ${item.version || 'n/d'}, licença ${item.license}`}
          >
            <View style={{ flex: 1, paddingRight: 12 }}>
              <Text style={styles.cardName}>{item.name}</Text>
              {item.version && (
                <Text style={styles.cardVer}>v{item.version}</Text>
              )}
            </View>
            <View style={styles.licenseBadge}>
              <Text style={styles.licenseBadgeText}>{item.license}</Text>
            </View>
          </Pressable>
        ))}

        {filtered.length === 0 && (
          <Text style={styles.empty}>Nenhum pacote encontrado.</Text>
        )}

        <View style={styles.footer}>
          <Text style={styles.footerText}>
            Sentiu falta de algum pacote? Envie um email para{' '}
            <Text
              style={styles.link}
              onPress={() =>
                Linking.openURL('mailto:suporte@alfabetizacaomagica.app?subject=Licença%20OSS%20faltando')
              }
            >
              suporte@alfabetizacaomagica.app
            </Text>
            .
          </Text>
        </View>
      </ScrollView>

      <Modal
        visible={!!selected}
        animationType="slide"
        transparent
        onRequestClose={() => setSelected(null)}
      >
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>{selected?.name}</Text>
            <Text style={styles.modalSub}>
              {selected?.version ? `v${selected.version} · ` : ''}
              Licença {selected?.license}
            </Text>

            {!!selected?.url && (
              <Pressable
                style={styles.modalLink}
                onPress={() => Linking.openURL(selected.url)}
              >
                <Text style={styles.modalLinkText}>Abrir repositório ↗</Text>
              </Pressable>
            )}

            <ScrollView style={styles.modalLicense}>
              <Text style={styles.modalLicenseText}>
                {selected?.licenseText ||
                  `Texto integral da licença ${selected?.license || ''} disponível no repositório oficial do pacote.`}
              </Text>
            </ScrollView>

            <Pressable
              style={styles.modalClose}
              onPress={() => setSelected(null)}
              accessibilityRole="button"
              accessibilityLabel="Fechar"
            >
              <Text style={styles.modalCloseText}>Fechar</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#0E2A47' },
  content: { padding: 16, paddingBottom: 48 },

  title: { color: '#fff', fontSize: 22, fontWeight: '800', marginBottom: 6 },
  subtitle: { color: 'rgba(255,255,255,0.75)', fontSize: 14, lineHeight: 20, marginBottom: 14 },

  search: {
    backgroundColor: '#1B2B3A',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: '#fff',
    fontSize: 15,
    marginBottom: 8,
  },
  counter: {
    color: 'rgba(255,255,255,0.55)',
    fontSize: 12,
    marginBottom: 10,
  },

  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1B2B3A',
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 8,
    minHeight: 56,
  },
  cardPressed: { opacity: 0.7 },
  cardName: { color: '#fff', fontSize: 15, fontWeight: '600' },
  cardVer:  { color: 'rgba(255,255,255,0.55)', fontSize: 12, marginTop: 2 },

  licenseBadge: {
    backgroundColor: 'rgba(245,197,24,0.15)',
    borderColor: '#F5C518',
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  licenseBadgeText: { color: '#F5C518', fontSize: 12, fontWeight: '700' },

  empty: { color: 'rgba(255,255,255,0.55)', textAlign: 'center', marginTop: 24 },

  footer: { marginTop: 20, padding: 12, backgroundColor: '#1B2B3A', borderRadius: 10 },
  footerText: { color: 'rgba(255,255,255,0.7)', fontSize: 12, lineHeight: 18 },
  link: { color: '#F5C518', textDecorationLine: 'underline' },

  // Modal
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'flex-end',
  },
  modalCard: {
    backgroundColor: '#0E2A47',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    maxHeight: '85%',
  },
  modalTitle: { color: '#fff', fontSize: 18, fontWeight: '700' },
  modalSub:   { color: 'rgba(255,255,255,0.65)', fontSize: 13, marginTop: 4 },
  modalLink:  { marginTop: 10 },
  modalLinkText: { color: '#F5C518', fontWeight: '600' },
  modalLicense: {
    marginTop: 14,
    maxHeight: 280,
    backgroundColor: '#1B2B3A',
    borderRadius: 8,
    padding: 12,
  },
  modalLicenseText: {
    color: 'rgba(255,255,255,0.85)',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    fontSize: 12,
    lineHeight: 18,
  },
  modalClose: {
    marginTop: 14,
    backgroundColor: '#F5C518',
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  modalCloseText: { color: '#0E2A47', fontWeight: '800', fontSize: 15 },
});
