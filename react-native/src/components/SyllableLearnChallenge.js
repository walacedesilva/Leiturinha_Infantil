/**
 * SyllableLearnChallenge.js
 * -----------------------------------------------------------------------------
 * Componente reutilizável que implementa o fluxo pedagógico padrão de uma
 * "estação fonética":
 *
 *   1) APRENDER: cards de sílaba/vogal. Tocar reproduz o áudio em 0.9× e
 *      marca a estação como ouvida no progressStore.
 *   2) DESAFIO: 3 rodadas de reconhecimento auditivo. Erro = vibração leve +
 *      mascote dá feedback contextual sem som negativo + replay automático
 *      em 0.85×. 3 acertos consecutivos → onComplete().
 *
 * Props:
 *   - worldId        : string ('vila' | 'bairro' | ...)
 *   - groupId        : string (ex.: 'B' para a Família do B). Opcional.
 *   - title, subtitle: strings
 *   - items          : Array<{ id, letter, ipa, color?, hint?, audio }>
 *   - challengeRounds: number (default 3)
 *   - onComplete     : () => void   chamado APÓS o último acerto.
 *
 * Reuso: VilaScreen (vogais), BairroScreen (sílabas CV por família).
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  View, Text, Pressable, StyleSheet, ScrollView,
  Animated, Easing, Vibration,
} from 'react-native';

import audio from '../services/audioService';
import { getWordsForFamily, getFamilyColor } from '../data/wordBank';
import { useProgressStore } from '../store/progressStore';
import { useReduceMotion } from '../hooks/useA11y';

const DEFAULT_COLORS = ['#E94B4B', '#F5C518', '#9AE19A', '#4BC0E9', '#C977E5'];

function Card({ item, color, heard, onPress, dimmed, highlight }) {
  const reduceMotion = useReduceMotion();
  const scale = useRef(new Animated.Value(1)).current;
  const animateTap = useCallback(() => {
    if (reduceMotion) return; // a11y: respeita "Reduzir movimento".
    Animated.sequence([
      Animated.timing(scale, { toValue: 1.12, duration: 120, useNativeDriver: true, easing: Easing.out(Easing.quad) }),
      Animated.timing(scale, { toValue: 1.0,  duration: 160, useNativeDriver: true }),
    ]).start();
  }, [scale, reduceMotion]);

  return (
    <Animated.View style={{ transform: [{ scale }] }}>
      <Pressable
        onPress={() => { animateTap(); onPress(); }}
        accessibilityRole="button"
        accessibilityLabel={item.letter}
        accessibilityHint={`Tocar para ouvir ${item.letter}`}
        style={[
          styles.card,
          { backgroundColor: color, opacity: dimmed ? 0.45 : 1 },
          highlight && styles.cardHighlight,
        ]}
      >
        <Text style={styles.cardLetter}>{item.letter}</Text>
        {heard && <Text style={styles.cardCheck}>✓</Text>}
      </Pressable>
      {item.hint && <Text style={styles.cardHint}>{item.hint}</Text>}
    </Animated.View>
  );
}

export default function SyllableLearnChallenge({
  worldId,
  groupId,
  title,
  subtitle,
  items,
  challengeRounds = 3,
  onComplete,
}) {
  const stationsHeard = useProgressStore((s) => s.progress.stationsHeard?.[worldId] || []);
  const markStationHeard = useProgressStore((s) => s.markStationHeard);

  const expectedIds = useMemo(() => items.map((i) => i.id), [items]);
  const allHeard = useMemo(
    () => expectedIds.every((id) => stationsHeard.includes(id)),
    [expectedIds, stationsHeard],
  );

  const [phase, setPhase] = useState('learn'); // 'learn' | 'words' | 'challenge' | 'done'
  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(null);
  const [errorOn, setErrorOn] = useState(null);
  const [feedback, setFeedback] = useState(null);

  const familyWords = useMemo(() => (groupId ? getWordsForFamily(groupId) : []), [groupId]);
  const familyColor = useMemo(
    () => (groupId ? getFamilyColor(groupId) : null) || items[0]?.color || '#F5C518',
    [groupId, items],
  );

  const goToWords = useCallback(() => setPhase('words'), []);

  const playItem = useCallback(async (item) => {
    setFeedback(null);
    await audio.play(item.audio, { rate: 0.9 });
    markStationHeard(worldId, item.id);
  }, [markStationHeard, worldId]);

  const pickTarget = useCallback((exclude) => {
    const pool = items.filter((v) => v.id !== exclude?.id);
    return pool[Math.floor(Math.random() * pool.length)];
  }, [items]);

  const startChallenge = useCallback(() => {
    setPhase('challenge');
    setRound(0);
    const first = pickTarget(null);
    setTarget(first);
    setFeedback('Ouça com atenção e toque na sílaba certa!');
    setTimeout(() => audio.play(first.audio, { rate: 0.9 }), 350);
  }, [pickTarget]);

  const replayTarget = useCallback(() => {
    if (target) audio.play(target.audio, { rate: 0.9 });
  }, [target]);

  const handleChallengePress = useCallback(async (item) => {
    if (!target) return;
    const correct = item.id === target.id;

    if (!correct) {
      Vibration.vibrate(35);
      setErrorOn(item.id);
      setFeedback(`Quase! Ouça de novo: o som é "${target.letter}"`);
      setTimeout(() => {
        setErrorOn(null);
        audio.play(target.audio, { rate: 0.85 });
      }, 600);
      return;
    }

    await audio.play(item.audio, { rate: 0.9 });
    const nextRound = round + 1;

    if (nextRound >= challengeRounds) {
      setPhase('done');
      setFeedback('Você completou esta etapa! 🌟');
      setTimeout(() => onComplete?.(), 1200);
      return;
    }

    setRound(nextRound);
    const nxt = pickTarget(target);
    setTarget(nxt);
    setFeedback('Muito bem! Próxima…');
    setTimeout(() => audio.play(nxt.audio, { rate: 0.9 }), 500);
  }, [target, round, pickTarget, onComplete, challengeRounds]);

  useEffect(() => () => { audio.stopAll(); }, []);

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.subtitle}>
        {subtitle ?? (
          phase === 'learn'
            ? 'Toque em cada sílaba para ouvir o som.'
            : phase === 'words'
              ? 'Toque em cada palavra para ouvi-la!'
              : phase === 'challenge'
                ? `Rodada ${round + 1} de ${challengeRounds}`
                : 'Etapa concluída!'
        )}
      </Text>

      {phase !== 'words' && (
        <View style={styles.grid}>
          {items.map((item, idx) => (
            <Card
              key={item.id}
              item={item}
              color={item.color || DEFAULT_COLORS[idx % DEFAULT_COLORS.length]}
              heard={stationsHeard.includes(item.id)}
              onPress={() => {
                if (phase === 'challenge') handleChallengePress(item);
                else playItem(item);
              }}
              dimmed={phase === 'challenge' && errorOn && errorOn !== item.id}
              highlight={errorOn === item.id}
            />
          ))}
        </View>
      )}

      {phase === 'words' && (
        <View style={styles.wordsGrid}>
          {familyWords.map((w) => (
            <Pressable
              key={w.word}
              onPress={() => audio.play(w.audio, { rate: 0.9 })}
              accessibilityRole="button"
              accessibilityLabel={`Palavra ${w.word}`}
              accessibilityHint="Toque para ouvir"
              style={styles.wordCard}
            >
              <Text style={styles.wordText}>{w.word}</Text>
              <View style={styles.syllablesRow}>
                {w.syllables.map((syl, si) => (
                  <View
                    key={si}
                    style={[
                      styles.sylChip,
                      { backgroundColor: syl[0] === groupId ? familyColor : '#4a5568' },
                    ]}
                  >
                    <Text style={styles.sylChipText}>{syl}</Text>
                  </View>
                ))}
              </View>
            </Pressable>
          ))}
        </View>
      )}

      {feedback && (
        <View style={styles.mascot}>
          <Text style={styles.mascotEmoji}>🦊</Text>
          <Text style={styles.mascotText}>{feedback}</Text>
        </View>
      )}

      {phase === 'learn' && (
        <Pressable
          style={[styles.btn, !allHeard && styles.btnDisabled]}
          onPress={familyWords.length > 0 ? goToWords : startChallenge}
          disabled={!allHeard}
          accessibilityRole="button"
          accessibilityState={{ disabled: !allHeard }}
        >
          <Text style={styles.btnText}>
            {allHeard
              ? (familyWords.length > 0 ? 'Ver Palavras →' : 'Começar Desafio')
              : `Ouça todas (${stationsHeard.filter((id) => expectedIds.includes(id)).length}/${items.length})`}
          </Text>
        </Pressable>
      )}

      {phase === 'words' && (
        <Pressable
          style={styles.btn}
          onPress={startChallenge}
          accessibilityRole="button"
          accessibilityLabel="Começar desafio"
        >
          <Text style={styles.btnText}>Começar Desafio 🎮</Text>
        </Pressable>
      )}

      {phase === 'challenge' && (
        <Pressable
          style={[styles.btn, styles.btnGhost]}
          onPress={replayTarget}
          accessibilityRole="button"
          accessibilityLabel="Ouvir o som novamente"
        >
          <Text style={[styles.btnText, { color: '#F5C518' }]}>🔊 Ouvir de novo</Text>
        </Pressable>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 20, alignItems: 'center' },
  title:    { color: '#fff', fontSize: 22, fontWeight: '800', textAlign: 'center' },
  subtitle: { color: 'rgba(255,255,255,0.75)', marginTop: 6, marginBottom: 16, textAlign: 'center' },

  grid: {
    flexDirection: 'row', flexWrap: 'wrap',
    justifyContent: 'center', gap: 14,
    marginVertical: 8,
  },
  card: {
    width: 96, height: 96, minWidth: 88, minHeight: 88,
    borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
    elevation: 4,
    shadowColor: '#000', shadowOpacity: 0.25, shadowRadius: 6, shadowOffset: { width: 0, height: 3 },
  },
  cardHighlight: { borderWidth: 3, borderColor: '#fff' },
  cardLetter:    { color: '#fff', fontSize: 40, fontWeight: '900' },
  cardCheck:     { position: 'absolute', top: 4, right: 8, color: '#fff', fontSize: 16, fontWeight: '800' },
  cardHint:      { color: 'rgba(255,255,255,0.7)', fontSize: 10, textAlign: 'center', marginTop: 4, maxWidth: 96 },

  mascot: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 16, padding: 12,
    marginTop: 20, maxWidth: 360, gap: 10,
  },
  mascotEmoji: { fontSize: 28 },
  mascotText:  { color: '#fff', flexShrink: 1, fontSize: 14, lineHeight: 18 },

  btn: {
    marginTop: 24, backgroundColor: '#F5C518',
    paddingHorizontal: 28, paddingVertical: 14,
    borderRadius: 28, minHeight: 48, alignItems: 'center',
  },
  btnDisabled: { backgroundColor: 'rgba(245,197,24,0.35)' },
  btnGhost:    { backgroundColor: 'transparent', borderWidth: 2, borderColor: '#F5C518' },
  btnText:     { color: '#0E2A47', fontWeight: '800', fontSize: 16 },

  wordsGrid: {
    flexDirection: 'row', flexWrap: 'wrap',
    justifyContent: 'center', gap: 12,
    marginVertical: 8, width: '100%',
  },
  wordCard: {
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderRadius: 16, padding: 14,
    alignItems: 'center', minWidth: 130,
    elevation: 3,
    shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 4, shadowOffset: { width: 0, height: 2 },
  },
  wordText: { color: '#fff', fontSize: 26, fontWeight: '900', letterSpacing: 2, marginBottom: 8 },
  syllablesRow: { flexDirection: 'row', gap: 6 },
  sylChip: {
    paddingHorizontal: 10, paddingVertical: 5,
    borderRadius: 8,
    alignItems: 'center', justifyContent: 'center',
  },
  sylChipText: { color: '#fff', fontSize: 16, fontWeight: '800' },
});
