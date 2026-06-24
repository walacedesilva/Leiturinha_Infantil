# Alfabetização Mágica — React Native (Expo)

App pedagógico de alfabetização para crianças 4–7 anos, em pt-BR.

## Setup

```powershell
cd react-native
npm install
npm start            # Expo dev server
npm run android      # ou: expo start --android
npm run ios          # ou: expo start --ios
npm run web
```

## Estrutura

```
react-native/
├─ App.js                  # SafeAreaProvider + AppNavigator
├─ index.js                # registerRootComponent
├─ app.json                # config Expo (permissões mic, scheme, etc.)
├─ package.json
├─ babel.config.js
└─ src/
   ├─ navigation/AppNavigator.js   # RootStack(Splash, Consent, MainTabs)
   ├─ screens/
   │  ├─ SplashScreen.js
   │  ├─ ConsentScreen.js          # LGPD + ParentalGate
   │  ├─ HomeMapScreen.js          # mapa mundial
   │  ├─ DesafiosScreen.js         # leitura em voz alta (ASR)
   │  ├─ ConquistasScreen.js
   │  ├─ PerfilScreen.js
   │  └─ worlds/
   │     ├─ VilaScreen.js          # Phase 1 — vogais
   │     ├─ BairroScreen.js        # Phase 2 — sílabas CV (B/C/D/F/M)
   │     ├─ CidadeScreen.js        # Phase 3 — clusters CCV
   │     └─ ReinoScreen.js         # Phase 4 — histórias
   ├─ components/
   │  ├─ ParentalGate.js           # matemática 22..98
   │  ├─ SyllableLearnChallenge.js # fluxo aprender+desafio compartilhado
   │  └─ ReadAloudButton.js        # mic + match fonético
   ├─ services/
   │  ├─ audioService.js           # wrapper expo-av (fallback noop)
   │  ├─ speechService.js          # ASR (expo / voice / mock)
   │  └─ phoneticMatch.js          # fuzzy match tolerante
   ├─ store/
   │  ├─ progressStore.js          # Zustand + AsyncStorage v3
   │  └─ consentStore.js           # LGPD persistido
   └─ data/
      ├─ phase1Vowels.js
      ├─ phase2Syllables.js
      ├─ phase3Clusters.js
      └─ phase4Stories.js
```

## Áudio

- **Phase 2 (Bairro)**: 25 .wav de sílabas CV em `../assets/audio/syllables/`.
- **Phase 1, 3**: `audio: null` — fallback silencioso até gerar TTS.
  - Pipeline: `python ..\tools\tts\azure_synthesize.py --bank`.

## ASR (mic)

O `speechService` detecta backends em ordem: `expo-speech-recognition` →
`@react-native-voice/voice` → `mock` (devolve `mockAnswer` após 900ms).
Para ativar mic real:

```powershell
npm install expo-speech-recognition
```

Sem isso, o app roda em modo simulado — funcional para QA de UX.

## Privacidade (LGPD)

- Tudo fica no aparelho (AsyncStorage). Sem servidores, sem cadastro, sem ads.
- Microfone é opt-in granular (separado do consentimento geral).
- Revogação visível em Perfil → volta ao `ConsentScreen`.
