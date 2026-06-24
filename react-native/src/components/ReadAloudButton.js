/**
 * ReadAloudButton.js
 * -----------------------------------------------------------------------------
 * Botão de "leitura em voz alta" para a criança.
 *
 * Estados visuais: idle → recording → matching → success | retry
 *
 * Comportamento:
 *   - Bloqueia se !consent.microphoneAllowed (mostra CTA para Perfil).
 *   - Mascote dá feedback amigável (sem som negativo) em retry.
 *   - Em ambiente de DEV/mock, usa mockAnswer = target para fechar o loop.
 *
 * Props:
 *   - target   : string  (ex. "BA", "MAÇÃ")
 *   - hint     : string  (texto pequeno acima — opcional)
 *   - onSuccess: ({result, match}) => void
 *   - onCancel : () => void  (opcional)
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { View, Text, Pressable, StyleSheet, Animated, Easing, Vibration } from 'react-native';
import { useNavigation } from '@react-navigation/native';

import { useConsentStore } from '../store/consentStore';
import { useSettingsStore } from '../store/settingsStore';
import speech from '../services/speechService';
import { matchPhonetic } from '../services/phoneticMatch';
import { useReduceMotion } from '../hooks/useA11y';

const MAX_ATTEMPTS = 3;

export default function ReadAloudButton({ target, hint, onSuccess, onCancel }) {
  const navigation = useNavigation();
  const micAllowed = useConsentStore((s) => s.consent.microphoneAllowed);
  const inputMethod = useSettingsStore((s) => s.settings.inputMethod);
  const reduceMotion = useReduceMotion();
  const touchOnly = inputMethod === 'touch_only';

  const [state, setState] = useState('idle'); // idle | recording | matching | success | retry
  const [attempts, setAttempts] = useState(0);
  const [feedback, setFeedback] = useState(null);

  const pulse = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    if (state !== 'recording') {
      pulse.setValue(1);
      return;
    }
    if (reduceMotion) return; // a11y: não anima quando "Reduzir movimento" está ativo
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1.18, duration: 500, useNativeDriver: true, easing: Easing.inOut(Easing.quad) }),
        Animated.timing(pulse, { toValue: 1.0,  duration: 500, useNativeDriver: true, easing: Easing.inOut(Easing.quad) }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [state, pulse, reduceMotion]);

  useEffect(() => () => { speech.cancel(); }, []);

  const startListen = useCallback(async () => {
    if (!micAllowed) return;
    setState('recording');
    setFeedback('Pode falar! 🎤');

    try {
      const result = await speech.listen({
        lang: 'pt-BR',
        mockAnswer: target,    // garante demo funcional sem hardware
        timeoutMs: 5000,
      });
      setState('matching');
      const match = matchPhonetic(result.transcript, target);
      if (match.ok) {
        setState('success');
        setFeedback(result.simulated
          ? `Modo simulado ativo (sem mic real). "${target}" ✓`
          : `Muito bem! Você disse "${result.transcript}".`);
        setTimeout(() => onSuccess?.({ result, match }), 900);
        return;
      }
      const nextAttempts = attempts + 1;
      setAttempts(nextAttempts);
      Vibration.vibrate(30);
      if (nextAttempts >= MAX_ATTEMPTS) {
        // Sem penalidade: oferece pular sem marcar erro grave.
        setState('retry');
        setFeedback(`Tudo bem! Vamos seguir e voltar depois. Alvo: "${target}".`);
      } else {
        setState('retry');
        setFeedback(`Quase! Tente de novo dizendo "${target}".`);
      }
    } catch (e) {
      setState('retry');
      const why = e?.message === 'timeout'
        ? 'Não ouvi nada. Tente de novo!'
        : e?.message === 'cancelled'
          ? 'Captura cancelada.'
          : 'Não consegui ouvir. Tente de novo!';
      setFeedback(why);
    }
  }, [micAllowed, target, attempts, onSuccess]);

  const skip = useCallback(() => {
    speech.cancel();
    onSuccess?.({ result: null, match: { ok: false, score: 0, reason: 'skipped' } });
  }, [onSuccess]);

  // ── Bloqueio por consentimento ──────────────────────────────────────
  if (!micAllowed && !touchOnly) {
    return (
      <View style={styles.consentBlock}>
        <Text style={styles.consentTitle}>🎤 Microfone desligado</Text>
        <Text style={styles.consentText}>
          Para esta atividade, um adulto precisa ativar o microfone em Perfil.
        </Text>
        <Pressable
          style={styles.btn}
          onPress={() => navigation.navigate('Perfil')}
          accessibilityRole="button"
          accessibilityLabel="Ir para Perfil para ativar o microfone"
        >
          <Text style={styles.btnText}>Ir para Perfil</Text>
        </Pressable>
        {onCancel && (
          <Pressable style={styles.btnGhost} onPress={onCancel}>
            <Text style={styles.btnGhostText}>Voltar</Text>
          </Pressable>
        )}
      </View>
    );
  }

  // ── Modo somente toque (inputMethod = 'touch_only') ─────────────────
  // Quando o responsável desativou o microfone nas preferências,
  // oferecemos uma confirmação simples por toque em vez da gravação.
  if (touchOnly) {
    return (
      <View style={styles.wrap}>
        {hint && <Text style={styles.hint}>{hint}</Text>}
        <Text style={styles.target}>{target}</Text>
        <Pressable
          style={[styles.mic, state === 'success' && styles.micSuccess]}
          onPress={() => {
            if (state === 'success') return;
            setState('success');
            setFeedback(`"${target}" confirmado! ✓`);
            setTimeout(() => onSuccess?.({
              result: { transcript: target, simulated: true },
              match: { ok: true, score: 1, reason: 'touch_only' },
            }), 900);
          }}
          disabled={state === 'success'}
          accessibilityRole="button"
          accessibilityLabel={`Confirmar que leu: ${target}`}
          accessibilityHint="Modo somente toque — toque para confirmar a leitura"
        >
          <Text style={styles.micIcon}>
            {state === 'success' ? '✓' : '👆'}
          </Text>
        </Pressable>
        <Text style={styles.feedback}>
          {feedback || `Leia em voz alta e toque para confirmar.`}
        </Text>
        {onCancel && (
          <Pressable style={styles.btnGhost} onPress={onCancel}>
            <Text style={styles.btnGhostText}>Voltar</Text>
          </Pressable>
        )}
        <Text style={styles.engineBadge}>Modo: somente toque</Text>
      </View>
    );
  }

  // ── UI normal ───────────────────────────────────────────────────────
  return (
    <View style={styles.wrap}>
      {hint && <Text style={styles.hint}>{hint}</Text>}
      <Text style={styles.target}>{target}</Text>

      <Animated.View style={{ transform: [{ scale: pulse }] }}>
        <Pressable
          style={[
            styles.mic,
            state === 'recording' && styles.micActive,
            state === 'success'   && styles.micSuccess,
          ]}
          onPress={state === 'recording' ? () => speech.cancel() : startListen}
          disabled={state === 'matching' || state === 'success'}
          accessibilityRole="button"
          accessibilityLabel={state === 'recording' ? 'Cancelar gravação' : 'Iniciar gravação de leitura'}
        >
          <Text style={styles.micIcon}>
            {state === 'success' ? '✓' : state === 'recording' ? '■' : '🎤'}
          </Text>
        </Pressable>
      </Animated.View>

      <Text style={styles.feedback}>{feedback || 'Toque no microfone e diga em voz alta.'}</Text>

      {state === 'retry' && attempts < MAX_ATTEMPTS && (
        <Pressable style={styles.btn} onPress={startListen}>
          <Text style={styles.btnText}>Tentar de novo</Text>
        </Pressable>
      )}

      {(state === 'retry' && attempts >= MAX_ATTEMPTS) && (
        <Pressable style={styles.btnGhost} onPress={skip}>
          <Text style={styles.btnGhostText}>Pular por agora</Text>
        </Pressable>
      )}

      <Text style={styles.engineBadge}>
        Motor: {speech.getEngine()} {speech.isAvailable() ? '' : '(simulado)'}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: 'center', padding: 20 },

  hint:   { color: 'rgba(255,255,255,0.7)', fontSize: 13, marginBottom: 4 },
  target: { color: '#F5C518', fontSize: 56, fontWeight: '900', marginVertical: 12 },

  mic: {
    width: 112, height: 112, borderRadius: 56,
    backgroundColor: '#1B2B3A',
    alignItems: 'center', justifyContent: 'center',
    borderWidth: 3, borderColor: '#F5C518',
    minWidth: 48, minHeight: 48,
  },
  micActive:  { backgroundColor: '#E94B4B', borderColor: '#fff' },
  micSuccess: { backgroundColor: '#9AE19A', borderColor: '#fff' },
  micIcon:    { fontSize: 48, color: '#fff' },

  feedback: {
    color: '#fff', marginTop: 18, fontSize: 14,
    textAlign: 'center', maxWidth: 320, lineHeight: 19,
  },

  btn: {
    marginTop: 16, backgroundColor: '#F5C518',
    paddingHorizontal: 24, paddingVertical: 12,
    borderRadius: 24, minHeight: 48,
  },
  btnText: { color: '#0E2A47', fontWeight: '800', fontSize: 15, textAlign: 'center' },

  btnGhost: {
    marginTop: 10, paddingHorizontal: 18, paddingVertical: 10,
    borderRadius: 24, minHeight: 48,
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.3)',
  },
  btnGhostText: { color: 'rgba(255,255,255,0.85)', fontSize: 14 },

  engineBadge: { color: 'rgba(255,255,255,0.4)', fontSize: 10, marginTop: 16 },

  /* Bloqueio por consentimento */
  consentBlock: {
    margin: 20, padding: 20, borderRadius: 18,
    backgroundColor: '#1B2B3A', alignItems: 'center',
  },
  consentTitle: { color: '#fff', fontWeight: '800', fontSize: 16 },
  consentText:  { color: 'rgba(255,255,255,0.7)', textAlign: 'center', marginTop: 8, marginBottom: 14, fontSize: 13, lineHeight: 18 },
});
