/**
 * BairroScreen.js — Bairro das Famílias (Phase 2)
 * -----------------------------------------------------------------------------
 * Hub das 5 "casas" das famílias silábicas (B, C, D, F, M).
 *
 * - Cada casa abre um fluxo Aprender+Desafio reutilizado de
 *   SyllableLearnChallenge.
 * - Ao concluir o desafio de uma família, ela é marcada em
 *   progressStore.phaseChallenges.bairro.
 * - Ao concluir TODAS as 5 famílias → completeWorld('bairro') + volta ao mapa.
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useMemo, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

import SyllableLearnChallenge from '../../components/SyllableLearnChallenge';
import { FAMILIES, FAMILY_IDS } from '../../data/phase2Syllables';
import { useProgressStore } from '../../store/progressStore';

const WORLD_ID = 'bairro';

export default function BairroScreen() {
  const navigation = useNavigation();
  const passed = useProgressStore((s) => s.progress.phaseChallenges?.bairro || []);
  const markChallengePassed = useProgressStore((s) => s.markChallengePassed);
  const completeWorld = useProgressStore((s) => s.completeWorld);

  const [activeFamilyId, setActiveFamilyId] = useState(null);

  const activeFamily = useMemo(
    () => FAMILIES.find((f) => f.id === activeFamilyId),
    [activeFamilyId],
  );

  const allFamiliesDone = useMemo(
    () => FAMILY_IDS.every((id) => passed.includes(id)),
    [passed],
  );

  const handleFamilyComplete = useCallback(() => {
    if (!activeFamily) return;
    markChallengePassed(WORLD_ID, activeFamily.id);
    setActiveFamilyId(null);
  }, [activeFamily, markChallengePassed]);

  const handleFinishWorld = useCallback(() => {
    completeWorld(WORLD_ID);
    navigation.navigate('WorldMap');
  }, [completeWorld, navigation]);

  // ─── Modo "sala da família" ─────────────────────────────────────────
  if (activeFamily) {
    return (
      <SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}>
        <Pressable
          style={styles.backBtn}
          onPress={() => setActiveFamilyId(null)}
          accessibilityRole="button"
          accessibilityLabel="Voltar para o bairro"
        >
          <Text style={styles.backText}>← Bairro</Text>
        </Pressable>
        <SyllableLearnChallenge
          worldId={WORLD_ID}
          groupId={activeFamily.id}
          title={`${activeFamily.emoji} ${activeFamily.label}`}
          items={activeFamily.syllables}
          onComplete={handleFamilyComplete}
        />
      </SafeAreaView>
    );
  }

  // ─── Modo "hub do bairro" (mapa das casas) ──────────────────────────
  return (
    <SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Bairro das Famílias</Text>
        <Text style={styles.subtitle}>
          Visite cada casa para conhecer as famílias de sílabas.
        </Text>

        <View style={styles.grid}>
          {FAMILIES.map((fam) => {
            const done = passed.includes(fam.id);
            return (
              <Pressable
                key={fam.id}
                onPress={() => setActiveFamilyId(fam.id)}
                accessibilityRole="button"
                accessibilityLabel={fam.label}
                accessibilityHint={done ? 'Família já concluída. Pode revisitar.' : 'Entrar na casa desta família.'}
                style={[styles.house, { backgroundColor: fam.color }]}
              >
                <Text style={styles.houseEmoji}>{fam.emoji}</Text>
                <Text style={styles.houseLetter}>{fam.letter}</Text>
                <Text style={styles.houseLabel}>{fam.label}</Text>
                {done && <Text style={styles.houseCheck}>✓</Text>}
              </Pressable>
            );
          })}
        </View>

        <Text style={styles.progressText}>
          Famílias concluídas: {passed.length}/{FAMILY_IDS.length}
        </Text>

        {allFamiliesDone && (
          <Pressable
            style={styles.btn}
            onPress={handleFinishWorld}
            accessibilityRole="button"
            accessibilityLabel="Concluir Bairro das Famílias e voltar ao mapa"
          >
            <Text style={styles.btnText}>Concluir Bairro ✨</Text>
          </Pressable>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 20, alignItems: 'center' },

  title:    { color: '#fff', fontSize: 24, fontWeight: '800', textAlign: 'center' },
  subtitle: { color: 'rgba(255,255,255,0.75)', marginTop: 6, marginBottom: 18, textAlign: 'center' },

  grid: {
    flexDirection: 'row', flexWrap: 'wrap',
    justifyContent: 'center', gap: 14,
  },
  house: {
    width: 140, minHeight: 140, padding: 12,
    borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
    elevation: 4,
    shadowColor: '#000', shadowOpacity: 0.25, shadowRadius: 6, shadowOffset: { width: 0, height: 3 },
  },
  houseEmoji:  { fontSize: 38 },
  houseLetter: { color: '#fff', fontSize: 32, fontWeight: '900', marginTop: 2 },
  houseLabel:  { color: 'rgba(255,255,255,0.95)', fontSize: 12, marginTop: 4, textAlign: 'center' },
  houseCheck:  { position: 'absolute', top: 6, right: 10, color: '#fff', fontSize: 20, fontWeight: '800' },

  progressText: { color: 'rgba(255,255,255,0.7)', marginTop: 20, fontSize: 13 },

  btn: {
    marginTop: 16, backgroundColor: '#F5C518',
    paddingHorizontal: 28, paddingVertical: 14,
    borderRadius: 28, minHeight: 48, alignItems: 'center',
  },
  btnText: { color: '#0E2A47', fontWeight: '800', fontSize: 16 },

  backBtn: { paddingHorizontal: 16, paddingVertical: 10, minHeight: 48, alignSelf: 'flex-start' },
  backText: { color: '#F5C518', fontWeight: '700', fontSize: 15 },
});
