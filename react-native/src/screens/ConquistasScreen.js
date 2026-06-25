/**
 * ConquistasScreen.js
 * -----------------------------------------------------------------------------
 * Painel de conquistas (medalhas). Lê o progresso do store e mostra:
 *   - Medalha por mundo concluído (4 mundos)
 *   - Sub-medalhas por sub-desafio (famílias do Bairro, clusters da Cidade,
 *     histórias do Reino)
 *
 * Não muta estado — é uma visão read-only.
 * -----------------------------------------------------------------------------
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useProgressStore } from '../store/progressStore';
import { FAMILY_IDS } from '../data/phase2Syllables';
import { CLUSTER_IDS } from '../data/phase3Clusters';
import { STORY_IDS, STORIES } from '../data/phase4Stories';
import { useTextStyle } from '../hooks/useA11y';

const WORLDS = [
  { id: 'vila',   label: 'Vila das Vogais',     emoji: '🦊' },
  { id: 'bairro', label: 'Bairro das Famílias', emoji: '🏘️' },
  { id: 'cidade', label: 'Cidade dos Encontros', emoji: '🏙️' },
  { id: 'reino',  label: 'Reino das Histórias', emoji: '📖' },
];

export default function ConquistasScreen() {
  const progress = useProgressStore((s) => s.progress);
  const titleStyle = useTextStyle(24);
  const subStyle   = useTextStyle(13);

  const totals = useMemo(() => {
    const worldsDone = WORLDS.filter((w) => progress[`${w.id}Completed`]).length;
    const bairroDone = (progress.phaseChallenges?.bairro || []).length;
    const cidadeDone = (progress.phaseChallenges?.cidade || []).length;
    const reinoDone  = (progress.phaseChallenges?.reino  || []).length;
    return { worldsDone, bairroDone, cidadeDone, reinoDone };
  }, [progress]);

  const totalMedals = totals.worldsDone + totals.bairroDone + totals.cidadeDone + totals.reinoDone;

  return (
    <SafeAreaView style={styles.root}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={[styles.title, titleStyle]}>Conquistas</Text>
        <Text style={[styles.sub, subStyle]}>
          {totalMedals === 0
            ? 'Suas primeiras medalhas vão aparecer aqui.'
            : `${totalMedals} medalha${totalMedals === 1 ? '' : 's'} conquistada${totalMedals === 1 ? '' : 's'}!`}
        </Text>

        <Section title="Mundos">
          <Row>
            {WORLDS.map((w) => {
              const done = progress[`${w.id}Completed`];
              return (
                <Medal
                  key={w.id}
                  icon={w.emoji}
                  label={w.label}
                  done={done}
                />
              );
            })}
          </Row>
        </Section>

        <Section title={`Famílias do Bairro (${totals.bairroDone}/${FAMILY_IDS.length})`}>
          <Row>
            {FAMILY_IDS.map((id) => (
              <Medal
                key={id}
                icon="🏠"
                label={`Família ${id}`}
                done={(progress.phaseChallenges?.bairro || []).includes(id)}
              />
            ))}
          </Row>
        </Section>

        <Section title={`Praças da Cidade (${totals.cidadeDone}/${CLUSTER_IDS.length})`}>
          <Row>
            {CLUSTER_IDS.map((id) => (
              <Medal
                key={id}
                icon="🏛️"
                label={id}
                done={(progress.phaseChallenges?.cidade || []).includes(id)}
              />
            ))}
          </Row>
        </Section>

        <Section title={`Histórias do Reino (${totals.reinoDone}/${STORY_IDS.length})`}>
          <Row>
            {STORIES.map((s) => (
              <Medal
                key={s.id}
                icon={s.emoji}
                label={s.title}
                done={(progress.phaseChallenges?.reino || []).includes(s.id)}
              />
            ))}
          </Row>
        </Section>
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

function Row({ children }) {
  return <View style={styles.row}>{children}</View>;
}

function Medal({ icon, label, done }) {
  return (
    <View
      style={[styles.medal, !done && styles.medalLocked]}
      accessibilityLabel={`${label}: ${done ? 'conquistada' : 'pendente'}`}
    >
      <Text style={[styles.medalIcon, !done && styles.medalIconLocked]}>{done ? icon : '🔒'}</Text>
      <Text style={[styles.medalLabel, !done && styles.medalLabelLocked]} numberOfLines={2}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: '#0E2A47' },
  scroll: { padding: 20, paddingBottom: 40 },

  title: { color: '#fff', fontSize: 24, fontWeight: '800' },
  sub:   { color: 'rgba(255,255,255,0.7)', marginTop: 6, marginBottom: 16, fontSize: 13 },

  section: { marginBottom: 18 },
  sectionTitle: { color: '#F5C518', fontWeight: '800', fontSize: 14, marginBottom: 10 },

  row: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },

  medal: {
    width: 96, minHeight: 96, padding: 8,
    borderRadius: 14, backgroundColor: '#1B2B3A',
    alignItems: 'center', justifyContent: 'center',
    borderWidth: 2, borderColor: '#F5C518',
  },
  medalLocked:      { borderColor: 'rgba(255,255,255,0.15)', opacity: 0.7 },
  medalIcon:        { fontSize: 32 },
  medalIconLocked:  { opacity: 0.6 },
  medalLabel:       { color: '#fff', fontSize: 11, marginTop: 4, textAlign: 'center', fontWeight: '700' },
  medalLabelLocked: { color: 'rgba(255,255,255,0.55)', fontWeight: '500' },
});
