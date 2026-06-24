/**
 * ossLicenses.js
 * -----------------------------------------------------------------------------
 * Lista declarativa de dependências e licenças usadas pelo app.
 * Mantenha sincronizado com package.json (production deps).
 *
 * Para regenerar automaticamente no futuro:
 *   npx license-checker --production --json > licenses.json
 *   e adaptar via scripts/gen-oss-licenses.js
 * -----------------------------------------------------------------------------
 */

const OSS_LICENSES = [
  {
    name: 'react-native',
    version: '0.74.5',
    license: 'MIT',
    url: 'https://github.com/facebook/react-native',
  },
  {
    name: 'react',
    version: '18.2.0',
    license: 'MIT',
    url: 'https://github.com/facebook/react',
  },
  {
    name: 'expo',
    version: '~51.0.28',
    license: 'MIT',
    url: 'https://github.com/expo/expo',
  },
  {
    name: 'expo-av',
    version: '~14.0.7',
    license: 'MIT',
    url: 'https://github.com/expo/expo/tree/main/packages/expo-av',
  },
  {
    name: 'expo-constants',
    version: '~16.0.2',
    license: 'MIT',
    url: 'https://github.com/expo/expo/tree/main/packages/expo-constants',
  },
  {
    name: 'expo-status-bar',
    version: '~1.12.1',
    license: 'MIT',
    url: 'https://github.com/expo/expo/tree/main/packages/expo-status-bar',
  },
  {
    name: '@react-navigation/native',
    version: '^6.1.18',
    license: 'MIT',
    url: 'https://github.com/react-navigation/react-navigation',
  },
  {
    name: '@react-navigation/bottom-tabs',
    version: '^6.6.1',
    license: 'MIT',
    url: 'https://github.com/react-navigation/react-navigation',
  },
  {
    name: '@react-navigation/native-stack',
    version: '^6.11.0',
    license: 'MIT',
    url: 'https://github.com/react-navigation/react-navigation',
  },
  {
    name: '@react-native-async-storage/async-storage',
    version: '1.23.1',
    license: 'MIT',
    url: 'https://github.com/react-native-async-storage/async-storage',
  },
  {
    name: 'zustand',
    version: '^4.5.5',
    license: 'MIT',
    url: 'https://github.com/pmndrs/zustand',
  },
  {
    name: 'react-native-safe-area-context',
    version: '4.10.5',
    license: 'MIT',
    url: 'https://github.com/th3rdwave/react-native-safe-area-context',
  },
  {
    name: 'react-native-screens',
    version: '3.31.1',
    license: 'MIT',
    url: 'https://github.com/software-mansion/react-native-screens',
  },
  {
    name: 'react-native-svg',
    version: '15.2.0',
    license: 'MIT',
    url: 'https://github.com/software-mansion/react-native-svg',
  },
  {
    name: 'react-native-gesture-handler',
    version: '~2.16.1',
    license: 'MIT',
    url: 'https://github.com/software-mansion/react-native-gesture-handler',
  },
];

export default OSS_LICENSES;
