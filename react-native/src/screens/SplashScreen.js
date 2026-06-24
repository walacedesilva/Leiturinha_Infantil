/**
 * SplashScreen.js
 * Splash rápido (<2s). Roteia para ConsentScreen no primeiro acesso
 * (ou quando a política for atualizada) e para MainTabs depois.
 */

import React, { useEffect } from 'react';
import { View, Image, ActivityIndicator, StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useConsentStore } from '../store/consentStore';

const SPLASH_MS = 1800;

// eslint-disable-next-line global-require
const LOGO = require('../../../assets/images/logo.png');

export default function SplashScreen() {
  const navigation = useNavigation();
  const isCurrentPolicyAccepted = useConsentStore((s) => s.isCurrentPolicyAccepted);

  useEffect(() => {
    const t = setTimeout(() => {
      const next = isCurrentPolicyAccepted() ? 'MainTabs' : 'Consent';
      navigation.reset({ index: 0, routes: [{ name: next }] });
    }, SPLASH_MS);
    return () => clearTimeout(t);
  }, [navigation, isCurrentPolicyAccepted]);

  return (
    <View style={styles.root}>
      <Image source={LOGO} style={styles.logo} resizeMode="contain" />
      <ActivityIndicator color="#F5C518" size="large" style={styles.spinner} />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#0E2A47',
    alignItems: 'center',
    justifyContent: 'center',
  },
  logo: {
    width: '70%',
    height: undefined,
    aspectRatio: 1,
  },
  spinner: { marginTop: 32 },
});
