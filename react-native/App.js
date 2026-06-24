/**
 * App.js — ponto de entrada do projeto React Native.
 * Envolve o AppNavigator no SafeAreaProvider.
 */

import React, { useEffect } from 'react';
import { StatusBar } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useFonts } from 'expo-font';
import AppNavigator from './src/navigation/AppNavigator';
import { initSettingsBridge, disposeSettingsBridge } from './src/services/settingsBridge';

export default function App() {
  // Carrega fontes customizadas. Falha silenciosa: app continua
  // funcional com fallback do sistema.
  const [fontsLoaded] = useFonts({
    // eslint-disable-next-line global-require
    'OpenDyslexic-Regular': require('../assets/fonts/OpenDyslexic-Regular.otf'),
  });

  useEffect(() => {
    initSettingsBridge();
    return () => disposeSettingsBridge();
  }, []);

  // Não bloqueia a UI: renderiza mesmo enquanto a fonte carrega;
  // componentes que usam dyslexiaFont mostrarão a fonte assim que pronta.
  return (
    <SafeAreaProvider>
      <StatusBar barStyle="light-content" backgroundColor="#0E2A47" />
      <AppNavigator />
    </SafeAreaProvider>
  );
}

// Suprime warning de render antes de fonte carregar (comportamento correto).
if (__DEV__) {
  // eslint-disable-next-line no-console
  const orig = console.error.bind(console);
  console.error = (...args) => {
    if (typeof args[0] === 'string' && args[0].includes('fontFamily')) return;
    orig(...args);
  };
}
