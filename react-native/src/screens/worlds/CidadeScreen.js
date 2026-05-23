/**
 * CidadeScreen.js — Cidade das Sílabas (Phase 3)
 * -----------------------------------------------------------------------------
 * Hub das 11 famílias silábicas restantes (G, J, L, N, P, R, S, T, V, X, Z).
 * Reusa SyllableLearnChallenge com a fase "palavras" para mostrar como as
 * sílabas de diferentes famílias se combinam para formar palavras.
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useMemo, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

import SyllableLearnChallenge from '../../components/SyllableLearnChallenge';
import { FAMILIES_PHASE3, FAMILY_IDS_PHASE3 } from '../../data/phase3Syllables';
import { useProgressStore } from '../../store/progressStore';

const WORLD_ID = 'cidade';

export default function CidadeScreen() {
  const navigation = useNavigation();
  const passed = useProgressStore((s) => s.progress.phaseChallenges?.cidade || []);
  const markChallengePassed = useProgressStore((s) => s.markChallengePassed);
  const completeWorld = useProgressStore((s) => s.completeWorld);

  const [activeFamilyId, setActiveFamilyId] = useState(null);

  const activeFamily = useMemo(
    () => FAMILIES_PHASE3.find((f) => f.id === activeFamilyId),
    [activeFamilyId],
  );

  const allDone = useMemo(
    () => FAMILY_IDS_PHASE3.every((id) => passed.includes(id)),
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

  if (activeFamily) {
    return (
      <SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}>
        <Pressable
          style={styles.backBtn}
          onPress={() => setActiveFamilyId(null)}
          accessibilityRole="button"
          accessibilityLabel="Voltar para a cidade"
        >
          <Text style={styles.backText}>← Cidade</Text>
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

  return (
    <SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Cidade das Sílabas</Text>
        <Text style={styles.subtitle}>
          Conheça as famílias silábicas e aprenda a formar palavras!
        </Text>

        <View style={styles.grid}>
          {FAMILIES_PHASE3.map((family) => {
            const done = passed.includes(family.id);
            return (
              <Pressable
                key={family.id}
                onPress={() => setActiveFamilyId(family.id)}
                accessibilityRole="button"
                accessibilityLabel={family.label}
                accessibilityHint={done ? 'Já concluído. Pode revisitar.' : 'Entrar nesta família.'}
                style={[styles.tile, { backgroundColor: family.color }]}
              >
                <Text style={styles.tileEmoji}>{family.emoji}</Text>
                <Text style={styles.tileLetter}>{family.letter}</Text>
                <Text style={styles.tileLabel}>{family.label}</Text>
                {done && <Text style={styles.tileCheck}>✓</Text>}
              </Pressable>
            );
          })}
        </View>

        <Text style={styles.progressText}>
          Famílias visitadas: {passed.length}/{FAMILY_IDS_PHASE3.length}
        </Text>

        {allDone && (
          <Pressable
            style={styles.btn}
            onPress={handleFinishWorld}
            accessibilityRole="button"
            accessibilityLabel="Concluir Cidade dos Encontros e voltar ao mapa"
          >
            <Text style={styles.btnText}>Concluir Cidade das Sílabas ✨</Text>
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
  tile: {
    width: 140, minHeight: 140, padding: 12,
    borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
    elevation: 4,
    shadowColor: '#000', shadowOpacity: 0.25, shadowRadius: 6, shadowOffset: { width: 0, height: 3 },
  },
  tileEmoji:  { fontSize: 38 },
  tileLetter: { color: '#fff', fontSize: 28, fontWeight: '900', marginTop: 2 },
  tileLabel:  { color: 'rgba(255,255,255,0.95)', fontSize: 12, marginTop: 4, textAlign: 'center' },
  tileCheck:  { position: 'absolute', top: 6, right: 10, color: '#fff', fontSize: 20, fontWeight: '800' },

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
