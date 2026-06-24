/**
 * HomeMapScreen.js  (WorldMap)
 * -----------------------------------------------------------------------------
 * Tela inicial do app — o Mapa Mundial da Jornada.
 *
 * Refactor QA:
 *  - useMemo agora depende corretamente de `progress` (regra dos hooks).
 *  - Opacidade de fase bloqueada ajustada para 0.6 (spec).
 *  - Feedback de bloqueio: toast custom (substitui Alert nativo iOS).
 *  - Navegação usa nomes do HomeStack aninhado.
 * -----------------------------------------------------------------------------
 */

import React, { useCallback, useMemo, useState } from 'react';
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  Vibration,
  Animated,
  Easing,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import Svg, { Line } from 'react-native-svg';

import { useProgressStore, WORLD_ORDER } from '../store/progressStore';
import { useTextStyle } from '../hooks/useA11y';

const WORLDS = [
  { id: 'vila',   label: 'Vila das Vogais',     icon: '🏡', x: 0.18, y: 0.78, target: 'VilaScreen'   },
  { id: 'bairro', label: 'Bairro das Famílias', icon: '🏘️', x: 0.42, y: 0.55, target: 'BairroScreen' },
  { id: 'cidade', label: 'Cidade das Sílabas',  icon: '🏙️', x: 0.70, y: 0.35, target: 'CidadeScreen', tall: true },
  { id: 'reino',  label: 'Reino das Histórias', icon: '🏰', x: 0.85, y: 0.12, target: 'ReinoScreen'  },
];

const TARGET_BY_ID = {
  vila:   'VilaScreen',
  bairro: 'BairroScreen',
  cidade: 'CidadeScreen',
  reino:  'ReinoScreen',
};

// Toast custom (substitui Alert/ToastAndroid agressivos)
function useGentleToast() {
  const [msg, setMsg] = useState(null);
  const opacity = useMemo(() => new Animated.Value(0), []);

  const show = useCallback((text) => {
    setMsg(text);
    opacity.setValue(0);
    Animated.sequence([
      Animated.timing(opacity, { toValue: 1, duration: 180, useNativeDriver: true, easing: Easing.out(Easing.ease) }),
      Animated.delay(1600),
      Animated.timing(opacity, { toValue: 0, duration: 240, useNativeDriver: true }),
    ]).start(() => setMsg(null));
  }, [opacity]);

  const node = msg ? (
    <Animated.View style={[styles.toast, { opacity }]} pointerEvents="none">
      <Text style={styles.toastText}>{msg}</Text>
    </Animated.View>
  ) : null;

  return { show, node };
}

export default function HomeMapScreen() {
  const navigation = useNavigation();
  const progress = useProgressStore((s) => s.progress);
  const getWorldStatus = useProgressStore((s) => s.getWorldStatus);
  const canEnter       = useProgressStore((s) => s.canEnter);
  const getCTA         = useProgressStore((s) => s.getCallToAction);
  const worldLabelStyle = useTextStyle(10);

  const toast = useGentleToast();

  const statuses = useMemo(
    () => Object.fromEntries(WORLD_ORDER.map((id) => [id, getWorldStatus(id)])),
    [progress, getWorldStatus],
  );

  const cta = getCTA();

  const handlePress = (world) => {
    if (canEnter(world.id)) {
      navigation.navigate(world.target);
    } else {
      Vibration.vibrate(40);
      toast.show('🔒 Complete a fase anterior para abrir esta!');
    }
  };

  const handleCTA = () => {
    const target = cta.target ? TARGET_BY_ID[cta.target] : null;
    if (target && canEnter(cta.target)) navigation.navigate(target);
  };

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'left', 'right']}>
      <View style={styles.map}>
        <Svg style={StyleSheet.absoluteFill} pointerEvents="none">
          {WORLDS.slice(0, -1).map((from, i) => {
            const to = WORLDS[i + 1];
            const active = statuses[from.id] === 'completed';
            return (
              <Line
                key={`${from.id}-${to.id}`}
                x1={`${from.x * 100}%`} y1={`${from.y * 100}%`}
                x2={`${to.x   * 100}%`} y2={`${to.y   * 100}%`}
                stroke={active ? '#F5C518' : 'rgba(255,255,255,0.18)'}
                strokeWidth={active ? 6 : 4}
                strokeDasharray={active ? undefined : '8,8'}
                strokeLinecap="round"
              />
            );
          })}
        </Svg>

        {WORLDS.map((world) => {
          const status = statuses[world.id];
          const isLocked = status === 'locked';

          return (
            <Pressable
              key={world.id}
              onPress={() => handlePress(world)}
              accessibilityRole="button"
              accessibilityLabel={world.label}
              accessibilityState={{ disabled: isLocked }}
              accessibilityHint={
                isLocked
                  ? 'Bloqueado. Complete a fase anterior para desbloquear.'
                  : `Abrir ${world.label}`
              }
              style={[
                styles.worldBtn,
                {
                  left: `${world.x * 100}%`,
                  top:  `${world.y * 100}%`,
                  opacity: isLocked ? 0.6 : 1,
                },
                world.tall && styles.worldTall,
                status === 'unlocked' && styles.worldPulse,
              ]}
            >
              <Text style={[styles.worldIcon, world.tall && styles.worldIconTall]}>
                {world.icon}
              </Text>
              <Text style={[styles.worldLabel, worldLabelStyle]} numberOfLines={2}>
                {world.label}
              </Text>
              {isLocked && <Text style={styles.lockBadge}>🔒</Text>}
            </Pressable>
          );
        })}

        {cta.target && (
          <Pressable
            style={styles.cta}
            onPress={handleCTA}
            accessibilityRole="button"
            accessibilityLabel={cta.label}
          >
            <Text style={styles.ctaText}>{cta.label}</Text>
          </Pressable>
        )}

        {toast.node}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#0E2A47' },
  map:  { flex: 1, position: 'relative' },

  worldBtn: {
    position: 'absolute',
    width: 96, height: 96, minWidth: 48, minHeight: 48,
    marginLeft: -48, marginTop: -48,
    borderRadius: 48,
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderWidth: 2, borderColor: '#F5C518',
    alignItems: 'center', justifyContent: 'center',
    padding: 6,
  },
  worldTall: {
    width: 110, height: 130, marginLeft: -55, marginTop: -65,
    borderRadius: 24,
  },
  worldPulse: {
    shadowColor: '#F5C518', shadowOpacity: 0.8, shadowRadius: 12,
    shadowOffset: { width: 0, height: 0 }, elevation: 8,
  },
  worldIcon:     { fontSize: 36 },
  worldIconTall: { fontSize: 44 },
  worldLabel:    { color: '#fff', fontSize: 10, textAlign: 'center', marginTop: 2 },
  lockBadge:     { position: 'absolute', top: -6, right: -6, fontSize: 22 },

  cta: {
    position: 'absolute', bottom: 24, alignSelf: 'center', left: 0, right: 0,
    marginHorizontal: 24,
    backgroundColor: '#F5C518',
    paddingVertical: 14, borderRadius: 28,
    alignItems: 'center', elevation: 6, minHeight: 48,
  },
  ctaText: { color: '#0E2A47', fontWeight: '800', fontSize: 16 },

  toast: {
    position: 'absolute', top: 24, alignSelf: 'center',
    backgroundColor: 'rgba(27,43,58,0.95)',
    paddingHorizontal: 16, paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1, borderColor: 'rgba(245,197,24,0.4)',
  },
  toastText: { color: '#fff', fontSize: 14, fontWeight: '600' },
});
