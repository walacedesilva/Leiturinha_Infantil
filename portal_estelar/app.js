/**
 * Portal Estelar - Alfabetização Cósmica Interativa
 * Desenvolvido com HTML5 Canvas, Web Audio API e Speech Synthesis API.
 */

// Intercept console logging and direct to Flutter WebConsole channel if present
(function() {
  if (window.WebConsole) {
    const log = console.log;
    console.log = function(...args) {
      log.apply(console, args);
      window.WebConsole.postMessage(args.map(a => typeof a === 'object' ? JSON.stringify(a) : a).join(' '));
    };
    const error = console.error;
    console.error = function(...args) {
      error.apply(console, args);
      window.WebConsole.postMessage('❌ ERROR: ' + args.map(a => typeof a === 'object' ? JSON.stringify(a) : a).join(' '));
    };
    const warn = console.warn;
    console.warn = function(...args) {
      warn.apply(console, args);
      window.WebConsole.postMessage('⚠️ WARN: ' + args.map(a => typeof a === 'object' ? JSON.stringify(a) : a).join(' '));
    };
  }
})();

// ==========================================================================
// ESTADO GLOBAL DA APLICAÇÃO
// ==========================================================================
const state = {
  activePlanet: 'earth',
  streakDays: 3,
  fuelPercentage: 40,
  audioCtx: null,
  ambientOsc: null,
  ambientGain: null,
  isSpeechPlaying: false,
  speechUtterance: null,
  spatialAudio: false,
  
  // Constellation Minigame parameters
  selectedWord: "TERRA",
  currentSpelling: "",
  stars: [], // Lista de nodos de estrelas no canvas {x, y, letter, id, active}
  dragPoints: [], // Caminho arrastado pelo usuário {x, y}
  isDragging: false,
  lastConnectedStar: null,
  connectedStars: [], // Lista de IDs das estrelas conectadas na ordem correta
  
  // Alien Dialogues dataset
  aliens: {
    earth: { name: "Kael da Terra", text: "Bem-vindo à Terra, jovem astronauta! A nossa atmosfera está calma. Para podermos viajar para outros planetas, me ajude a decifrar a Constelação de Palavras. Soletrar a palavra 'TERRA' nos dará o combustível estelar necessário!", guide: "👽", word: "TERRA" },
    mercury: { name: "Pax de Mercúrio", text: "Uau, que calor! Mercúrio é o planeta mais próximo do Sol. Vamos soletrar a palavra 'SOL' rapidamente antes que nossas botas derretam!", guide: "🤖", word: "SOL" },
    venus: { name: "Luma de Vênus", text: "Olá, Explorador! Sou Luma. Vênus precisa de suas palavras para restabelecer o sinal.", guide: "🧚‍♀️", word: "NUVEM" },
    mars: { name: "Zyx de Marte", text: "Saudações, explorador! Marte é coberto de rochas vermelhas de ferro. Vamos decifrar a palavra 'MARTE' para ativar nossos propulsores!", guide: "👽", word: "MARTE" },
    jupiter: { name: "Juno de Júpiter", text: "Olá, Explorador! Sou Juno. Júpiter é o gigante gasoso! Vamos soletrar a palavra 'GIGANTE'!", guide: "🧞", word: "GIGANTE" },
    saturn: { name: "Sari de Saturno", text: "Saudações estelares! Sou Sari. Os anéis de Saturno guardam bilhetes espaciais. Vamos soletrar 'ANEL'!", guide: "🤖", word: "ANEL" },
    asteroids: { name: "Bolo do Cinturão", text: "Bzzzt! Sou Bolo. O Cinturão de Asteroides está cheio de destroços de interferência! Vamos soletrar 'ROCHA'!", guide: "👾", word: "ROCHA" },
    pluto: { name: "Pluto de Plutão", text: "Olá, bravo Explorador! Você chegou aos confins da Biblioteca Cósmica em Plutão. Vamos soletrar 'BIBLIOTECA'!", guide: "🦊", word: "BIBLIOTECA" }
  },

  // Planeta Vênus Module Active State
  venus: {
    active: false,
    currentActivityIndex: 0, // 0: ven_syllable_sort, 1: ven_word_decoder, 2: ven_mini_text
    activeWordIndex: 0,
    timerInterval: null,
    timerSecs: 60,
    scoreCorrect: 0,
    totalActions: 0,
    failedAttemptsOnCurrentItem: 0,
    placedSyllables: [],
    selectedVowelGaps: {},
    readingWordIndex: -1,
    comprehensionQuestionIndex: 0,
    activities: [
      {
        id: "ven_syllable_sort",
        type: "arrastar_silabas",
        difficulty: "facil",
        content: {
          target_words: ["casa", "gato", "bola", "sapo"],
          syllable_pool: ["ca", "sa", "to", "bo", "la", "sa", "po", "ga"],
          distractors: ["mu", "re", "fi", "lo"]
        },
        scoring: {
          base_xp: 15,
          accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.8, "3_stars": 1.0},
          time_bonus: true,
          fuel_cost: 1
        }
      },
      {
        id: "ven_word_decoder",
        type: "lacunas_vogais",
        difficulty: "medio",
        content: {
          words_with_blanks: ["c_sa", "p_t_o", "v_la", "l_na"],
          options_per_blank: ["a", "e", "i", "o", "u"],
          context_sentence: "A ___ voa alto no céu."
        },
        scoring: {
          base_xp: 20,
          accuracy_thresholds: {"1_star": 0.6, "2_stars": 0.85, "3_stars": 0.95},
          time_bonus: false,
          fuel_cost: 1
        }
      },
      {
        id: "ven_mini_text",
        type: "leitura_orbital",
        difficulty: "medio",
        content: {
          text: "Luma viu um brilho no deserto de Vênus. Era uma pedra que cantava sílabas.",
          highlight_speed_ms: 800,
          comprehension_questions: [
            {"q": "O que Luma viu?", "options": ["uma pedra", "uma nave", "um animal"], "correct": 0},
            {"q": "A pedra fazia o quê?", "options": ["chorava", "cantava sílabas", "brilhava sem som"], "correct": 1}
          ]
        },
        scoring: {
          base_xp: 25,
          accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.75, "3_stars": 0.9},
          time_bonus: false,
          fuel_cost: 2
        }
      }
    ]
  }
};

// Elementos HTML / Seletores Únicos
const els = {
  streakCounter: document.getElementById('streak-counter'),
  btnBackLobby: document.getElementById('btn-back-lobby'),
  btnToggleDevice: document.getElementById('btn-toggle-device'),
  btnRotateDevice: document.getElementById('btn-rotate-device'),
  phoneChassis: document.getElementById('phone-chassis'),
  gameStage: document.getElementById('game-stage'),
  starsBgCanvas: document.getElementById('stars-bg-canvas'),
  
  // Constellation overlay elements (Earth)
  constellationOverlay: document.getElementById('constellation-overlay'),
  constellationCanvas: document.getElementById('constellation-canvas'),
  btnCloseConstellation: document.getElementById('btn-close-constellation'),
  constellationWordTarget: document.getElementById('constellation-word-target'),
  constellationCurrentSpelling: document.getElementById('constellation-current-spelling'),
  
  // Space Map & Alien Dialogue Bubble
  orbitalMapView: document.getElementById('orbital-map-view'),
  alienDialogueBubble: document.getElementById('alien-dialogue-bubble'),
  alienName: document.getElementById('alien-name'),
  alienSpeechText: document.getElementById('alien-speech-text'),
  alienAvatar: document.getElementById('alien-avatar'),
  planetNodes: document.querySelectorAll('.planet-node'),
  
  // Sidebar elements
  fuelBarFill: document.getElementById('fuel-bar-fill'),
  fuelTextPercentage: document.getElementById('fuel-text-percentage'),
  btnHearHint: document.getElementById('btn-hear-hint'),
  btnSpatialAudio: document.getElementById('btn-spatial-audio'),
  narratorSpeed: document.getElementById('narrator-speed'),
  
  // Missions list
  mission2: document.getElementById('mission-item-2'),
  mission3: document.getElementById('mission-item-3'),

  // Planet Vênus Overlays & Selectors
  planetSelectScreen: document.getElementById('planet-select-screen'),
  btnStartVenusMission: document.getElementById('btn-start-venus-mission'),
  btnCloseSelect: document.getElementById('btn-close-select'),
  btnPlayIntroVoice: document.getElementById('btn-play-intro-voice'),
  
  briefingScreen: document.getElementById('briefing-screen'),
  briefingSpeechBubble: document.getElementById('briefing-speech-bubble'),
  btnRepeatBriefing: document.getElementById('btn-repeat-briefing'),
  btnPhoneticHint: document.getElementById('btn-phonetic-hint'),
  btnConfirmBriefing: document.getElementById('btn-confirm-briefing'),
  
  activityScreen: document.getElementById('activity-screen'),
  activityTimer: document.getElementById('activity-timer'),
  activityFuelCost: document.getElementById('activity-fuel-cost'),
  activityPlayground: document.getElementById('activity-playground'),
  btnUseHint: document.getElementById('btn-use-hint'),
  btnSkipActivity: document.getElementById('btn-skip-activity'),
  
  feedbackScreen: document.getElementById('feedback-screen'),
  feedbackAlienAvatar: document.getElementById('feedback-alien-avatar'),
  feedbackTitle: document.getElementById('feedback-title'),
  feedbackMessage: document.getElementById('feedback-message'),
  btnContinueFeedback: document.getElementById('btn-continue-feedback'),
  
  resultScreen: document.getElementById('result-screen'),
  resultStars: document.getElementById('result-stars'),
  resultXp: document.getElementById('result-xp'),
  resultWords: document.getElementById('result-words'),
  btnNextActivity: document.getElementById('btn-next-activity'),
  btnSaveJournal: document.getElementById('btn-save-journal'),
  btnResultClose: document.getElementById('btn-result-close'),
  
  btnJournal: document.getElementById('btn-journal'),
  journalOverlay: document.getElementById('journal-overlay'),
  btnCloseJournal: document.getElementById('btn-close-journal'),
  journalEntriesList: document.getElementById('journal-entries-list')
};

// ==========================================================================
// INICIALIZAÇÃO DA APLICAÇÃO
// ==========================================================================
window.addEventListener('DOMContentLoaded', () => {
  setupDeviceControls();
  setupEcosystemRedirection();
  setupPlanetSelection();
  setupAudioContext();
  setupAccessibilityControls();
  setupStarsBackground();
  setupVenusFlow();
  
  // Mostra a bolha do alien inicial após 1 segundo
  setTimeout(() => {
    triggerAlienDialogue(state.activePlanet);
  }, 1000);
});

// Redirecionamento fluído entre Portal Estelar e Reino das Histórias
function setupEcosystemRedirection() {
  if (els.btnBackLobby) {
    els.btnBackLobby.addEventListener('click', () => {
      window.location.href = '../reino_das_historias/index.html';
    });
  }
}

// Configuração do chassis de celular e rotação
function setupDeviceControls() {
  if (els.btnToggleDevice) {
    els.btnToggleDevice.addEventListener('click', () => {
      const isMobile = els.phoneChassis.classList.toggle('device-active');
      els.phoneChassis.classList.toggle('device-desktop', !isMobile);
      els.btnToggleDevice.classList.toggle('active', isMobile);
      
      if (isMobile) {
        els.phoneChassis.classList.add('device-portrait');
        els.phoneChassis.classList.remove('device-landscape');
        els.btnRotateDevice.classList.remove('hidden');
      } else {
        els.phoneChassis.classList.remove('device-portrait', 'device-landscape');
        els.btnRotateDevice.classList.add('hidden');
      }
      
      triggerCanvasResizes();
    });
  }
  
  if (els.btnRotateDevice) {
    els.btnRotateDevice.addEventListener('click', () => {
      if (els.phoneChassis.classList.contains('device-active')) {
        const isPortrait = els.phoneChassis.classList.toggle('device-portrait');
        els.phoneChassis.classList.toggle('device-landscape', !isPortrait);
        
        setTimeout(triggerCanvasResizes, 150);
      }
    });
  }
}

function triggerCanvasResizes() {
  window.dispatchEvent(new Event('resize'));
}

// ==========================================================================
// SELEÇÃO DE PLANETAS & GATILHOS DE DIÁLOGO
// ==========================================================================
const planetActivities = {
  mercury: {
    id: "mercury",
    name: "Mercúrio",
    focus: "Consciência Fonêmica & Sílabas",
    alien_guide: "🤖 Pax de Mercúrio",
    speech_intro: "Uau, que calor! Mercúrio é o planeta mais próximo do Sol. Vamos soletrar sílabas simples para reativar nosso sinal!",
    activities: [
      {
        id: "mer_syllable_sort",
        type: "arrastar_silabas",
        difficulty: "facil",
        content: {
          target_words: ["casa", "gato", "bola", "sapo"],
          syllable_pool: ["ca", "sa", "to", "bo", "la", "sa", "po", "ga"],
          distractors: ["mu", "re", "fi", "lo"]
        },
        scoring: { base_xp: 15, accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.8, "3_stars": 1.0}, fuel_cost: 1 }
      }
    ]
  },
  venus: {
    id: "venus",
    name: "Vênus",
    focus: "Decodificação & Vocabulário",
    alien_guide: "🧚‍♀️ Luma de Vênus",
    speech_intro: "Olá, Explorador! Sou Luma. Vênus precisa de suas palavras para restabelecer o sinal.",
    activities: [
      {
        id: "ven_syllable_sort",
        type: "arrastar_silabas",
        difficulty: "facil",
        content: {
          target_words: ["casa", "gato", "bola", "sapo"],
          syllable_pool: ["ca", "sa", "to", "bo", "la", "sa", "po", "ga"],
          distractors: ["mu", "re", "fi", "lo"]
        },
        scoring: { base_xp: 15, accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.8, "3_stars": 1.0}, fuel_cost: 1 }
      },
      {
        id: "ven_word_decoder",
        type: "lacunas_vogais",
        difficulty: "medio",
        content: {
          words_with_blanks: ["c_sa", "p_t_o", "v_la", "l_na"],
          options_per_blank: ["a", "e", "i", "o", "u"],
          context_sentence: "A ___ voa alto no céu."
        },
        scoring: { base_xp: 20, accuracy_thresholds: {"1_star": 0.6, "2_stars": 0.85, "3_stars": 0.95}, fuel_cost: 1 }
      },
      {
        id: "ven_mini_text",
        type: "leitura_orbital",
        difficulty: "medio",
        content: {
          text: "Luma viu um brilho no deserto de Vênus. Era uma pedra que cantava sílabas.",
          highlight_speed_ms: 800,
          comprehension_questions: [
            {"q": "O que Luma viu?", "options": ["uma pedra", "uma nave", "um animal"], "correct": 0},
            {"q": "A pedra fazia o quê?", "options": ["chorava", "cantava sílabas", "brilhava sem som"], "correct": 1}
          ]
        },
        scoring: { base_xp: 25, accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.75, "3_stars": 0.9}, fuel_cost: 2 }
      }
    ]
  },
  earth: {
    id: "earth",
    name: "Terra",
    focus: "Leitura em Voz Alta & Pontuação",
    alien_guide: "👽 Kael da Terra",
    speech_intro: "Bem-vindo à Terra, jovem astronauta! Vamos ler juntos com ritmo para calibrar nossos tradutores.",
    activities: [
      {
        id: "ear_mini_text",
        type: "leitura_orbital",
        difficulty: "facil",
        content: {
          text: "A Terra é o nosso lar azul no espaço infinito. Proteja as florestas e rios do planeta azul.",
          highlight_speed_ms: 700,
          comprehension_questions: [
            {"q": "De que cor é o nosso lar?", "options": ["azul", "vermelho", "verde"], "correct": 0},
            {"q": "O que devemos proteger?", "options": ["as estrelas", "as florestas e rios", "os meteoros"], "correct": 1}
          ]
        },
        scoring: { base_xp: 20, accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.75, "3_stars": 0.9}, fuel_cost: 1 }
      }
    ]
  },
  mars: {
    id: "mars",
    name: "Marte",
    focus: "Compreensão Literal & Inferência",
    alien_guide: "👽 Zyx de Marte",
    speech_intro: "Saudações, explorador! Marte é coberto de rochas vermelhas de ferro. Vamos responder às perguntas de compreensão!",
    activities: [
      {
        id: "mar_mini_text",
        type: "leitura_orbital",
        difficulty: "medio",
        content: {
          text: "O robô explorador viaja pelas dunas vermelhas de Marte procurando água congelada sob o solo seco.",
          highlight_speed_ms: 750,
          comprehension_questions: [
            {"q": "Quem viaja pelas dunas vermelhas?", "options": ["um alien", "um robô explorador", "uma nave"], "correct": 1},
            {"q": "O que o robô procura sob o solo?", "options": ["ouro", "água congelada", "plantas"], "correct": 1}
          ]
        },
        scoring: { base_xp: 25, accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.75, "3_stars": 0.9}, fuel_cost: 2 }
      }
    ]
  },
  jupiter: {
    id: "jupiter",
    name: "Júpiter",
    focus: "Fluência & Textos Narrativos",
    alien_guide: "🧞 Juno de Júpiter",
    speech_intro: "Olá, Explorador! Sou Juno. Júpiter é o gigante gasoso! Vamos treinar nossa fluência em leitura rápida.",
    activities: [
      {
        id: "jup_mini_text",
        type: "leitura_orbital",
        difficulty: "dificil",
        content: {
          text: "A grande tempestade de Júpiter gira como um redemoinho gigante há centenas de anos espaciais sem parar.",
          highlight_speed_ms: 600,
          comprehension_questions: [
            {"q": "O que gira em Júpiter?", "options": ["uma grande tempestade", "um satélite", "um anel"], "correct": 0},
            {"q": "Há quanto tempo a tempestade gira?", "options": ["há dez dias", "há centenas de anos", "há poucos meses"], "correct": 1}
          ]
        },
        scoring: { base_xp: 30, accuracy_thresholds: {"1_star": 0.6, "2_stars": 0.8, "3_stars": 0.95}, fuel_cost: 2 }
      }
    ]
  },
  saturn: {
    id: "saturn",
    name: "Saturno",
    focus: "Gêneros Textuais & Produção",
    alien_guide: "🤖 Sari de Saturno",
    speech_intro: "Saudações estelares! Sou Sari. Os anéis de Saturno guardam bilhetes espaciais. Vamos completar as palavras dos bilhetes!",
    activities: [
      {
        id: "sat_word_decoder",
        type: "lacunas_vogais",
        difficulty: "medio",
        content: {
          words_with_blanks: ["v_la", "l_na", "c_sa", "p_t_o"],
          options_per_blank: ["a", "e", "i", "o", "u"],
          context_sentence: "O bilhete de Saturno diz: complete a palavra ___."
        },
        scoring: { base_xp: 25, accuracy_thresholds: {"1_star": 0.6, "2_stars": 0.85, "3_stars": 0.95}, fuel_cost: 2 }
      }
    ]
  },
  asteroids: {
    id: "asteroids",
    name: "Asteroides",
    focus: "Revisão Espelhada & Desafios",
    alien_guide: "👾 Bolo do Cinturão",
    speech_intro: "Bzzzt! Sou Bolo. O Cinturão de Asteroides está cheio de destroços de interferência! Vamos reorganizar as sílabas das palavras!",
    activities: [
      {
        id: "ast_syllable_sort",
        type: "arrastar_silabas",
        difficulty: "medio",
        content: {
          target_words: ["gato", "sapo", "casa", "bola"],
          syllable_pool: ["ga", "to", "sa", "po", "ca", "sa", "bo", "la"],
          distractors: ["mu", "re", "fi", "lo"]
        },
        scoring: { base_xp: 20, accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.8, "3_stars": 1.0}, fuel_cost: 2 }
      }
    ]
  },
  pluto: {
    id: "pluto",
    name: "Plutão",
    focus: "Leitura Crítica & Autonomia",
    alien_guide: "🦊 Pluto da Borda",
    speech_intro: "Olá, bravo Explorador! Você chegou aos confins da Biblioteca Cósmica em Plutão. Vamos fazer a leitura crítica final!",
    activities: [
      {
        id: "plu_mini_text",
        type: "leitura_orbital",
        difficulty: "dificil",
        content: {
          text: "A biblioteca cósmica foi totalmente restaurada! Os exploradores agora viajam livremente pelas rotas estelares infinitas.",
          highlight_speed_ms: 700,
          comprehension_questions: [
            {"q": "O que foi restaurado?", "options": ["a biblioteca cósmica", "a tempestade", "o combustível"], "correct": 0},
            {"q": "Como os exploradores viajam agora?", "options": ["com dificuldade", "livremente", "não viajam mais"], "correct": 1}
          ]
        },
        scoring: { base_xp: 35, accuracy_thresholds: {"1_star": 0.5, "2_stars": 0.8, "3_stars": 0.95}, fuel_cost: 3 }
      }
    ]
  }
};

function setupPlanetSelection() {
  els.planetNodes.forEach(node => {
    node.addEventListener('click', () => {
      const planetId = node.dataset.planet;
      
      // Toca som de transição orbital
      playProceduralSound('sweep');
      
      // Limpa classe ativa de outros planetas
      els.planetNodes.forEach(n => n.classList.remove('active-planet'));
      node.classList.add('active-planet');
      
      state.activePlanet = planetId;
      
      openPlanetSelectScreen(planetId);
    });
  });
  
  // Abrir minigame ao clicar no próprio avatar do alien
  if (els.alienAvatar) {
    els.alienAvatar.addEventListener('click', () => {
      openConstellationGame(state.aliens[state.activePlanet].word);
    });
  }
  
  // Botões de fechar do minigame
  if (els.btnCloseConstellation) {
    els.btnCloseConstellation.addEventListener('click', () => {
      els.constellationOverlay.classList.add('panel-hidden');
    });
  }
}

function openPlanetSelectScreen(planetId) {
  const pData = planetActivities[planetId];
  if (!pData) return;
  
  if (els.alienDialogueBubble) {
    els.alienDialogueBubble.classList.add('hidden');
  }
  
  if (els.planetSelectScreen) {
    const aura = els.planetSelectScreen.querySelector('.venus-aura');
    if (aura) {
      const planetGraphics = {
        mercury: "🪨",
        venus: "🌫️",
        earth: "🌍",
        mars: "🟠",
        jupiter: "🪐",
        saturn: "💍",
        asteroids: "☄️",
        pluto: "🔭"
      };
      aura.textContent = planetGraphics[planetId] || "🪐";
    }
    
    const title = els.planetSelectScreen.querySelector('h2');
    if (title) title.textContent = `Planeta ${pData.name}`;
    
    const badge = els.planetSelectScreen.querySelector('.pedagogical-badge');
    if (badge) badge.textContent = pData.focus;
    
    const stats = els.planetSelectScreen.querySelector('.info-stats-card');
    if (stats) {
      stats.innerHTML = `
        <p><strong>Status:</strong> Livre para Exploração ✅</p>
        <p><strong>Custo de Missão:</strong> ⚡ ${pData.activities[0].scoring.fuel_cost} combustíveis</p>
      `;
    }
    
    const bubble = els.planetSelectScreen.querySelector('.luma-intro-bubble');
    if (bubble) {
      const guideSpan = bubble.querySelector('.bubble-header span');
      if (guideSpan) guideSpan.textContent = pData.alien_guide;
      
      const textP = bubble.querySelector('p');
      if (textP) textP.textContent = `"${pData.speech_intro}"`;
    }
    
    els.planetSelectScreen.classList.remove('panel-hidden');
  }
  speakLuma(pData.speech_intro);
}

function triggerAlienDialogue(planetId) {
  const data = state.aliens[planetId];
  if (!data) return;
  
  if (els.alienDialogueBubble) {
    els.alienDialogueBubble.classList.remove('hidden');
  }
  if (els.alienName) {
    els.alienName.textContent = data.name;
  }
  if (els.alienSpeechText) {
    els.alienSpeechText.textContent = data.text;
  }
  if (els.alienAvatar) {
    els.alienAvatar.textContent = data.guide;
  }
  
  // Ajusta a missão 2 para descrever a tarefa do planeta ativo
  if (els.mission2) {
    const h4 = els.mission2.querySelector('h4');
    if (h4) h4.textContent = `Constelação de ${data.name.split(' ')[0]}`;
    
    const p = els.mission2.querySelector('p');
    if (p) p.textContent = `Conecte as estrelas para formar "${data.word}".`;
    
    els.mission2.className = "mission-row active";
  }
  
  // Fala a instrução usando TTS nativo
  speakAlienInstruction(data.text);
}

// ==========================================================================
// MOTOR DE VOZ IA (TTS) INTEGRADO COM VELOCIDADE E PITCH
// ==========================================================================
function speakAlienInstruction(text) {
  let cleanText = text.replace(/\[[a-zA-Z0-9_:\s]+\]/g, '').trim();

  if (window.TTSChannel) {
    window.TTSChannel.postMessage(cleanText);
    return;
  }

  if (!window.speechSynthesis) return;
  
  // Cancela falas anteriores
  window.speechSynthesis.cancel();
  
  const u = new SpeechSynthesisUtterance(cleanText);
  state.speechUtterance = u;
  
  // Ajusta velocidade baseado no slider
  u.rate = parseFloat(els.narratorSpeed.value) || 0.9;
  
  // Seleciona voz brasileira
  const voices = window.speechSynthesis.getVoices();
  const ptVoice = voices.find(v => v.lang.includes('PT') || v.lang.includes('pt'));
  if (ptVoice) {
    u.voice = ptVoice;
  }
  
  u.onstart = () => { state.isSpeechPlaying = true; };
  u.onend = () => { state.isSpeechPlaying = false; };
  
  window.speechSynthesis.speak(u);
}

// Speech engine optimized for Luma (Alien girl of Venus)
function speakLuma(text, callback) {
  let cleanText = text.replace(/\[[a-zA-Z0-9_:\s]+\]/g, '').trim();

  if (window.TTSChannel) {
    window.TTSChannel.postMessage(cleanText);
    if (callback) {
      setTimeout(callback, 3000); // Call completed callback after typical speaking delay
    }
    return;
  }

  if (!window.speechSynthesis) {
    if (callback) callback();
    return;
  }

  window.speechSynthesis.cancel();
  state.isSpeechPlaying = true;

  const u = new SpeechSynthesisUtterance(cleanText);
  state.speechUtterance = u;

  // Modulate alien sound: Pitch 1.05 and Speed 0.95
  u.pitch = 1.05;
  u.rate = 0.95;

  const voices = window.speechSynthesis.getVoices();
  const ptVoice = voices.find(v => v.lang.includes('PT') || v.lang.includes('pt'));
  if (ptVoice) {
    u.voice = ptVoice;
  }

  u.onstart = () => {
    state.isSpeechPlaying = true;
  };

  u.onend = () => {
    state.isSpeechPlaying = false;
    if (callback) callback();
  };

  u.onerror = () => {
    state.isSpeechPlaying = false;
    if (callback) callback();
  };

  window.speechSynthesis.speak(u);
}

function setupAccessibilityControls() {
  if (els.btnHearHint) {
    els.btnHearHint.addEventListener('click', () => {
      if (state.activePlanet === 'venus') {
        triggerVenusActivityHint();
      } else {
        const targetWord = state.selectedWord;
        const currentLen = state.connectedStars.length;
        
        if (currentLen < targetWord.length) {
          const nextChar = targetWord[currentLen];
          speakAlienInstruction(`Procure pela letra... [pausa] ${nextChar}!`);
        } else {
          speakAlienInstruction("Você já conectou todas as estrelas!");
        }
      }
    });
  }
  
  if (els.btnSpatialAudio) {
    els.btnSpatialAudio.addEventListener('click', () => {
      state.spatialAudio = !state.spatialAudio;
      els.btnSpatialAudio.classList.toggle('active', state.spatialAudio);
      
      if (state.spatialAudio) {
        if (state.activePlanet === 'venus') {
          speakLuma("Áudio Espacial Cósmico ativado. Sinta a órbita de Vênus!");
        } else {
          speakAlienInstruction("Áudio Espacial Cósmico ativado. Sinta os graves espaciais!");
        }
      }
    });
  }
}

// ==========================================================================
// SINTETIZADOR PROCEDURAL CÓSMICO (WEB AUDIO API)
// ==========================================================================
function setupAudioContext() {
  const initAudio = () => {
    if (!state.audioCtx) {
      state.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      
      // Inicia som ambiente de nebulosa suave ao fundo
      state.ambientGain = state.audioCtx.createGain();
      state.ambientGain.gain.value = 0.03;
      state.ambientGain.connect(state.audioCtx.destination);
      
      state.ambientOsc = state.audioCtx.createOscillator();
      state.ambientOsc.type = 'sawtooth';
      state.ambientOsc.frequency.setValueAtTime(55, state.audioCtx.currentTime); // Frequência super grave A1
      
      // Lowpass filter para tornar o som super suave e abafado (atmosfera espacial)
      const lpFilter = state.audioCtx.createBiquadFilter();
      lpFilter.type = 'lowpass';
      lpFilter.frequency.setValueAtTime(120, state.audioCtx.currentTime);
      
      state.ambientOsc.connect(lpFilter);
      lpFilter.connect(state.ambientGain);
      state.ambientOsc.start();
    }
  };
  
  document.body.addEventListener('click', initAudio, { once: true });
}

function playProceduralSound(type) {
  if (!state.audioCtx) return;
  
  if (state.audioCtx.state === 'suspended') {
    state.audioCtx.resume();
  }
  
  const osc = state.audioCtx.createOscillator();
  const gain = state.audioCtx.createGain();
  const filter = state.audioCtx.createBiquadFilter();
  
  osc.connect(gain);
  gain.connect(filter);
  
  // Suporte a áudio espacial (Mock estéreo)
  if (state.spatialAudio) {
    const panner = state.audioCtx.createStereoPanner();
    panner.pan.value = (Math.random() * 2) - 1;
    filter.connect(panner);
    panner.connect(state.audioCtx.destination);
  } else {
    filter.connect(state.audioCtx.destination);
  }
  
  const now = state.audioCtx.currentTime;
  
  switch(type) {
    case 'sweep': // Transição de planeta
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(200, now);
      osc.frequency.exponentialRampToValueAtTime(800, now + 0.5);
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.15, now + 0.25);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.5);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1200, now);
      
      osc.start(now);
      osc.stop(now + 0.5);
      break;
      
    case 'chime': // Conectar estrela correta
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1200, now);
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.2, now + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(400, now);
      
      osc.start(now);
      osc.stop(now + 0.4);
      break;
      
    case 'error': // Erro ao conectar estrela
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(140, now);
      osc.frequency.linearRampToValueAtTime(80, now + 0.3);
      
      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(350, now);
      
      osc.start(now);
      osc.stop(now + 0.35);
      break;
      
    case 'victory_fanfare': // Sucesso total na palavra
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(261.63, now); // C4
      osc.frequency.setValueAtTime(329.63, now + 0.1); // E4
      osc.frequency.setValueAtTime(392.00, now + 0.2); // G4
      osc.frequency.setValueAtTime(523.25, now + 0.3); // C5
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.25, now + 0.1);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.8);
      
      filter.type = 'peaking';
      filter.frequency.setValueAtTime(800, now);
      
      osc.start(now);
      osc.stop(now + 0.8);
      break;

    // PROCEDURAL AUDIO SFX FOR PLANET VÊNUS
    case 'sfx_chime_soft':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(987.77, now); // B5
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.12, now + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(600, now);
      
      osc.start(now);
      osc.stop(now + 0.3);
      break;

    case 'sfx_harmonic_ping':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, now); // A5
      osc.frequency.exponentialRampToValueAtTime(1760, now + 0.4); // Sweeping octave
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.2, now + 0.08);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(400, now);
      
      osc.start(now);
      osc.stop(now + 0.6);
      break;

    case 'sfx_static_mild':
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(100, now);
      osc.frequency.linearRampToValueAtTime(300, now + 0.15);
      
      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      
      filter.type = 'bandpass';
      filter.frequency.setValueAtTime(1000, now);
      filter.Q.value = 5.0;
      
      osc.start(now);
      osc.stop(now + 0.2);
      break;

    case 'sfx_orbit_resolve':
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.linearRampToValueAtTime(880, now + 0.35);
      osc.frequency.setValueAtTime(1320, now + 0.35); // E6
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.15, now + 0.15);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.75);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1500, now);
      
      osc.start(now);
      osc.stop(now + 0.75);
      break;

    case 'sfx_click':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1500, now);
      osc.frequency.exponentialRampToValueAtTime(300, now + 0.05);
      
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(800, now);
      
      osc.start(now);
      osc.stop(now + 0.05);
      break;

    case 'sfx_word_lock':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(523.25, now); // C5
      osc.frequency.setValueAtTime(783.99, now + 0.1); // G5
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.15, now + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(300, now);
      
      osc.start(now);
      osc.stop(now + 0.4);
      break;

    case 'sfx_constellation_pop':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1046.50, now); // C6
      osc.frequency.setValueAtTime(1318.51, now + 0.06); // E6
      osc.frequency.setValueAtTime(1567.98, now + 0.12); // G6
      osc.frequency.setValueAtTime(2093.00, now + 0.18); // C7
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.18, now + 0.06);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(600, now);
      
      osc.start(now);
      osc.stop(now + 0.6);
      break;

    case 'sfx_typing_soft':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(800, now);
      
      gain.gain.setValueAtTime(0.04, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1000, now);
      
      osc.start(now);
      osc.stop(now + 0.03);
      break;

    case 'sfx_star_collect':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1567.98, now); // G6
      osc.frequency.exponentialRampToValueAtTime(3135.96, now + 0.2); // G7
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.15, now + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(1000, now);
      
      osc.start(now);
      osc.stop(now + 0.45);
      break;

    case 'sfx_rewind_gentle':
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(880, now);
      osc.frequency.exponentialRampToValueAtTime(220, now + 0.45);
      
      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(800, now);
      
      osc.start(now);
      osc.stop(now + 0.45);
      break;

    case 'sfx_journal_open':
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(180, now);
      osc.frequency.exponentialRampToValueAtTime(540, now + 0.5);
      
      gain.gain.setValueAtTime(0.01, now);
      gain.gain.linearRampToValueAtTime(0.15, now + 0.15);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.5);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(400, now);
      
      osc.start(now);
      osc.stop(now + 0.5);
      break;
  }
}

// ==========================================================================
// MINIGAME INTERATIVO: CONSTELAÇÃO DE PALAVRAS (CANVAS 2D) - TERRA
// ==========================================================================
function openConstellationGame(word) {
  if (!els.constellationOverlay || !els.constellationCanvas) return;

  state.selectedWord = word;
  state.currentSpelling = "";
  state.connectedStars = [];
  state.lastConnectedStar = null;
  state.dragPoints = [];
  
  els.constellationWordTarget.textContent = word;
  els.constellationCurrentSpelling.textContent = "";
  
  els.constellationOverlay.classList.remove('panel-hidden');
  
  // Prepara estrelas no canvas
  resizeConstellationCanvas();
  generateConstellationStars(word);
}

function resizeConstellationCanvas() {
  const canvas = els.constellationCanvas;
  if (!canvas) return;
  canvas.width = canvas.parentElement.offsetWidth || 300;
  canvas.height = canvas.parentElement.offsetHeight || 340;
  
  drawConstellation();
}
window.addEventListener('resize', () => {
  if (state.activePlanet !== 'venus') {
    resizeConstellationCanvas();
  }
});

function generateConstellationStars(word) {
  const canvas = els.constellationCanvas;
  if (!canvas) return;
  state.stars = [];
  
  const padding = 45;
  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;
  
  const step = (Math.PI * 2) / word.length;
  
  for (let i = 0; i < word.length; i++) {
    const angle = i * step + (Math.random() - 0.5) * 0.2;
    const rx = (canvas.width - padding * 2) / 2;
    const ry = (canvas.height - padding * 2) / 2;
    
    state.stars.push({
      id: i,
      letter: word[i],
      x: centerX + Math.cos(angle) * rx,
      y: centerY + Math.sin(angle) * ry,
      radius: 18,
      active: false
    });
  }
  
  drawConstellation();
}

function drawConstellation() {
  const canvas = els.constellationCanvas;
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  // 1. Desenha as linhas conectadas pelo usuário
  if (state.connectedStars.length > 1) {
    ctx.beginPath();
    ctx.strokeStyle = '#00F0FF';
    ctx.lineWidth = 4;
    ctx.shadowBlur = 15;
    ctx.shadowColor = '#00F0FF';
    
    const startStar = state.stars.find(s => s.id === state.connectedStars[0]);
    if (startStar) ctx.moveTo(startStar.x, startStar.y);
    
    for (let i = 1; i < state.connectedStars.length; i++) {
      const star = state.stars.find(s => s.id === state.connectedStars[i]);
      if (star) ctx.lineTo(star.x, star.y);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;
  }
  
  // 2. Desenha a linha elástica arrastada ativa
  if (state.isDragging && state.lastConnectedStar && state.dragPoints.length > 0) {
    ctx.beginPath();
    ctx.strokeStyle = 'rgba(255, 0, 127, 0.6)';
    ctx.lineWidth = 3;
    ctx.setLineDash([4, 4]);
    ctx.moveTo(state.lastConnectedStar.x, state.lastConnectedStar.y);
    
    const lastDragPoint = state.dragPoints[state.dragPoints.length - 1];
    ctx.lineTo(lastDragPoint.x, lastDragPoint.y);
    ctx.stroke();
    ctx.setLineDash([]);
  }
  
  // 3. Desenha cada estrela/letra individualmente
  state.stars.forEach(star => {
    ctx.save();
    
    if (star.active) {
      ctx.shadowBlur = 20;
      ctx.shadowColor = '#00F0FF';
      ctx.fillStyle = '#00F0FF';
      ctx.strokeStyle = '#FFF';
    } else {
      ctx.fillStyle = '#140F26';
      ctx.strokeStyle = 'rgba(255,255,255,0.2)';
    }
    
    ctx.beginPath();
    ctx.arc(star.x, star.y, star.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.lineWidth = 2;
    ctx.stroke();
    
    ctx.shadowBlur = 0;
    ctx.fillStyle = star.active ? '#000' : '#FFF8E7';
    ctx.font = 'bold 15px Outfit';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(star.letter, star.x, star.y);
    
    ctx.restore();
  });
}

// Configuração de interação Pointer (Mouse e Touch) no Canvas
function setupConstellationEvents() {
  const canvas = els.constellationCanvas;
  if (!canvas) return;
  
  const getMousePos = (e) => {
    const rect = canvas.getBoundingClientRect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    return {
      x: clientX - rect.left,
      y: clientY - rect.top
    };
  };
  
  const handlePointerDown = (pos) => {
    const clickedStar = findStarAtPos(pos.x, pos.y);
    
    if (clickedStar) {
      const nextExpectedLetter = state.selectedWord[state.connectedStars.length];
      
      if (clickedStar.letter === nextExpectedLetter && !clickedStar.active) {
        state.isDragging = true;
        clickedStar.active = true;
        state.lastConnectedStar = clickedStar;
        state.connectedStars.push(clickedStar.id);
        state.currentSpelling += clickedStar.letter;
        els.constellationCurrentSpelling.textContent = state.currentSpelling;
        
        playProceduralSound('chime');
        drawConstellation();
      }
    }
  };
  
  const handlePointerMove = (pos) => {
    if (!state.isDragging || !state.lastConnectedStar) return;
    
    state.dragPoints.push(pos);
    
    const hoveredStar = findStarAtPos(pos.x, pos.y);
    
    if (hoveredStar && hoveredStar.id !== state.lastConnectedStar.id) {
      const nextExpectedLetter = state.selectedWord[state.connectedStars.length];
      
      if (hoveredStar.letter === nextExpectedLetter && !hoveredStar.active) {
        hoveredStar.active = true;
        state.lastConnectedStar = hoveredStar;
        state.connectedStars.push(hoveredStar.id);
        state.currentSpelling += hoveredStar.letter;
        els.constellationCurrentSpelling.textContent = state.currentSpelling;
        
        playProceduralSound('chime');
        
        if (state.currentSpelling === state.selectedWord) {
          handleWordCompletion();
        }
      } else if (!hoveredStar.active && hoveredStar.letter !== nextExpectedLetter) {
        triggerHapticDevice();
        playProceduralSound('error');
        resetConstellationDraw();
      }
    }
    
    drawConstellation();
  };
  
  const handlePointerUp = () => {
    if (state.isDragging) {
      resetConstellationDraw();
      drawConstellation();
    }
  };
  
  canvas.addEventListener('mousedown', (e) => handlePointerDown(getMousePos(e)));
  canvas.addEventListener('mousemove', (e) => handlePointerMove(getMousePos(e)));
  window.addEventListener('mouseup', handlePointerUp);
  
  canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    handlePointerDown(getMousePos(e));
  }, { passive: false });
  
  canvas.addEventListener('touchmove', (e) => {
    e.preventDefault();
    handlePointerMove(getMousePos(e));
  }, { passive: false });
  
  window.addEventListener('touchend', handlePointerUp);
}

setupConstellationEvents();

function findStarAtPos(x, y) {
  return state.stars.find(s => {
    const dist = Math.hypot(s.x - x, s.y - y);
    return dist < s.radius + 8;
  });
}

function resetConstellationDraw() {
  state.isDragging = false;
  state.lastConnectedStar = null;
  state.connectedStars = [];
  state.currentSpelling = "";
  state.dragPoints = [];
  if (els.constellationCurrentSpelling) {
    els.constellationCurrentSpelling.textContent = "...";
  }
  
  state.stars.forEach(s => s.active = false);
}

function handleWordCompletion() {
  state.isDragging = false;
  playProceduralSound('victory_fanfare');
  
  state.fuelPercentage = Math.min(state.fuelPercentage + 20, 100);
  els.fuelBarFill.style.width = `${state.fuelPercentage}%`;
  els.fuelTextPercentage.textContent = `${state.fuelPercentage}%`;
  
  els.mission2.className = "mission-row completed";
  els.mission2.querySelector('.mission-check').textContent = "✔";
  
  if (state.fuelPercentage >= 60) {
    els.mission3.className = "mission-row active";
    els.mission3.querySelector('.mission-check').textContent = "⏳";
    document.getElementById('planet-mars').style.opacity = '1';
  }
  
  triggerCosmicCelebration();
  speakAlienInstruction(`Fantástico! Você decifrou a constelação de ${state.selectedWord}! Nosso tanque de combustível estelar está se enchendo!`);
  
  setTimeout(() => {
    els.constellationOverlay.classList.add('panel-hidden');
  }, 3200);
}

// Simulação de vibração tátil no chassis de celular
function triggerHapticDevice() {
  if (navigator.vibrate) {
    navigator.vibrate([100, 50, 100]);
  }
  
  if (els.phoneChassis.classList.contains('device-active')) {
    els.phoneChassis.classList.add('device-vibrate');
    setTimeout(() => {
      els.phoneChassis.classList.remove('device-vibrate');
    }, 400);
  }
}

// ==========================================================================
// BACKGROUND CÓSMICO DE ESTRELAS CAINDO (CANVAS 2D)
// ==========================================================================
function setupStarsBackground() {
  const canvas = els.starsBgCanvas;
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  
  let stars = [];
  
  const resize = () => {
    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;
  };
  window.addEventListener('resize', resize);
  resize();
  
  class ShootingStar {
    constructor() {
      this.x = Math.random() * canvas.width;
      this.y = Math.random() * canvas.height;
      this.size = Math.random() * 1.5 + 0.5;
      this.speed = Math.random() * 0.15 + 0.05;
      this.alpha = Math.random() * 0.4 + 0.2;
    }
    update() {
      this.y -= this.speed;
      if (this.y < 0) {
        this.y = canvas.height;
        this.x = Math.random() * canvas.width;
      }
    }
    draw() {
      ctx.save();
      ctx.globalAlpha = this.alpha;
      ctx.fillStyle = '#00F0FF';
      ctx.fillRect(this.x, this.y, this.size, this.size);
      ctx.restore();
    }
  }
  
  for (let i = 0; i < 35; i++) {
    stars.push(new ShootingStar());
  }
  
  const animate = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    stars.forEach(s => {
      s.update();
      s.draw();
    });
    requestAnimationFrame(animate);
  };
  animate();
  
  window.triggerCosmicCelebration = () => {
    for (let i = 0; i < 60; i++) {
      const s = new ShootingStar();
      s.x = canvas.width / 2;
      s.y = canvas.height / 2;
      s.size = Math.random() * 3 + 1.5;
      s.alpha = 1.0;
      
      const angle = Math.random() * Math.PI * 2;
      const velocity = Math.random() * 4 + 2;
      const vx = Math.cos(angle) * velocity;
      const vy = Math.sin(angle) * velocity;
      
      s.update = function() {
        this.x += vx;
        this.y += vy;
        this.alpha -= 0.02;
        if (this.alpha < 0) this.alpha = 0;
      };
      
      s.draw = function() {
        if (this.alpha <= 0) return;
        ctx.save();
        ctx.globalAlpha = this.alpha;
        ctx.fillStyle = Math.random() > 0.5 ? '#FF007F' : '#00F0FF';
        ctx.shadowBlur = 10;
        ctx.shadowColor = ctx.fillStyle;
        ctx.fillRect(this.x, this.y, this.size, this.size);
        ctx.restore();
      };
      
      stars.push(s);
    }
  };
}

// ==========================================================================
// MÓDULO EXCLUSIVO: PLANETA VÊNUS FLOW & ATIVIDADES
// ==========================================================================
function setupVenusFlow() {
  // Screen 1 Diário de Bordo Float Button
  if (els.btnJournal) {
    els.btnJournal.addEventListener('click', () => {
      playProceduralSound('sfx_journal_open');
      els.journalOverlay.classList.remove('panel-hidden');
      renderJournalEntries();
    });
  }
  
  if (els.btnCloseJournal) {
    els.btnCloseJournal.addEventListener('click', () => {
      playProceduralSound('sfx_click');
      els.journalOverlay.classList.add('panel-hidden');
    });
  }

  // Screen 2 selection overlay buttons
  if (els.btnCloseSelect) {
    els.btnCloseSelect.addEventListener('click', () => {
      playProceduralSound('sfx_click');
      els.planetSelectScreen.classList.add('panel-hidden');
    });
  }

  if (els.btnPlayIntroVoice) {
    els.btnPlayIntroVoice.addEventListener('click', () => {
      playProceduralSound('sfx_click');
      speakLuma("Olá, Explorador! Sou Luma. Vênus precisa de suas palavras para restabelecer o sinal.");
    });
  }

  if (els.btnStartVenusMission) {
    els.btnStartVenusMission.addEventListener('click', () => {
      // Sempre garante que o combustível seja recarregado para garantir que a criança possa jogar sem restrições de bloqueio
      state.fuelPercentage = 100;
      if (els.fuelBarFill) {
        els.fuelBarFill.style.width = '100%';
      }
      if (els.fuelTextPercentage) {
        els.fuelTextPercentage.textContent = '100%';
      }
      
      playProceduralSound('sfx_orbit_resolve');
      if (els.planetSelectScreen) {
        els.planetSelectScreen.classList.add('panel-hidden');
      }
      
      // Abre a primeira atividade
      state.venus.currentActivityIndex = 0;
      loadVenusBriefing();
    });
  }

  // Screen 3 briefing buttons
  if (els.btnRepeatBriefing) {
    els.btnRepeatBriefing.addEventListener('click', () => {
      playProceduralSound('sfx_click');
      speakLuma(els.briefingSpeechBubble.textContent);
    });
  }

  if (els.btnPhoneticHint) {
    els.btnPhoneticHint.addEventListener('click', () => {
      playProceduralSound('sfx_chime_soft');
      showPhoneticBriefingHint();
    });
  }

  if (els.btnConfirmBriefing) {
    els.btnConfirmBriefing.addEventListener('click', () => {
      playProceduralSound('sfx_click');
      els.briefingScreen.classList.add('panel-hidden');
      startVenusActivity();
    });
  }

  // Screen 4 gameplay buttons
  if (els.btnUseHint) {
    els.btnUseHint.addEventListener('click', () => {
      triggerVenusActivityHint();
    });
  }

  if (els.btnSkipActivity) {
    els.btnSkipActivity.addEventListener('click', () => {
      skipVenusActivity();
    });
  }

  // Screen 5 feedback continue button
  if (els.btnContinueFeedback) {
    els.btnContinueFeedback.addEventListener('click', () => {
      playProceduralSound('sfx_click');
      els.feedbackScreen.classList.add('panel-hidden');
      showVenusResults();
    });
  }

  // Screen 6 results buttons
  if (els.btnNextActivity) {
    els.btnNextActivity.addEventListener('click', () => {
      playProceduralSound('sfx_orbit_resolve');
      els.resultScreen.classList.add('panel-hidden');
      
      state.venus.currentActivityIndex++;
      const pData = planetActivities[state.activePlanet];
      if (pData && state.venus.currentActivityIndex < pData.activities.length) {
        loadVenusBriefing();
      } else {
        const pName = pData ? pData.name : "Planeta";
        speakLuma(`Missão de ${pName} finalizada! Você decodificou todas as palavras com sucesso.`);
        
        // Visual updates on map
        els.planetNodes.forEach(node => {
          if (node.dataset.planet === state.activePlanet) {
            node.querySelector('.planet-label').textContent = `${pName} ⭐⭐⭐`;
            node.classList.add('completed-planet');
          }
        });
      }
    });
  }

  if (els.btnSaveJournal) {
    els.btnSaveJournal.addEventListener('click', () => {
      saveVenusMissionToJournal();
    });
  }

  if (els.btnResultClose) {
    els.btnResultClose.addEventListener('click', () => {
      playProceduralSound('sfx_click');
      els.resultScreen.classList.add('panel-hidden');
    });
  }

  renderJournalEntries();
}

function loadVenusBriefing() {
  const pData = planetActivities[state.activePlanet];
  if (!pData) return;
  
  const actIndex = state.venus.currentActivityIndex;
  const act = pData.activities[actIndex];
  if (!act) return;

  els.briefingScreen.classList.remove('panel-hidden');

  let briefingText = "";
  if (act.type === "arrastar_silabas") {
    briefingText = `Olá! Sou ${pData.alien_guide.split(' ')[1]}. Vamos arrastar as sílabas e colocá-las em ordem para formar palavras mágicas em ${pData.name}!`;
  } else if (act.type === "lacunas_vogais") {
    briefingText = "Toque nas vogais que estão faltando para completar as palavras no nosso tradutor cósmico.";
  } else if (act.type === "leitura_orbital") {
    briefingText = "Leia o texto espacial que vai brilhar na órbita, e depois responda às perguntas de compreensão.";
  } else {
    briefingText = `Prepare-se para o desafio de ${pData.focus} em ${pData.name}!`;
  }

  els.briefingSpeechBubble.textContent = briefingText;
  speakLuma(briefingText);
}

function showPhoneticBriefingHint() {
  const pData = planetActivities[state.activePlanet];
  if (!pData) return;
  
  const actIndex = state.venus.currentActivityIndex;
  const act = pData.activities[actIndex];
  if (!act) return;
  
  let hint = "";
  if (act.type === "arrastar_silabas") {
    hint = "Dica: Junte os sons de cada pedacinho. Por exemplo: 'ca' mais 'sa' forma 'casa'.";
  } else if (act.type === "lacunas_vogais") {
    hint = "Dica: Tente pronunciar a palavra em voz alta para descobrir qual vogal se encaixa.";
  } else if (act.type === "leitura_orbital") {
    hint = "Dica: As palavras brilharão uma de cada vez. Acompanhe com atenção!";
  } else {
    hint = "Dica: Observe com carinho as letras espaciais.";
  }
  
  speakLuma(hint);
}

function startVenusActivity() {
  const pData = planetActivities[state.activePlanet];
  if (!pData) return;
  
  const actIndex = state.venus.currentActivityIndex;
  const act = pData.activities[actIndex];
  if (!act) return;

  // Deduct fuel cost
  const fuelCost = act.scoring.fuel_cost;
  state.fuelPercentage = Math.max(state.fuelPercentage - fuelCost * 10, 0);
  els.fuelBarFill.style.width = `${state.fuelPercentage}%`;
  els.fuelTextPercentage.textContent = `${state.fuelPercentage}%`;

  els.activityScreen.classList.remove('panel-hidden');
  els.activityFuelCost.textContent = `⚡ Cost: ${fuelCost}`;

  // Reset clock (60 seconds limit)
  state.venus.timerSecs = 60;
  els.activityTimer.textContent = `⏳ ${state.venus.timerSecs}s`;
  
  if (state.venus.timerInterval) clearInterval(state.venus.timerInterval);
  state.venus.timerInterval = setInterval(() => {
    state.venus.timerSecs--;
    els.activityTimer.textContent = `⏳ ${state.venus.timerSecs}s`;
    
    if (state.venus.timerSecs <= 0) {
      clearInterval(state.venus.timerInterval);
      finishVenusActivity();
    }
  }, 1000);

  state.venus.activeWordIndex = 0;
  state.venus.scoreCorrect = 0;
  state.venus.totalActions = 0;
  state.venus.failedAttemptsOnCurrentItem = 0;
  state.venus.placedSyllables = [];
  state.venus.comprehensionQuestionIndex = 0;
  state.venus.readingWordIndex = -1;
  
  // Clone selected planet activities array into current active session
  state.venus.activities = pData.activities;

  renderVenusActivityItem();
}

function getWordSyllables(word) {
  const map = {
    "casa": ["ca", "sa"],
    "gato": ["ga", "to"],
    "bola": ["bo", "la"],
    "sapo": ["sa", "po"]
  };
  return map[word] || [word];
}

function renderVenusActivityItem() {
  const actIndex = state.venus.currentActivityIndex;
  const act = state.venus.activities[actIndex];
  const playground = els.activityPlayground;
  playground.innerHTML = "";

  if (act.type === "arrastar_silabas") {
    const word = act.content.target_words[state.venus.activeWordIndex];
    if (!word) {
      finishVenusActivity();
      return;
    }

    state.venus.placedSyllables = [];

    const inst = document.createElement('div');
    inst.className = "drag-instruction";
    inst.textContent = `Palavra ${state.venus.activeWordIndex + 1}/4: Ordene as sílabas`;
    playground.appendChild(inst);

    const targetSyllables = getWordSyllables(word);
    
    // Slots Container
    const slotsContainer = document.createElement('div');
    slotsContainer.className = "syllable-slots-container";

    targetSyllables.forEach((_, i) => {
      const slot = document.createElement('div');
      slot.className = "syllable-slot";
      slot.dataset.index = i;
      slot.textContent = "?";
      
      slot.addEventListener('click', () => {
        if (slot.classList.contains('filled')) {
          playProceduralSound('sfx_click');
          const chipVal = slot.textContent;
          slot.textContent = "?";
          slot.classList.remove('filled');
          state.venus.placedSyllables[i] = null;
          
          const chip = Array.from(document.querySelectorAll('.syllable-chip')).find(c => c.textContent === chipVal && c.style.visibility === 'hidden');
          if (chip) chip.style.visibility = 'visible';
        }
      });

      slot.addEventListener('dragover', (e) => e.preventDefault());
      slot.addEventListener('drop', (e) => {
        e.preventDefault();
        const sylVal = e.dataTransfer.getData('text/plain');
        placeSyllableInSlot(sylVal, i, slot);
      });

      slotsContainer.appendChild(slot);
    });

    playground.appendChild(slotsContainer);

    // Chips Container
    const chipsContainer = document.createElement('div');
    chipsContainer.className = "syllable-chips-container";

    const pool = act.content.syllable_pool.concat(act.content.distractors);
    const shuffledPool = pool.sort(() => Math.random() - 0.5);

    shuffledPool.forEach(sylVal => {
      const chip = document.createElement('div');
      chip.className = "syllable-chip";
      chip.setAttribute('draggable', 'true');
      chip.textContent = sylVal;

      chip.addEventListener('dragstart', (e) => {
        e.dataTransfer.setData('text/plain', sylVal);
        playProceduralSound('sfx_click');
      });

      chip.addEventListener('click', () => {
        const emptyIndex = targetSyllables.findIndex((_, index) => !state.venus.placedSyllables[index]);
        if (emptyIndex !== -1) {
          const slot = slotsContainer.children[emptyIndex];
          placeSyllableInSlot(sylVal, emptyIndex, slot);
          chip.style.visibility = 'hidden';
        }
      });

      chipsContainer.appendChild(chip);
    });

    playground.appendChild(chipsContainer);
    playProceduralSound('sfx_chime_soft');

  } else if (act.type === "lacunas_vogais") {
    const blankWord = act.content.words_with_blanks[state.venus.activeWordIndex];
    if (!blankWord) {
      finishVenusActivity();
      return;
    }

    const contextMap = {
      "c_sa": "A minha casa é aconchegante e colorida.",
      "p_t_o": "O pato amarelo nada alegre no lago.",
      "v_la": "A vela brilha e ilumina a cabana à noite.",
      "l_na": "A nave de Luma pousou no solo da lua (luna)."
    };

    const inst = document.createElement('div');
    inst.className = "drag-instruction";
    inst.textContent = `Palavra ${state.venus.activeWordIndex + 1}/4: Complete as vogais`;
    playground.appendChild(inst);

    const gapWordContainer = document.createElement('div');
    gapWordContainer.className = "gap-word-container";

    const charArray = blankWord.split("");
    state.venus.selectedVowelGaps = {};
    let blankIndexCount = 0;

    charArray.forEach((char) => {
      if (char === "_") {
        const gap = document.createElement('div');
        gap.className = "gap-blank";
        gap.dataset.blankIndex = blankIndexCount;
        gap.textContent = "_";
        gapWordContainer.appendChild(gap);
        blankIndexCount++;
      } else {
        const letter = document.createElement('div');
        letter.className = "gap-char";
        letter.textContent = char;
        gapWordContainer.appendChild(letter);
      }
    });

    playground.appendChild(gapWordContainer);

    const contextText = contextMap[blankWord] || act.content.context_sentence;
    const contextDiv = document.createElement('div');
    contextDiv.className = "gap-context";
    contextDiv.innerHTML = `Luma diz: "<em>${contextText}</em>"`;
    playground.appendChild(contextDiv);

    const optionsGrid = document.createElement('div');
    optionsGrid.className = "vowel-options-grid";

    act.content.options_per_blank.forEach(vowel => {
      const btn = document.createElement('button');
      btn.className = "btn-vowel-option";
      btn.textContent = vowel.toUpperCase();
      btn.addEventListener('click', () => {
        playProceduralSound('sfx_click');
        selectVowelForDecoder(vowel);
      });
      optionsGrid.appendChild(btn);
    });

    playground.appendChild(optionsGrid);
    playProceduralSound('sfx_chime_soft');

  } else if (act.type === "leitura_orbital") {
    if (state.venus.readingWordIndex === -1) {
      state.venus.readingWordIndex = 0;
      
      const readingTextContainer = document.createElement('div');
      readingTextContainer.className = "reading-text-view";
      
      const words = act.content.text.split(" ");
      words.forEach((w, i) => {
        const span = document.createElement('span');
        span.className = "reading-word";
        span.textContent = w + " ";
        span.dataset.wordIndex = i;
        readingTextContainer.appendChild(span);
      });
      
      playground.appendChild(readingTextContainer);
      speakLuma(act.content.text);
      playProceduralSound('sfx_typing_soft');

      const intervalMs = act.content.highlight_speed_ms || 800;
      const highlightInterval = setInterval(() => {
        const spans = readingTextContainer.querySelectorAll('.reading-word');
        if (!spans || spans.length === 0) {
          clearInterval(highlightInterval);
          return;
        }

        if (state.venus.readingWordIndex > 0) {
          spans[state.venus.readingWordIndex - 1].classList.remove('active');
        }
        
        if (state.venus.readingWordIndex < spans.length) {
          spans[state.venus.readingWordIndex].classList.add('active');
          playProceduralSound('sfx_typing_soft');
          state.venus.readingWordIndex++;
        } else {
          clearInterval(highlightInterval);
          playProceduralSound('sfx_orbit_resolve');
          
          setTimeout(() => {
            state.venus.comprehensionQuestionIndex = 0;
            renderComprehensionQuestion();
          }, 1500);
        }
      }, intervalMs);
    }
  }
}

function placeSyllableInSlot(sylVal, index, slot) {
  playProceduralSound('sfx_click');
  slot.textContent = sylVal;
  slot.classList.add('filled');
  state.venus.placedSyllables[index] = sylVal;
  state.venus.totalActions++;

  const word = state.venus.activities[state.venus.currentActivityIndex].content.target_words[state.venus.activeWordIndex];
  const targetSyllables = getWordSyllables(word);
  
  const allFilled = targetSyllables.every((_, i) => state.venus.placedSyllables[i]);

  if (allFilled) {
    const spelledWord = state.venus.placedSyllables.join("");
    if (spelledWord === word) {
      slot.parentElement.querySelectorAll('.syllable-slot').forEach(s => {
        s.style.borderColor = '#228B22';
        s.style.boxShadow = '0 0 15px rgba(34, 139, 34, 0.8)';
      });
      playProceduralSound('sfx_harmonic_ping');
      state.venus.scoreCorrect++;
      
      setTimeout(() => {
        state.venus.activeWordIndex++;
        renderVenusActivityItem();
      }, 1200);
    } else {
      triggerHapticDevice();
      playProceduralSound('sfx_static_mild');
      state.venus.failedAttemptsOnCurrentItem++;

      slot.parentElement.querySelectorAll('.syllable-slot').forEach(s => {
        s.style.borderColor = '#FF007F';
        s.style.boxShadow = '0 0 15px rgba(255, 0, 127, 0.8)';
        s.classList.add('device-vibrate');
        setTimeout(() => {
          s.style.borderColor = '';
          s.style.boxShadow = '';
          s.classList.remove('device-vibrate');
        }, 600);
      });

      if (state.venus.failedAttemptsOnCurrentItem >= 3) {
        speakLuma("Dica cósmica: junte os sons. As sílabas corretas estão brilhando em dourado.");
        highlightCorrectSyllables(targetSyllables);
      }

      setTimeout(() => {
        slot.parentElement.querySelectorAll('.syllable-slot').forEach((s, idx) => {
          const chipVal = s.textContent;
          s.textContent = "?";
          s.classList.remove('filled');
          state.venus.placedSyllables[idx] = null;
          
          const chip = Array.from(document.querySelectorAll('.syllable-chip')).find(c => c.textContent === chipVal && c.style.visibility === 'hidden');
          if (chip) chip.style.visibility = 'visible';
        });
      }, 800);
    }
  }
}

function highlightCorrectSyllables(targetSyllables) {
  const chips = document.querySelectorAll('.syllable-chip');
  const slots = document.querySelectorAll('.syllable-slot');
  
  targetSyllables.forEach((syl, i) => {
    if (slots[i]) {
      slots[i].style.borderColor = '#FFD700';
      slots[i].style.boxShadow = '0 0 10px rgba(255, 215, 0, 0.6)';
    }
    chips.forEach(chip => {
      if (chip.textContent === syl) {
        chip.style.borderColor = '#FFD700';
        chip.style.boxShadow = '0 0 15px rgba(255, 215, 0, 0.8)';
      }
    });
  });
}

function selectVowelForDecoder(vowel) {
  const act = state.venus.activities[state.venus.currentActivityIndex];
  const blankWord = act.content.words_with_blanks[state.venus.activeWordIndex];
  
  const wordMap = {
    "c_sa": "casa",
    "p_t_o": "pato",
    "v_la": "vela",
    "l_na": "luna"
  };
  
  const correctWord = wordMap[blankWord];
  const targetVowels = [];
  
  const charArray = blankWord.split("");
  let gapIndex = 0;
  charArray.forEach((char, idx) => {
    if (char === "_") {
      targetVowels.push({
        blankIndex: gapIndex,
        charIndex: idx,
        correctChar: correctWord[idx]
      });
      gapIndex++;
    }
  });

  const activeGap = targetVowels.find(tv => !state.venus.selectedVowelGaps[tv.blankIndex]);
  if (!activeGap) return;

  state.venus.totalActions++;

  if (vowel.toLowerCase() === activeGap.correctChar.toLowerCase()) {
    playProceduralSound('sfx_word_lock');
    
    const gapEl = document.querySelector(`.gap-blank[data-blank-index="${activeGap.blankIndex}"]`);
    if (gapEl) {
      gapEl.textContent = vowel.toUpperCase();
      gapEl.style.borderBottomColor = '#228B22';
      gapEl.style.textShadow = '0 0 10px rgba(34, 139, 34, 0.8)';
      gapEl.classList.remove('pulse');
    }

    state.venus.selectedVowelGaps[activeGap.blankIndex] = vowel;

    const allDone = targetVowels.every(tv => state.venus.selectedVowelGaps[tv.blankIndex]);
    if (allDone) {
      playProceduralSound('sfx_harmonic_ping');
      state.venus.scoreCorrect++;
      
      setTimeout(() => {
        state.venus.activeWordIndex++;
        renderVenusActivityItem();
      }, 1200);
    }
  } else {
    triggerHapticDevice();
    playProceduralSound('sfx_static_mild');
    state.venus.failedAttemptsOnCurrentItem++;

    const gapEl = document.querySelector(`.gap-blank[data-blank-index="${activeGap.blankIndex}"]`);
    if (gapEl) {
      gapEl.style.borderBottomColor = '#FF007F';
      gapEl.classList.add('device-vibrate');
      setTimeout(() => {
        gapEl.style.borderBottomColor = '';
        gapEl.classList.remove('device-vibrate');
      }, 600);
    }

    if (state.venus.failedAttemptsOnCurrentItem >= 3) {
      speakLuma("Dica cósmica: o som correto é " + activeGap.correctChar.toUpperCase() + ". Veja o destaque no teclado.");
      const btns = document.querySelectorAll('.btn-vowel-option');
      btns.forEach(btn => {
        if (btn.textContent.toLowerCase() === activeGap.correctChar.toLowerCase()) {
          btn.style.borderColor = '#FFD700';
          btn.style.boxShadow = '0 0 15px rgba(255, 215, 0, 0.8)';
        }
      });
    }
  }
}

function renderComprehensionQuestion() {
  const act = state.venus.activities[state.venus.currentActivityIndex];
  const qIndex = state.venus.comprehensionQuestionIndex;
  const question = act.content.comprehension_questions[qIndex];
  const playground = els.activityPlayground;
  
  playground.innerHTML = "";

  if (!question) {
    finishVenusActivity();
    return;
  }

  const qBox = document.createElement('div');
  qBox.className = "comprehension-box";

  const title = document.createElement('h4');
  title.textContent = `Pergunta ${qIndex + 1}/2: ${question.q}`;
  qBox.appendChild(title);

  const optionsGrid = document.createElement('div');
  optionsGrid.className = "mc-options-grid";

  question.options.forEach((opt, i) => {
    const btn = document.createElement('button');
    btn.className = "btn-mc-option";
    btn.textContent = opt;
    btn.addEventListener('click', () => {
      selectMCQOption(i, question.correct, btn);
    });
    optionsGrid.appendChild(btn);
  });

  qBox.appendChild(optionsGrid);
  playground.appendChild(qBox);
  playProceduralSound('sfx_chime_soft');
}

function selectMCQOption(chosenIdx, correctIdx, btn) {
  state.venus.totalActions++;
  if (chosenIdx === correctIdx) {
    btn.style.borderColor = '#228B22';
    btn.style.background = 'rgba(34, 139, 34, 0.15)';
    playProceduralSound('sfx_star_collect');
    state.venus.scoreCorrect++;
    
    setTimeout(() => {
      state.venus.comprehensionQuestionIndex++;
      renderComprehensionQuestion();
    }, 1200);
  } else {
    triggerHapticDevice();
    playProceduralSound('sfx_static_mild');
    btn.style.borderColor = '#FF007F';
    btn.style.background = 'rgba(255, 0, 127, 0.15)';
    btn.classList.add('device-vibrate');
    setTimeout(() => {
      btn.classList.remove('device-vibrate');
    }, 600);
  }
}

function finishVenusActivity() {
  if (state.venus.timerInterval) clearInterval(state.venus.timerInterval);
  playProceduralSound('sfx_orbit_resolve');

  if (els.activityScreen) {
    els.activityScreen.classList.add('panel-hidden');
  }
  if (els.feedbackScreen) {
    els.feedbackScreen.classList.remove('panel-hidden');
  }

  const accuracy = state.venus.totalActions > 0 ? (state.venus.scoreCorrect / state.venus.totalActions) : 0;
  const guideEmoji = state.aliens[state.activePlanet]?.guide || "👽";
  
  if (accuracy >= 0.75) {
    if (els.feedbackAlienAvatar) els.feedbackAlienAvatar.textContent = guideEmoji;
    if (els.feedbackTitle) els.feedbackTitle.textContent = "Conexão Estável!";
    if (els.feedbackMessage) els.feedbackMessage.textContent = "Você decodificou a palavra com sucesso e estabilizou a órbita!";
    if (els.feedbackScreen) {
      const card = els.feedbackScreen.querySelector('.feedback-card');
      if (card) card.classList.remove('error-style');
    }
    speakLuma("Sinal estável! Você decodificou as palavras de forma maravilhosa!");
  } else {
    if (els.feedbackAlienAvatar) els.feedbackAlienAvatar.textContent = guideEmoji;
    if (els.feedbackTitle) els.feedbackTitle.textContent = "Interferência Detectada";
    if (els.feedbackMessage) els.feedbackMessage.textContent = "O transmissor cósmico precisa de calibragem rápida. Vamos revisar!";
    if (els.feedbackScreen) {
      const card = els.feedbackScreen.querySelector('.feedback-card');
      if (card) card.classList.add('error-style');
    }
    speakLuma("Interferência detectada. Observe as sílabas e tente novamente.");
  }
}

function showVenusResults() {
  els.resultScreen.classList.remove('panel-hidden');
  
  const pData = planetActivities[state.activePlanet];
  if (!pData) return;
  
  const act = pData.activities[state.venus.currentActivityIndex];
  const accuracy = state.venus.totalActions > 0 ? (state.venus.scoreCorrect / state.venus.totalActions) : 0;

  let starsStr = "⭐";
  let starCount = 1;
  const thresh = act.scoring.accuracy_thresholds;
  if (accuracy >= thresh["3_stars"]) {
    starsStr = "⭐⭐⭐";
    starCount = 3;
  } else if (accuracy >= thresh["2_stars"]) {
    starsStr = "⭐⭐";
    starCount = 2;
  }

  els.resultStars.textContent = starsStr;

  const baseXP = act.scoring.base_xp;
  const multiplier = state.streakDays >= 7 ? 1.5 : (state.streakDays >= 4 ? 1.3 : 1.2);
  const xpGained = Math.round(baseXP * multiplier);
  els.resultXp.textContent = `+${xpGained} XP`;

  let learnedWords = "NENHUMA";
  if (act.type === "arrastar_silabas") {
    learnedWords = "CASA, GATO, BOLA, SAPO";
  } else if (act.type === "lacunas_vogais") {
    learnedWords = "CASA, PATO, VELA, LUNA";
  } else if (act.type === "leitura_orbital") {
    learnedWords = "BRILHO, ESPAÇO, NAVE, LUTA";
  }

  els.resultWords.textContent = learnedWords;

  speakLuma(`Missão concluída em ${pData.name}! Você ganhou ${starCount} estrelas e ${xpGained} pontos de experiência.`);

  pData.activities[state.venus.currentActivityIndex].starsEarned = starCount;
  pData.activities[state.venus.currentActivityIndex].xpEarned = xpGained;
}

function saveVenusMissionToJournal() {
  const pData = planetActivities[state.activePlanet];
  if (!pData) return;
  
  const act = pData.activities[state.venus.currentActivityIndex];
  const starCount = act.starsEarned || 1;
  const xpEarned = act.xpEarned || 15;
  
  const entryText = `⭐ Ganhou ${starCount}★ no desafio '${act.id.replace(/^[a-z]{3}_/, "")}' de ${pData.name} (+${xpEarned} XP)`;
  
  const saved = JSON.parse(localStorage.getItem('portal_estelar_journal') || '[]');
  saved.push(entryText);
  localStorage.setItem('portal_estelar_journal', JSON.stringify(saved));
  
  playProceduralSound('sfx_constellation_pop');
  speakLuma(`Seu registro em ${pData.name} foi guardado com sucesso no Diário de Bordo.`);
  
  renderJournalEntries();
}

function renderJournalEntries() {
  if (!els.journalEntriesList) return;
  const saved = JSON.parse(localStorage.getItem('portal_estelar_journal') || '[]');
  
  els.journalEntriesList.innerHTML = "";
  
  if (saved.length === 0) {
    els.journalEntriesList.innerHTML = "<li>Nenhum registro ainda. Conclua missões para preencher seu Diário!</li>";
    return;
  }
  
  saved.reverse().forEach(entry => {
    const li = document.createElement('li');
    li.textContent = entry;
    els.journalEntriesList.appendChild(li);
  });
}

function skipVenusActivity() {
  playProceduralSound('sfx_orbit_resolve');
  speakLuma("Dobra espacial ativada! Passando para os resultados.");
  finishVenusActivity();
}

function triggerVenusActivityHint() {
  if (state.fuelPercentage < 5) {
    speakLuma("Tanque muito vazio para comprar dicas!");
    return;
  }

  state.fuelPercentage = Math.max(state.fuelPercentage - 5, 0);
  els.fuelBarFill.style.width = `${state.fuelPercentage}%`;
  els.fuelTextPercentage.textContent = `${state.fuelPercentage}%`;

  playProceduralSound('sfx_chime_soft');

  const act = state.venus.activities[state.venus.currentActivityIndex];
  let hint = "Tente observar a primeira letra.";
  if (act.type === "arrastar_silabas") {
    const word = act.content.target_words[state.venus.activeWordIndex];
    hint = `Dica cósmica: O som da palavra '${word}' inicia-se com a sílaba '${getWordSyllables(word)[0]}'.`;
  } else if (act.type === "lacunas_vogais") {
    const blankWord = act.content.words_with_blanks[state.venus.activeWordIndex];
    const wordMap = {
      "c_sa": "casa",
      "p_t_o": "pato",
      "v_la": "vela",
      "l_na": "luna"
    };
    hint = `Dica cósmica: A palavra falada correta é '${wordMap[blankWord]}'.`;
  } else if (act.type === "leitura_orbital") {
    hint = "Dica cósmica: Acompanhe a leitura brilhante com muita atenção para responder às perguntas!";
  }

  speakLuma(hint);
}
