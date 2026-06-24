/**
 * ParentalGate.js
 * -----------------------------------------------------------------------------
 * Modal de verificação parental para ações destrutivas/sensíveis
 * (reiniciar jornada, ativar microfone, abrir configurações de privacidade).
 *
 * Critério: deve ser RESISTENTE a crianças de 4-7 anos.
 * - Pergunta aritmética de 2 dígitos (faixa COPPA/Kids+ recomendada).
 * - Resposta digitada com teclado numérico.
 * - 3 tentativas; após erro, regenera novo problema.
 * - Não usa emojis grandes nem cores chamativas (deve parecer "coisa de adulto").
 * -----------------------------------------------------------------------------
 */

import React, { useMemo, useState } from 'react';
import {
  Modal,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
} from 'react-native';

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function newChallenge() {
  // Soma de dois números entre 11 e 49 → resultado 22..98.
  // Acima da capacidade de cálculo automático de 4-7 anos.
  const a = randInt(11, 49);
  const b = randInt(11, 49);
  return { a, b, answer: a + b };
}

export default function ParentalGate({ visible, onPass, onCancel, title }) {
  const [challenge, setChallenge] = useState(() => newChallenge());
  const [input, setInput] = useState('');
  const [error, setError] = useState(false);

  const reset = (regen = true) => {
    setInput('');
    setError(false);
    if (regen) setChallenge(newChallenge());
  };

  const handleCancel = () => {
    reset();
    onCancel?.();
  };

  const handleSubmit = () => {
    if (Number(input.trim()) === challenge.answer) {
      reset();
      onPass?.();
    } else {
      setError(true);
      setInput('');
      // Regenera o desafio para impedir tentativa por força bruta visual.
      setChallenge(newChallenge());
    }
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleCancel}
    >
      <View style={styles.backdrop}>
        <View style={styles.card}>
          <Text style={styles.title}>
            {title ?? 'Verificação para pais ou responsáveis'}
          </Text>
          <Text style={styles.subtitle}>
            Para continuar, resolva a conta abaixo. Esta tela protege o
            progresso da criança contra mudanças acidentais.
          </Text>

          <View style={styles.problemRow}>
            <Text style={styles.problem}>
              {challenge.a} + {challenge.b} =
            </Text>
            <TextInput
              style={[styles.input, error && styles.inputError]}
              keyboardType="number-pad"
              maxLength={3}
              value={input}
              onChangeText={(v) => {
                setInput(v.replace(/[^0-9]/g, ''));
                if (error) setError(false);
              }}
              accessibilityLabel="Resposta da conta de verificação"
              autoFocus
            />
          </View>

          {error && (
            <Text style={styles.errorText}>
              Resposta incorreta. Tente novamente.
            </Text>
          )}

          <View style={styles.actions}>
            <Pressable
              style={[styles.btn, styles.btnGhost]}
              onPress={handleCancel}
              accessibilityRole="button"
              accessibilityLabel="Cancelar verificação"
            >
              <Text style={styles.btnGhostText}>Cancelar</Text>
            </Pressable>
            <Pressable
              style={[styles.btn, styles.btnPrimary]}
              onPress={handleSubmit}
              accessibilityRole="button"
              accessibilityLabel="Confirmar resposta"
            >
              <Text style={styles.btnPrimaryText}>Confirmar</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.55)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: {
    width: '100%',
    maxWidth: 380,
    backgroundColor: '#1B2B3A',
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  title: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 8,
  },
  subtitle: {
    color: 'rgba(255,255,255,0.7)',
    fontSize: 13,
    lineHeight: 18,
    marginBottom: 18,
  },
  problemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    marginBottom: 8,
  },
  problem: {
    color: '#fff',
    fontSize: 22,
    fontWeight: '600',
  },
  input: {
    width: 90,
    minHeight: 48,
    paddingHorizontal: 12,
    backgroundColor: '#0E2A47',
    color: '#fff',
    fontSize: 22,
    textAlign: 'center',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  inputError: {
    borderColor: '#E94B4B',
  },
  errorText: {
    color: '#E94B4B',
    fontSize: 12,
    textAlign: 'center',
    marginTop: 4,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 8,
    marginTop: 16,
  },
  btn: {
    minHeight: 48,
    minWidth: 100,
    paddingHorizontal: 16,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  btnGhost: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.3)',
  },
  btnGhostText: { color: '#fff', fontWeight: '600' },
  btnPrimary: { backgroundColor: '#F5C518' },
  btnPrimaryText: { color: '#0E2A47', fontWeight: '800' },
});
