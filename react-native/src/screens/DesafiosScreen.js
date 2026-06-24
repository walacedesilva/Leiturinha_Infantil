/**
 * DesafiosScreen.js
 * -----------------------------------------------------------------------------
 * Aba de Desafios — primeira atividade real: "Leia em voz alta".
 *
 * Sorteia 1 sílaba de uma família CV já desbloqueada (a partir do progresso
 * do Bairro) e pede que a criança leia. Usa ReadAloudButton (ASR + match
 * fonético tolerante). Sucessos acumulam um contador local da sessão
 * (não persistido — desafios são extras, não fazem parte da progressão linear).
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useMemo, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import ReadAloudButton from '../components/ReadAloudButton';
import { FAMILIES } from '../data/phase2Syllables';
import { useProgressStore } from '../store/progressStore';
import { useTextStyle } from '../hooks/useA11y';

function pickRandomFromPool(pool, exclude) {
  if (!pool.length) return null;
  const candidates = pool.filter((s) => s.id !== exclude?.id);
  if (!candidates.length) return pool[Math.floor(Math.random() * pool.length)];
  return candidates[Math.floor(Math.random() * candidates.length)];
}

export default function DesafiosScreen() {
  const passedFamilies = useProgressStore((s) => s.progress.phaseChallenges?.bairro || []);
  const titleStyle = useTextStyle(24);
  const subStyle   = useTextStyle(13);

  // Pool: famílias do Bairro já vencidas, ou Família do B como porta de entrada.
  const pool = useMemo(() => {
    const families = passedFamilies.length > 0
      ? FAMILIES.filter((f) => passedFamilies.includes(f.id))
      : FAMILIES.slice(0, 1);
    return families.flatMap((f) => f.syllables);
  }, [passedFamilies]);

  const [current, setCurrent] = useState(() => pickRandomFromPool(pool));
  const [hits, setHits] = useState(0);

  const next = useCallback(() => {
    setCurrent((prev) => pickRandomFromPool(pool, prev));
  }, [pool]);

  const handleSuccess = useCallback(({ match }) => {
    if (match?.ok) setHits((h) => h + 1);
    setTimeout(next, 250);
  }, [next]);

  if (!current) {
    return (
      <SafeAreaView style={styles.root}>
        <Text style={styles.title}>Desafios</Text>
        <Text style={styles.notice}>Nada disponível. Volte ao Bairro primeiro.</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.root}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={[styles.title, titleStyle]}>Desafios</Text>
        <Text style={[styles.sub, subStyle]}>Leia em voz alta a sílaba que aparecer.</Text>

        <View style={styles.badge}>
          <Text style={styles.badgeText}>Acertos nesta sessão: {hits}</Text>
        </View>

        <ReadAloudButton
          key={current.id}
          target={current.letter}
          hint="Leia esta sílaba:"
          onSuccess={handleSuccess}
        />

        <Pressable style={styles.btnGhost} onPress={next} accessibilityRole="button">
          <Text style={styles.btnGhostText}>Trocar sílaba</Text>
        </Pressable>

        {passedFamilies.length === 0 && (
          <Text style={styles.notice}>
            Dica: conclua famílias no Bairro para liberar mais sílabas aqui.
          </Text>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 20, alignItems: 'center', paddingBottom: 40 },

  title: { color: '#fff', fontSize: 24, fontWeight: '800' },
  sub:   { color: 'rgba(255,255,255,0.7)', marginTop: 6, marginBottom: 12, textAlign: 'center' },

  badge: {
    backgroundColor: '#1B2B3A', borderRadius: 14,
    paddingHorizontal: 14, paddingVertical: 8,
    marginBottom: 8,
  },
  badgeText: { color: '#F5C518', fontWeight: '700', fontSize: 13 },

  btnGhost: {
    marginTop: 14, paddingHorizontal: 18, paddingVertical: 10,
    borderRadius: 24, minHeight: 48,
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.3)',
  },
  btnGhostText: { color: 'rgba(255,255,255,0.85)', fontSize: 14 },

  notice: {
    color: 'rgba(255,255,255,0.6)', fontSize: 12,
    marginTop: 20, textAlign: 'center', maxWidth: 320, lineHeight: 16,
  },
});
