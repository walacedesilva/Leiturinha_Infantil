/**
 * VilaScreen.js — Vila das Vogais (Phase 1)
 * -----------------------------------------------------------------------------
 * Fase real (substitui o stub). Duas etapas inline:
 *
 *  1) APRENDER — 5 cards de vogal. Tocar reproduz o áudio + animação de scale.
 *     Cada toque registra a estação como "ouvida" no progressStore.
 *
 *  2) DESAFIO — Liberado quando todas as 5 vogais foram ouvidas.
 *     3 rodadas: toca uma vogal aleatória e a criança toca o card correspondente.
 *     Erro = vibração leve + dica visual (sem som negativo, sem "X" vermelho).
 *     3 acertos consecutivos → completeWorld('vila') e volta ao mapa.
 *
 * Acessibilidade:
 *  - Áreas de toque ≥ 88×88 px
 *  - accessibilityLabel + accessibilityHint em todos os botões
 *  - Sem confetes ou animações > 300 ms para respeitar reduce-motion (futuro)
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  ScrollView,
  Animated,
  Easing,
  Vibration,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

import { PHASE1_VOWELS } from '../../data/phase1Vowels';
import audio from '../../services/audioService';
import { useProgressStore } from '../../store/progressStore';

const WORLD_ID = 'vila';
const CHALLENGE_ROUNDS = 3;

// ─── Card animado de vogal ────────────────────────────────────────────────
function VowelCard({ vowel, heard, onPress, dimmed, highlight }) {
  const scale = useRef(new Animated.Value(1)).current;

  const animateTap = useCallback(() => {
    Animated.sequence([
      Animated.timing(scale, { toValue: 1.12, duration: 120, useNativeDriver: true, easing: Easing.out(Easing.quad) }),
      Animated.timing(scale, { toValue: 1.0,  duration: 160, useNativeDriver: true }),
    ]).start();
  }, [scale]);

  return (
    <Animated.View style={{ transform: [{ scale }] }}>
      <Pressable
        onPress={() => { animateTap(); onPress(); }}
        accessibilityRole="button"
        accessibilityLabel={`Vogal ${vowel.letter}`}
        accessibilityHint={`Tocar para ouvir o som da letra ${vowel.letter}`}
        style={[
          styles.card,
          { backgroundColor: vowel.color, opacity: dimmed ? 0.45 : 1 },
          highlight && styles.cardHighlight,
        ]}
      >
        <Text style={styles.cardLetter}>{vowel.letter}</Text>
        {heard && <Text style={styles.cardCheck}>✓</Text>}
      </Pressable>
      <Text style={styles.cardHint}>{vowel.hint}</Text>
    </Animated.View>
  );
}

// ─── Tela ────────────────────────────────────────────────────────────────
export default function VilaScreen() {
  const navigation = useNavigation();

  const stationsHeard = useProgressStore((s) => s.progress.stationsHeard?.vila || []);
  const markStationHeard = useProgressStore((s) => s.markStationHeard);
  const completeWorld = useProgressStore((s) => s.completeWorld);

  const allHeard = useMemo(
    () => PHASE1_VOWELS.every((v) => stationsHeard.includes(v.id)),
    [stationsHeard],
  );

  // Estado do desafio
  const [phase, setPhase] = useState('learn');   // 'learn' | 'challenge' | 'done'
  const [round, setRound] = useState(0);         // 0..CHALLENGE_ROUNDS
  const [target, setTarget] = useState(null);    // vogal alvo da rodada
  const [errorOn, setErrorOn] = useState(null);  // id da vogal errada (para flash)
  const [feedback, setFeedback] = useState(null); // mensagem do mascote

  // Ouve uma vogal e marca como heard.
  const playVowel = useCallback(async (vowel) => {
    setFeedback(null);
    await audio.play(vowel.audio, { rate: 0.9 });
    markStationHeard(WORLD_ID, vowel.id);
  }, [markStationHeard]);

  // Sorteia uma vogal alvo distinta da anterior.
  const pickTarget = useCallback((exclude) => {
    const pool = PHASE1_VOWELS.filter((v) => v.id !== exclude?.id);
    return pool[Math.floor(Math.random() * pool.length)];
  }, []);

  const startChallenge = useCallback(async () => {
    setPhase('challenge');
    setRound(0);
    const first = pickTarget(null);
    setTarget(first);
    setFeedback('Ouça com atenção e toque na letra certa!');
    // Pequeno delay para a UI trocar antes do áudio.
    setTimeout(() => audio.play(first.audio, { rate: 0.9 }), 350);
  }, [pickTarget]);

  const replayTarget = useCallback(() => {
    if (target) audio.play(target.audio, { rate: 0.9 });
  }, [target]);

  const handleChallengePress = useCallback(async (vowel) => {
    if (!target) return;
    const correct = vowel.id === target.id;

    if (!correct) {
      Vibration.vibrate(35);
      setErrorOn(vowel.id);
      setFeedback(`Quase! Ouça de novo: o som é "${target.letter}"`);
      // Reapresenta o áudio sem penalidade (suíte 3.4 / 3.5).
      setTimeout(() => {
        setErrorOn(null);
        audio.play(target.audio, { rate: 0.85 });
      }, 600);
      return;
    }

    // Acerto: reproduz a vogal e avança.
    await audio.play(vowel.audio, { rate: 0.9 });
    const nextRound = round + 1;

    if (nextRound >= CHALLENGE_ROUNDS) {
      setPhase('done');
      setFeedback('Você dominou as vogais da Vila! 🌟');
      completeWorld(WORLD_ID);
      // Volta ao mapa após uma respiração visual.
      setTimeout(() => navigation.navigate('WorldMap'), 1400);
      return;
    }

    setRound(nextRound);
    const nxt = pickTarget(target);
    setTarget(nxt);
    setFeedback('Muito bem! Próxima vogal…');
    setTimeout(() => audio.play(nxt.audio, { rate: 0.9 }), 500);
  }, [target, round, pickTarget, completeWorld, navigation]);

  // Cleanup: para qualquer áudio em curso ao sair.
  useEffect(() => () => { audio.stopAll(); }, []);

  // ─── Render ──────────────────────────────────────────────────────────
  return (
    <SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Vila das Vogais</Text>
        <Text style={styles.subtitle}>
          {phase === 'learn'
            ? 'Toque em cada letra para ouvir o som dela.'
            : phase === 'challenge'
              ? `Rodada ${round + 1} de ${CHALLENGE_ROUNDS}`
              : 'Fase concluída!'}
        </Text>

        <View style={styles.grid}>
          {PHASE1_VOWELS.map((v) => (
            <VowelCard
              key={v.id}
              vowel={v}
              heard={stationsHeard.includes(v.id)}
              onPress={() => {
                if (phase === 'challenge') handleChallengePress(v);
                else playVowel(v);
              }}
              dimmed={phase === 'challenge' && errorOn && errorOn !== v.id}
              highlight={errorOn === v.id}
            />
          ))}
        </View>

        {feedback && (
          <View style={styles.mascot}>
            <Text style={styles.mascotEmoji}>🦊</Text>
            <Text style={styles.mascotText}>{feedback}</Text>
          </View>
        )}

        {phase === 'learn' && (
          <Pressable
            style={[styles.btn, !allHeard && styles.btnDisabled]}
            onPress={startChallenge}
            disabled={!allHeard}
            accessibilityRole="button"
            accessibilityState={{ disabled: !allHeard }}
            accessibilityLabel="Começar o desafio das vogais"
          >
            <Text style={styles.btnText}>
              {allHeard
                ? 'Começar Desafio'
                : `Ouça todas (${stationsHeard.length}/${PHASE1_VOWELS.length})`}
            </Text>
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
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe:   { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 20, alignItems: 'center' },
  title:    { color: '#fff', fontSize: 24, fontWeight: '800', textAlign: 'center' },
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
  cardLetter: { color: '#fff', fontSize: 48, fontWeight: '900' },
  cardCheck:  { position: 'absolute', top: 4, right: 8, color: '#fff', fontSize: 16, fontWeight: '800' },
  cardHint:   { color: 'rgba(255,255,255,0.7)', fontSize: 10, textAlign: 'center', marginTop: 4, maxWidth: 96 },

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
});
