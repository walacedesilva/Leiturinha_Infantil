/**
 * Stub genérico de tela de mundo (fase).
 * Cada arquivo de mundo (Vila/Bairro/Cidade/Reino) reusa este componente
 * passando o `worldId`. No final da fase, chama `completeWorld(worldId)` e
 * volta para o Mapa.
 */

import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { useProgressStore } from '../../store/progressStore';

const LABELS = {
  vila:   'Vila das Vogais',
  bairro: 'Bairro das Famílias',
  cidade: 'Cidade das Sílabas',
  reino:  'Reino das Histórias',
};

export default function WorldScreenBase({ worldId }) {
  const navigation = useNavigation();
  const completeWorld = useProgressStore((s) => s.completeWorld);

  const finish = () => {
    completeWorld(worldId);
    // Volta ao Mapa Mundial mantendo a Tab Bar visível.
    navigation.navigate('WorldMap');
  };

  return (
    <SafeAreaView style={styles.root}>
      <Text style={styles.title}>{LABELS[worldId]}</Text>
      <Text style={styles.subtitle}>(Tela de fase — implemente o jogo aqui)</Text>

      <Pressable style={styles.btn} onPress={finish}>
        <Text style={styles.btnText}>Concluir fase</Text>
      </Pressable>

      <Pressable
        style={[styles.btn, styles.btnGhost]}
        onPress={() => navigation.navigate('WorldMap')}
      >
        <Text style={[styles.btnText, { color: '#F5C518' }]}>Voltar ao mapa</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1, backgroundColor: '#0E2A47',
    alignItems: 'center', justifyContent: 'center', padding: 24,
  },
  title:    { color: '#fff', fontSize: 26, fontWeight: '800' },
  subtitle: { color: 'rgba(255,255,255,0.7)', marginTop: 8, textAlign: 'center' },
  btn: {
    marginTop: 28, backgroundColor: '#F5C518',
    paddingHorizontal: 24, paddingVertical: 12, borderRadius: 24,
  },
  btnGhost: { backgroundColor: 'transparent', borderWidth: 2, borderColor: '#F5C518' },
  btnText:  { color: '#0E2A47', fontWeight: '800' },
});
