/**
 * AppNavigator.js
 * -----------------------------------------------------------------------------
 * Estrutura de navegação do "Alfabetização Mágica".
 *
 * Refactor (QA P0 / CRIT-004): as telas de mundo agora vivem DENTRO da aba
 * "Início" via Stack aninhado, garantindo que a Tab Bar permaneça visível
 * em todas as telas (checklist 1.2). Deep links continuam protegidos pelo
 * guard `withUnlockGuard`.
 * -----------------------------------------------------------------------------
 */

import React, { useEffect } from 'react';
import { NavigationContainer, useNavigation } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';

import HomeMapScreen from '../screens/HomeMapScreen';
import DesafiosScreen from '../screens/DesafiosScreen';
import ConquistasScreen from '../screens/ConquistasScreen';
import SettingsScreen from '../screens/SettingsScreen';
import OssLicensesScreen from '../screens/OssLicensesScreen';

import VilaScreen from '../screens/worlds/VilaScreen';
import BairroScreen from '../screens/worlds/BairroScreen';
import CidadeScreen from '../screens/worlds/CidadeScreen';
import ReinoScreen from '../screens/worlds/ReinoScreen';

import SplashScreen from '../screens/SplashScreen';
import ConsentScreen from '../screens/ConsentScreen';
import { useProgressStore } from '../store/progressStore';

const Tab = createBottomTabNavigator();
const RootStack = createNativeStackNavigator();
const HomeStack = createNativeStackNavigator();

// ---------------------------------------------------------------------------
// Guard HOC: protege telas de mundos contra acesso direto / deep links
// ---------------------------------------------------------------------------
function withUnlockGuard(WorldComponent, worldId) {
  return function Guarded(props) {
    const canEnter = useProgressStore((s) => s.canEnter(worldId));
    const markPlaying = useProgressStore((s) => s.markPlaying);
    const navigation = useNavigation();

    useEffect(() => {
      if (!canEnter) {
        navigation.reset({ index: 0, routes: [{ name: 'WorldMap' }] });
      } else {
        markPlaying(worldId);
      }
    }, [canEnter, markPlaying, navigation]);

    if (!canEnter) return null;
    return <WorldComponent {...props} />;
  };
}

const VilaGuarded   = withUnlockGuard(VilaScreen,   'vila');
const BairroGuarded = withUnlockGuard(BairroScreen, 'bairro');
const CidadeGuarded = withUnlockGuard(CidadeScreen, 'cidade');
const ReinoGuarded  = withUnlockGuard(ReinoScreen,  'reino');

// ---------------------------------------------------------------------------
// Stack aninhado da aba Home (mantém Tab Bar visível nos mundos)
// ---------------------------------------------------------------------------
function HomeStackNav() {
  return (
    <HomeStack.Navigator
      initialRouteName="WorldMap"
      screenOptions={{
        headerStyle: { backgroundColor: '#0E2A47' },
        headerTintColor: '#F5C518',
        headerTitleStyle: { color: '#fff', fontWeight: '700' },
        headerBackTitleVisible: false,
        animation: 'slide_from_right',
      }}
    >
      <HomeStack.Screen
        name="WorldMap"
        component={HomeMapScreen}
        options={{ headerShown: false }}
      />
      <HomeStack.Screen name="VilaScreen"   component={VilaGuarded}   options={{ title: 'Vila das Vogais' }} />
      <HomeStack.Screen name="BairroScreen" component={BairroGuarded} options={{ title: 'Bairro das Famílias' }} />
      <HomeStack.Screen name="CidadeScreen" component={CidadeGuarded} options={{ title: 'Cidade das Sílabas' }} />
      <HomeStack.Screen name="ReinoScreen"  component={ReinoGuarded}  options={{ title: 'Reino das Histórias' }} />
    </HomeStack.Navigator>
  );
}

// ---------------------------------------------------------------------------
// Tabs (raiz "lógica" do app — Home é o Mapa Mundial)
// ---------------------------------------------------------------------------
function MainTabs() {
  return (
    <Tab.Navigator
      initialRouteName="Home"
      screenOptions={{
        headerShown: false,
        tabBarHideOnKeyboard: true,
        tabBarStyle: { backgroundColor: '#0E2A47', borderTopColor: 'transparent' },
        tabBarActiveTintColor: '#F5C518',
        tabBarInactiveTintColor: 'rgba(255,255,255,0.6)',
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeStackNav}
        options={{
          title: 'Início',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'home' : 'home-outline'} size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Desafios"
        component={DesafiosScreen}
        options={{
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'game-controller' : 'game-controller-outline'} size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Conquistas"
        component={ConquistasScreen}
        options={{
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'star' : 'star-outline'} size={size} color={color} />
          ),
        }}
      />
      {/* Route name 'Perfil' mantido para retrocompatibilidade com
          navigate('Perfil') do ReadAloudButton. Componente é SettingsScreen. */}
      <Tab.Screen
        name="Perfil"
        component={SettingsScreen}
        options={{
          title: 'Ajustes',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'person' : 'person-outline'} size={size} color={color} />
          ),
        }}
      />
    </Tab.Navigator>
  );
}

// ---------------------------------------------------------------------------
// Linking: deep links de mundos passam pelo HomeStack → guard
// ---------------------------------------------------------------------------
const linking = {
  prefixes: ['alfabetizacaomagica://', 'https://alfabetizacaomagica.app'],
  config: {
    screens: {
      Splash:   'splash',
      Consent:  'consentimento',
      MainTabs: {
        screens: {
          Home: {
            screens: {
              WorldMap:     '',
              VilaScreen:   'mundo/vila',
              BairroScreen: 'mundo/bairro',
              CidadeScreen: 'mundo/cidade',
              ReinoScreen:  'mundo/reino',
            },
          },
          Desafios:   'desafios',
          Conquistas: 'conquistas',
          Perfil:     'perfil',
        },
      },
      OssLicenses: 'licencas',
    },
  },
};

// ---------------------------------------------------------------------------
// Root
// ---------------------------------------------------------------------------
export default function AppNavigator() {
  return (
    <NavigationContainer linking={linking}>
      <RootStack.Navigator
        initialRouteName="Splash"
        screenOptions={{ headerShown: false, animation: 'fade' }}
      >
        <RootStack.Screen name="Splash"   component={SplashScreen} />
        <RootStack.Screen name="Consent"  component={ConsentScreen} />
        <RootStack.Screen name="MainTabs" component={MainTabs} />
        <RootStack.Screen
          name="OssLicenses"
          component={OssLicensesScreen}
          options={{
            headerShown: true,
            title: 'Licenças de Terceiros',
            headerStyle: { backgroundColor: '#0E2A47' },
            headerTintColor: '#F5C518',
            headerTitleStyle: { color: '#fff', fontWeight: '700' },
          }}
        />
      </RootStack.Navigator>
    </NavigationContainer>
  );
}
