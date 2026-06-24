/**
 * ReinoScreen.js — Reino das Histórias (Phase 4)
 * -----------------------------------------------------------------------------
 * Hub das 3 histórias do reino. Cada história é uma sequência de páginas
 * onde a criança lê em voz alta a palavra-alvo destacada. Conclusão de
 * todas as páginas → marca a história em phaseChallenges.reino.
 * Quando as 3 histórias estiverem concluídas → completeWorld('reino').
 *
 * Pedagogia:
 *   - Sem múltipla escolha; validação diegética pela leitura em voz alta.
 *   - Se mic estiver desativado, ReadAloudButton mostra bloqueio elegante
 *     com CTA para Perfil (não trava o app).
 *   - Vocabulário recicla o que foi visto nas fases anteriores.
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useMemo, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

import ReadAloudButton from '../../components/ReadAloudButton';
import { STORIES, STORY_IDS } from '../../data/phase4Stories';
import { useProgressStore } from '../../store/progressStore';

const WORLD_ID = 'reino';

export default function ReinoScreen() {
  const navigation = useNavigation();
  const passed = useProgressStore((s) => s.progress.phaseChallenges?.reino || []);
  const markChallengePassed = useProgressStore((s) => s.markChallengePassed);
  const completeWorld = useProgressStore((s) => s.completeWorld);

  const [activeStoryId, setActiveStoryId] = useState(null);
  const [pageIdx, setPageIdx] = useState(0);

  const activeStory = useMemo(
    () => STORIES.find((s) => s.id === activeStoryId),
    [activeStoryId],
  );

  const allDone = useMemo(
    () => STORY_IDS.every((id) => passed.includes(id)),
    [passed],
  );

  const openStory = (id) => {
    setActiveStoryId(id);
    setPageIdx(0);
  };

  const closeStory = () => {
    setActiveStoryId(null);
    setPageIdx(0);
  };

  const handlePageSuccess = useCallback(() => {
    if (!activeStory) return;
    const nextIdx = pageIdx + 1;
    if (nextIdx >= activeStory.pages.length) {
      markChallengePassed(WORLD_ID, activeStory.id);
      setTimeout(closeStory, 600);
      return;
    }
    setPageIdx(nextIdx);
  }, [activeStory, pageIdx, markChallengePassed]);

  const handleFinishWorld = useCallback(() => {
    completeWorld(WORLD_ID);
    navigation.navigate('WorldMap');
  }, [completeWorld, navigation]);

  // ─── Modo "leitor de história" ──────────────────────────────────────
  if (activeStory) {
    const page = activeStory.pages[pageIdx];
    const parts = page.text.split('{target}');

    return (
      <SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}>
        <Pressable style={styles.backBtn} onPress={closeStory} accessibilityRole="button" accessibilityLabel="Voltar para o reino">
          <Text style={styles.backText}>← Reino</Text>
        </Pressable>

        <ScrollView contentContainerStyle={styles.scroll}>
          <Text style={styles.storyTitle}>{activeStory.emoji} {activeStory.title}</Text>
          <Text style={styles.pageBadge}>Página {pageIdx + 1} de {activeStory.pages.length}</Text>

          <View style={[styles.pageCard, { borderColor: activeStory.color }]}>
            <Text style={styles.pageText}>
              {parts[0]}
              <Text style={[styles.pageTarget, { color: activeStory.color }]}>{page.target}</Text>
              {parts[1]}
            </Text>
          </View>

          <ReadAloudButton
            key={`${activeStory.id}-${pageIdx}`}
            target={page.target}
            hint="Leia esta palavra:"
            onSuccess={handlePageSuccess}
          />
        </ScrollView>
      </SafeAreaView>
    );
  }

  // ─── Modo "hub do reino" ────────────────────────────────────────────
  return (
    <SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Reino das Histórias</Text>
        <Text style={styles.subtitle}>
          Escolha uma história e leia em voz alta as palavras destacadas.
        </Text>

        <View style={styles.grid}>
          {STORIES.map((story) => {
            const done = passed.includes(story.id);
            return (
              <Pressable
                key={story.id}
                onPress={() => openStory(story.id)}
                accessibilityRole="button"
                accessibilityLabel={story.title}
                accessibilityHint={done ? 'História concluída. Pode revisitar.' : 'Abrir esta história.'}
                style={[styles.tile, { backgroundColor: story.color }]}
              >
                <Text style={styles.tileEmoji}>{story.emoji}</Text>
                <Text style={styles.tileLabel}>{story.title}</Text>
                {done && <Text style={styles.tileCheck}>✓</Text>}
              </Pressable>
            );
          })}
        </View>

        <Text style={styles.progressText}>
          Histórias concluídas: {passed.length}/{STORY_IDS.length}
        </Text>

        {allDone && (
          <Pressable
            style={styles.btn}
            onPress={handleFinishWorld}
            accessibilityRole="button"
            accessibilityLabel="Concluir Reino das Histórias e voltar ao mapa"
          >
            <Text style={styles.btnText}>Concluir Reino ✨</Text>
          </Pressable>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe:   { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 20, alignItems: 'center', paddingBottom: 40 },

  title:    { color: '#fff', fontSize: 24, fontWeight: '800', textAlign: 'center' },
  subtitle: { color: 'rgba(255,255,255,0.75)', marginTop: 6, marginBottom: 18, textAlign: 'center' },

  grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 14 },
  tile: {
    width: 150, minHeight: 150, padding: 14,
    borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
    elevation: 4,
    shadowColor: '#000', shadowOpacity: 0.25, shadowRadius: 6, shadowOffset: { width: 0, height: 3 },
  },
  tileEmoji: { fontSize: 40 },
  tileLabel: { color: '#fff', fontSize: 13, fontWeight: '700', textAlign: 'center', marginTop: 6 },
  tileCheck: { position: 'absolute', top: 6, right: 10, color: '#fff', fontSize: 20, fontWeight: '800' },

  progressText: { color: 'rgba(255,255,255,0.7)', marginTop: 20, fontSize: 13 },

  btn: {
    marginTop: 16, backgroundColor: '#F5C518',
    paddingHorizontal: 28, paddingVertical: 14,
    borderRadius: 28, minHeight: 48, alignItems: 'center',
  },
  btnText: { color: '#0E2A47', fontWeight: '800', fontSize: 16 },

  backBtn:  { paddingHorizontal: 16, paddingVertical: 10, minHeight: 48, alignSelf: 'flex-start' },
  backText: { color: '#F5C518', fontWeight: '700', fontSize: 15 },

  /* Story reader */
  storyTitle: { color: '#fff', fontSize: 22, fontWeight: '800', textAlign: 'center' },
  pageBadge:  { color: 'rgba(255,255,255,0.6)', fontSize: 12, marginTop: 4, marginBottom: 14 },
  pageCard: {
    backgroundColor: '#1B2B3A',
    borderRadius: 18, padding: 22,
    borderWidth: 2,
    marginBottom: 16, minHeight: 120,
    justifyContent: 'center',
  },
  pageText:   { color: '#fff', fontSize: 22, fontWeight: '600', lineHeight: 30, textAlign: 'center' },
  pageTarget: { fontWeight: '900', fontSize: 26 },
});
