/**
 * Reino das Histórias - Engine Multissensorial & Narração por IA
 * Desenvolvido com HTML5, Web Audio API e Speech Synthesis API.
 */

// ==========================================================================
// ESTADO GLOBAL DA APLICAÇÃO
// ==========================================================================
const state = {
  stories: [],
  currentStory: null,
  currentScene: null,
  currentSceneIndex: 0,
  draggedElementId: null,
  isNarrationPlaying: false,
  narrationSpeed: 1.0,
  narrationPitch: 1.0,
  narrationStability: 0.5,
  narrationClarity: 0.7,
  narrationMode: 'teatral', // teatral, guiado, dinamico, texto
  headphoneMode: false,
  characterColors: true,
  audioCtx: null,
  musicNode: null,
  musicGain: null,
  wordsMetadata: [], // Guarda as palavras e seus metadados para sincronização karaoke
  currentSpeechUtterance: null,
  speechTimeout: null,
  particleSystem: null,
  customStories: []
};

// Elementos HTML / Seletores Únicos
const els = {
  storySelector: document.getElementById('story-selector'),
  btnHomeLobby: document.getElementById('btn-home-lobby'),
  resetStoryBtn: document.getElementById('reset-story-btn'),
  currentSceneTitle: document.getElementById('current-scene-title'),
  storyProgressFill: document.getElementById('story-progress-fill'),
  stageCanvas: document.getElementById('stage-canvas'),
  particlesOverlay: document.getElementById('particles-overlay'),
  activeZonesContainer: document.getElementById('active-zones-container'),
  scenicActorsContainer: document.getElementById('scenic-actors-container'),
  dragShelf: document.getElementById('drag-shelf'),
  speakerName: document.getElementById('speaker-name'),
  karaokeBoard: document.getElementById('karaoke-board'),
  btnToggleDevice: document.getElementById('btn-toggle-device'),
  btnRotateDevice: document.getElementById('btn-rotate-device'),
  deviceFrameWrapper: document.getElementById('device-frame-wrapper'),
  
  // Sliders
  stabilitySlider: document.getElementById('stability-slider'),
  claritySlider: document.getElementById('clarity-slider'),
  speedSlider: document.getElementById('speed-slider'),
  pitchSlider: document.getElementById('pitch-slider'),
  stabilityVal: document.getElementById('stability-val'),
  clarityVal: document.getElementById('clarity-val'),
  speedVal: document.getElementById('speed-val'),
  pitchVal: document.getElementById('pitch-val'),
  
  // Waveform
  waveformBars: document.getElementById('waveform-bars'),
  
  // Modos de Narração
  modeTeatral: document.getElementById('mode-teatral'),
  modeGuiado: document.getElementById('mode-guiado'),
  modeDinamico: document.getElementById('mode-dinamico'),
  modeTexto: document.getElementById('mode-texto'),
  
  // Acessibilidade
  btnRepeatPhrase: document.getElementById('btn-repeat-phrase'),
  btnHeadphoneMode: document.getElementById('btn-headphone-mode'),
  btnCharacterColors: document.getElementById('btn-character-colors'),
  btnPlayPauseNarration: document.getElementById('btn-play-pause-narration'),
  
  // Editor
  editorStoryTitle: document.getElementById('editor-story-title'),
  editorSceneId: document.getElementById('editor-scene-id'),
  editorSceneTitle: document.getElementById('editor-scene-title'),
  editorVisualTheme: document.getElementById('editor-visual-theme'),
  editorNarrationText: document.getElementById('editor-narration-text'),
  editorDragItemSelect: document.getElementById('editor-drag-item-select'),
  editorPromptText: document.getElementById('editor-prompt-text'),
  editorSuccessText: document.getElementById('editor-success-text'),
  addSceneBtn: document.getElementById('add-scene-btn'),
  exportJsonBtn: document.getElementById('export-json-btn'),
  customScenesList: document.getElementById('custom-scenes-list')
};

// Fallback robusto caso stories.json não possa ser carregado
const DEFAULT_STORIES_FALLBACK = [
  {
    "story_id": "reino_floresta_encantada_01",
    "title": "A Chave da Floresta Encantada",
    "target_age": "6-10 anos",
    "voice_settings": {
      "narrator_role": "contador_caloroso_misterioso",
      "base_stability": 0.5,
      "base_clarity": 0.7,
      "default_speed": 1.0
    },
    "scenes": [
      {
        "scene_id": "intro_forest",
        "title": "A Chegada",
        "visual_type": "forest",
        "drag_elements": [
          {"id": "backpack_item", "type": "mochila", "label": "🎒 Mochila Mágica", "description": "Guarda seus pertences e poções."}
        ],
        "narration": {
          "text": "[suave] Era uma manhã de neblina... [pausa 1.5s] Quando você chegou à borda da Floresta Encantada. [sussurrando] Dizem que apenas os corajosos... conseguem entrar...",
          "emotion": "mysterious_warm",
          "background_music": "forest_ambient_soft",
          "trigger_on_load": true
        },
        "interactive_prompt": {
          "instruction": "Arraste sua Mochila Mágica para o Inventário para se preparar!",
          "voice_hint": "[animado] Antes de entrar... que tal organizar sua mochila no inventário?",
          "drop_zone": "backpack_ui",
          "success_narration": "[alegre] Perfeito! Você está pronto para explorar!",
          "fail_narration": "[suave] Hmm, tente colocar a mochila na área do Inventário brilhante."
        },
        "next_scene": "crystal_riddle"
      },
      {
        "scene_id": "crystal_riddle",
        "title": "O Enigma dos Cristais",
        "visual_type": "cave",
        "drag_elements": [
          {"id": "crystal_red", "type": "cristal", "color": "red", "label": "🔴 Cristal de Fogo", "description": "Brilha com um calor interno."},
          {"id": "crystal_blue", "type": "cristal", "color": "blue", "label": "🔵 Cristal de Gelo", "description": "Frio como o topo da montanha."},
          {"id": "crystal_green", "type": "cristal", "color": "green", "label": "🟢 Cristal da Natureza", "description": "Vibra com a energia da floresta."}
        ],
        "narration": {
          "text": "[misterioso] Diante de você... três pedestais antigos... [pausa 1s] e três cristais brilhantes: [ênfase] Vermelho... Azul... e Verde... [sussurrando] Apenas a ordem correta... abrirá o portão do tesouro...",
          "emotion": "mysterious_warm",
          "background_music": "mystery_puzzle_ambient",
          "trigger_on_load": true
        },
        "interactive_prompt": {
          "instruction": "Coloque cada cristal no seu respectivo pedestal de cor!",
          "voice_hint": "[animado] Combine as cores dos cristais com os símbolos dos pedestais!",
          "is_ordered_puzzle": true,
          "placements": {
            "crystal_red": "pedestal_1",
            "crystal_blue": "pedestal_2",
            "crystal_green": "pedestal_3"
          },
          "drop_zones": [
            {"id": "pedestal_1", "color": "red", "label": "Pedestal Vermelho"},
            {"id": "pedestal_2", "color": "blue", "label": "Pedestal Azul"},
            {"id": "pedestal_3", "color": "green", "label": "Pedestal Verde"}
          ],
          "success_narration": "[épico] CRAC! [efeito:pedra] Os pedestais afundam... uma luz dourada inunda a sala... [pausa 2s] [maravilhado] O portão... está se abrindo!",
          "fail_narration": "[suave] Hmm... talvez não seja essa a ordem..."
        },
        "next_scene": "wise_king_hall"
      },
      {
        "scene_id": "wise_king_hall",
        "title": "O Salão do Rei Sábio",
        "visual_type": "castle",
        "drag_elements": [
          {"id": "golden_crown", "type": "coroa", "label": "👑 Coroa Perdida", "description": "A insígnia da realeza sagrada."}
        ],
        "narration": {
          "text": "[calmo] Você entra no salão majestoso. Lá está o Rei Sábio, com seu olhar bondoso. Ele fala com você: [rei_sabio] 'Bem-vindo, jovem aventureiro. Estou sem minha coroa sagrada — pausa — você a encontrou?'",
          "emotion": "calm_authority",
          "background_music": "castle_ambient",
          "trigger_on_load": true
        },
        "interactive_prompt": {
          "instruction": "Devolva a Coroa Perdida para o Rei Sábio!",
          "voice_hint": "[rei_sabio] Coloque minha coroa de volta, por favor.",
          "drop_zone": "wise_king",
          "success_narration": "[rei_sabio] [alegre] Magnífico! Você restaurou a honra de todo o Reino das Histórias! Muito obrigado!",
          "fail_narration": "[rei_sabio] [suave] A coroa deve ser colocada na minha cabeça."
        },
        "next_scene": "victory_scene"
      },
      {
        "scene_id": "victory_scene",
        "title": "A Grande Celebração",
        "visual_type": "victory",
        "drag_elements": [],
        "narration": {
          "text": "[animado] E assim... com inteligência e coragem, sua jornada chega ao fim! [fada_travessa] Yupi! Que aventura fantástica! [dragao_anciao] Você se provou um verdadeiro herói... muito bem! [suave] Todos celebram sua grande conquista!",
          "emotion": "joyful",
          "background_music": "victory_fanfare",
          "trigger_on_load": true
        },
        "interactive_prompt": {
          "instruction": "Parabéns! Você completou a jornada!",
          "is_victory": true
        }
      }
    ]
  }
];

// ==========================================================================
// INICIALIZAÇÃO DA APLICAÇÃO
// ==========================================================================
window.addEventListener('DOMContentLoaded', async () => {
  setupAudioContext();
  setupSliders();
  setupModes();
  setupAccessibility();
  setupDragAndDropSupport();
  setupParticleSystem();
  setupEditorForm();
  
  await loadStories();
  setupStorySelector();
  
  // Inicia mostrando o saguão principal do Reino
  showMainLobby();
  
  // Waveform simulator loop
  setInterval(simulateWaveform, 100);
});

// Inicializar Web Audio API
function setupAudioContext() {
  const initAudio = () => {
    if (!state.audioCtx) {
      state.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      startAmbientSynth();
    }
  };
  // Inicia ao interagir com a tela para evitar bloqueio de som do navegador
  document.body.addEventListener('click', initAudio, { once: true });
  document.body.addEventListener('dragstart', initAudio, { once: true });
}

// ==========================================================================
// CARREGAMENTO DE DADOS (STORIES JSON)
// ==========================================================================
async function loadStories() {
  try {
    const response = await fetch('stories.json');
    if (response.ok) {
      state.stories = await response.json();
    } else {
      console.warn('Falha ao carregar stories.json por fetch. Usando fallback.');
      state.stories = [...DEFAULT_STORIES_FALLBACK];
    }
  } catch (e) {
    console.warn('Erro ao carregar histórias por rede. Iniciando com fallback offline.', e);
    state.stories = [...DEFAULT_STORIES_FALLBACK];
  }
  
  // Carrega histórias customizadas salvas localmente
  const localStories = localStorage.getItem('reino_historias_custom');
  if (localStories) {
    try {
      state.customStories = JSON.parse(localStories);
      state.stories = [...state.stories, ...state.customStories];
    } catch (e) {
      console.error('Erro ao ler histórias do localStorage:', e);
    }
  }
}

function setupStorySelector() {
  els.storySelector.innerHTML = '';
  state.stories.forEach((st, idx) => {
    const opt = document.createElement('option');
    opt.value = idx;
    opt.textContent = `${st.title} (${st.target_age})`;
    els.storySelector.appendChild(opt);
  });
  
  els.storySelector.addEventListener('change', (e) => {
    const idx = parseInt(e.target.value);
    playStory(state.stories[idx]);
  });
  
  els.resetStoryBtn.addEventListener('click', () => {
    if (state.currentStory) {
      playStory(state.currentStory);
    }
  });
}

// ==========================================================================
// CONTROLADOR DO FLUXO DE HISTÓRIA / JOGO
// ==========================================================================
function playStory(story) {
  state.currentStory = story;
  state.currentSceneIndex = 0;
  loadScene(story.scenes[0]);
}

function loadScene(scene) {
  state.currentScene = scene;
  stopAllNarration();
  
  // Atualiza título e progresso
  els.currentSceneTitle.textContent = `${state.currentStory.title} - ${scene.title}`;
  const progressPercent = ((state.currentSceneIndex + 1) / state.currentStory.scenes.length) * 100;
  els.storyProgressFill.style.width = `${progressPercent}%`;
  
  // Atualiza Background visual do palco
  els.stageCanvas.className = `stage-canvas scene-${scene.visual_type || 'forest'}`;
  
  // Limpa elementos antigos
  els.activeZonesContainer.innerHTML = '';
  els.scenicActorsContainer.innerHTML = '';
  els.dragShelf.innerHTML = '';
  
  // Renderiza Drop Zones
  const prompt = scene.interactive_prompt;
  if (prompt) {
    // Puzzle ordenado de cristais (Cena 2)
    if (prompt.is_ordered_puzzle && prompt.drop_zones) {
      prompt.drop_zones.forEach(zone => {
        const dropEl = document.createElement('div');
        dropEl.id = zone.id;
        dropEl.className = `dropzone-element dropzone-${zone.color}`;
        dropEl.innerHTML = `<span>📥</span><div style="font-size:0.7rem; margin-top:4px;">${zone.label}</div>`;
        dropEl.dataset.targetColor = zone.color;
        els.activeZonesContainer.appendChild(dropEl);
      });
      setupDropZones();
    } 
    // Outras zonas de drop simples (Ex: Mochila, Rei Sábio)
    else if (prompt.drop_zone) {
      const dropEl = document.createElement('div');
      dropEl.id = prompt.drop_zone;
      dropEl.className = 'dropzone-element';
      
      if (prompt.drop_zone === 'backpack_ui') {
        dropEl.innerHTML = `<span>🎒</span><div style="font-size:0.7rem; margin-top:4px;">Inventário Mágico</div>`;
        els.activeZonesContainer.appendChild(dropEl);
      } 
      else if (prompt.drop_zone === 'wise_king') {
        // Personagem interativo no palco
        const kingActor = document.createElement('div');
        kingActor.className = 'character-wise-king';
        els.scenicActorsContainer.appendChild(kingActor);
        
        dropEl.innerHTML = `<span>👑 Devólva a Coroa</span>`;
        dropEl.style.position = 'absolute';
        dropEl.style.bottom = '160px';
        dropEl.style.width = '120px';
        dropEl.style.height = '60px';
        dropEl.style.borderRadius = '30px';
        els.activeZonesContainer.appendChild(dropEl);
      }
      setupDropZones();
    }
    
    // Se for cena de vitória, renderiza um banner comemorativo
    if (prompt.is_victory) {
      const banner = document.createElement('div');
      banner.className = 'victory-banner';
      banner.innerHTML = `
        <h2>🎉 PARABÉNS! 🎉</h2>
        <p>Você completou o enigma!</p>
        <button onclick="state.currentSceneIndex = 0; playStory(state.currentStory);" class="btn-primary" style="margin-top:20px; font-size:0.9rem; padding:8px 16px;">
          🔄 Jogar Novamente
        </button>
      `;
      els.activeZonesContainer.appendChild(banner);
      triggerCelebration();
    }
  }
  
  // Renderiza Draggable items na prateleira (Shelf)
  if (scene.drag_elements && scene.drag_elements.length > 0) {
    scene.drag_elements.forEach(item => {
      const dragEl = document.createElement('div');
      dragEl.id = item.id;
      dragEl.className = 'drag-item';
      dragEl.setAttribute('draggable', 'true');
      dragEl.dataset.type = item.type;
      dragEl.dataset.color = item.color || '';
      dragEl.innerHTML = `
        ${item.label}
        <span class="info-tooltip">${item.description}</span>
      `;
      els.dragShelf.appendChild(dragEl);
      setupDragItem(dragEl);
    });
  } else {
    els.dragShelf.innerHTML = `<p class="text-muted" style="font-size:0.85rem; font-style:italic;">Nenhuma ação necessária nesta cena. Aproveite a narração!</p>`;
  }
  
  // Modulação da trilha procedural conforme o clima da cena
  modulateAmbientSynth(scene.visual_type);
  
  // Dispara a narração da cena
  if (scene.narration && scene.narration.trigger_on_load) {
    speakNarrationText(scene.narration.text);
  }
}

// ==========================================================================
// PARSER DE TEXTO DE ORATÓRIA & FILTRO DE VOZ IA
// ==========================================================================
function parseNarrationText(text) {
  // Filtra siglas e adapta vocabulário para oratória
  let talkText = text;
  
  // Substituições rítmicas / contrações comuns para tom mais humano
  talkText = talkText.replace(/\bCEO\b/g, "diretor executivo");
  talkText = talkText.replace(/\bAI\b/g, "inteligência artificial");
  talkText = talkText.replace(/\bVS\b/g, "versus");
  
  // Regex para achar tags de palco: [sussurrando], [pausa 2s], [fada_travessa] etc.
  const tagsRegex = /(\[[a-zA-Z0-9_:\s]+\]|\{\{[a-zA-Z0-9_:\s]+\}\})/g;
  
  const tokens = [];
  let lastIndex = 0;
  let match;
  
  while ((match = tagsRegex.exec(text)) !== null) {
    const rawTag = match[0];
    const matchIndex = match.index;
    
    // Texto antes da tag
    if (matchIndex > lastIndex) {
      const segmentText = text.substring(lastIndex, matchIndex);
      addTextTokens(segmentText, tokens);
    }
    
    // A tag em si
    tokens.push({
      isTag: true,
      raw: rawTag,
      clean: rawTag.replace(/[\[\]\{\}]/g, '').trim()
    });
    
    lastIndex = tagsRegex.lastIndex;
  }
  
  // Texto depois da última tag
  if (lastIndex < text.length) {
    const segmentText = text.substring(lastIndex);
    addTextTokens(segmentText, tokens);
  }
  
  return tokens;
}

function addTextTokens(textSegment, tokensArray) {
  // Trata pontuações estratégicas como comandos de ritmo
  // Separamos o segmento em blocos de palavras, mantendo pontuações
  const parts = textSegment.split(/(\s+)/);
  
  parts.forEach(part => {
    if (part.trim() === '') return;
    
    // Identifica se há pontuações fortes que indicam ritmos
    let pauseTime = 0;
    let pitchMod = 1.0;
    let speedMod = 1.0;
    let isEmphasis = false;
    
    if (part.includes('...')) {
      pauseTime = 500; // 0.5s de suspense
    } else if (part.includes('— pausa —')) {
      pauseTime = 1200; // pausa longa
    } else if (part.includes('—')) {
      pauseTime = 300; // ênfase
      isEmphasis = true;
    } else if (part.includes('?!') || part.includes('!')) {
      pitchMod = 1.15; // pico de energia / agudo
      speedMod = 1.05;
    } else if (part.includes(',')) {
      pauseTime = 150; // respiração natural
    }
    
    tokensArray.push({
      isTag: false,
      word: part,
      pauseBefore: pauseTime,
      pitchModifier: pitchMod,
      speedModifier: speedMod,
      emphasis: isEmphasis
    });
  });
}

// ==========================================================================
// DISPOSITIVO DE LEGENDAS KARAOKE SINCRONIZADAS
// ==========================================================================
function renderKaraokeBoard(tokens) {
  els.karaokeBoard.innerHTML = '';
  let wordIndex = 0;
  
  let currentSpeaker = 'narrator';
  let activeEmotion = 'calmo';
  
  tokens.forEach(token => {
    if (token.isTag) {
      // Tags de controle de voz mudam a classe de falantes
      const tag = token.clean;
      if (['rei_sabio', 'fada_travessa', 'dragao_anciao', 'narrador'].includes(tag)) {
        currentSpeaker = tag;
      }
      if (['sussurrando', 'gritando', 'eco', 'calmo', 'animado', 'misterioso'].includes(tag)) {
        activeEmotion = tag;
      }
      return;
    }
    
    const wordSpan = document.createElement('span');
    wordSpan.className = `spoken-word speaker-${currentSpeaker} ${activeEmotion}`;
    wordSpan.id = `k-word-${wordIndex}`;
    wordSpan.textContent = token.word + ' ';
    
    // Guarda metadados associados à palavra no span
    token.elementId = wordSpan.id;
    token.speaker = currentSpeaker;
    token.emotion = activeEmotion;
    wordIndex++;
    
    els.karaokeBoard.appendChild(wordSpan);
  });
  
  state.wordsMetadata = tokens.filter(t => !t.isTag);
}

// ==========================================================================
// SÍNTESE DE VOZ HYBRIDA & ENGINE SSML
// ==========================================================================
function speakNarrationText(text) {
  stopAllNarration();
  
  if (state.narrationMode === 'texto') {
    // Modo silencioso, apenas legenda dinâmica temporizada simples
    els.speakerName.textContent = 'Somente Texto';
    els.speakerName.className = 'speaker-indicator speaker-narrator';
    
    const tokens = parseNarrationText(text);
    renderKaraokeBoard(tokens);
    simulateSilentSpeech(0);
    return;
  }
  
  const tokens = parseNarrationText(text);
  renderKaraokeBoard(tokens);
  
  if (!window.speechSynthesis) {
    console.error('Navegador não suporta Speech Synthesis API.');
    return;
  }
  
  state.isNarrationPlaying = true;
  els.btnPlayPauseNarration.innerHTML = '<span>⏸️</span> Pausar Narração';
  
  // Vamos compilar as frases baseadas nas vozes de personagens e tags
  // Criamos segmentos de texto com suas configurações
  const speechSegments = [];
  let currentSegmentText = [];
  let activeVoiceSettings = {
    role: 'narrator',
    pitch: 1.0,
    speed: 1.0,
    volume: 1.0,
    emotion: 'normal'
  };
  
  tokens.forEach(tok => {
    if (tok.isTag) {
      const tag = tok.clean;
      
      // Se for uma tag de troca de personagem ou emoção, encerra o segmento anterior e cria um novo
      if (['rei_sabio', 'fada_travessa', 'dragao_anciao', 'narrador', 'sussurrando', 'gritando', 'eco', 'calmo', 'animado', 'suave', 'misterioso'].includes(tag) || tag.startsWith('pausa')) {
        
        if (currentSegmentText.length > 0) {
          speechSegments.push({
            text: currentSegmentText.join(' '),
            settings: { ...activeVoiceSettings }
          });
          currentSegmentText = [];
        }
        
        if (tag === 'rei_sabio') {
          activeVoiceSettings.role = 'rei_sabio';
          activeVoiceSettings.pitch = 0.7; // grave
          activeVoiceSettings.speed = 0.75; // lento
          activeVoiceSettings.volume = 1.0;
        } else if (tag === 'fada_travessa') {
          activeVoiceSettings.role = 'fada_travessa';
          activeVoiceSettings.pitch = 1.35; // agudo
          activeVoiceSettings.speed = 1.2; // rápido
          activeVoiceSettings.volume = 0.95;
        } else if (tag === 'dragao_anciao') {
          activeVoiceSettings.role = 'dragao_anciao';
          activeVoiceSettings.pitch = 0.55; // muito grave
          activeVoiceSettings.speed = 0.65; // muito lento
          activeVoiceSettings.volume = 1.0;
        } else if (tag === 'narrador') {
          activeVoiceSettings.role = 'narrator';
          activeVoiceSettings.pitch = 1.0;
          activeVoiceSettings.speed = 1.0;
          activeVoiceSettings.volume = 1.0;
        }
        
        if (tag === 'sussurrando') {
          activeVoiceSettings.volume = 0.35;
          activeVoiceSettings.speed = 0.8;
          activeVoiceSettings.emotion = 'sussurrando';
        } else if (tag === 'gritando') {
          activeVoiceSettings.volume = 1.0;
          activeVoiceSettings.pitch = 1.2;
          activeVoiceSettings.speed = 1.1;
          activeVoiceSettings.emotion = 'gritando';
        } else if (tag === 'eco') {
          activeVoiceSettings.emotion = 'eco';
        } else if (['calmo', 'animado', 'suave', 'misterioso'].includes(tag)) {
          activeVoiceSettings.emotion = tag;
        }
        
        // Se for uma pausa explícita [pausa 1.5s]
        if (tag.startsWith('pausa')) {
          const pauseSecs = parseFloat(tag.replace(/[^0-9.]/g, '')) || 1.0;
          speechSegments.push({
            isPause: true,
            duration: pauseSecs * 1000
          });
        }
      }
    } else {
      currentSegmentText.push(tok.word);
    }
  });
  
  if (currentSegmentText.length > 0) {
    speechSegments.push({
      text: currentSegmentText.join(' '),
      settings: { ...activeVoiceSettings }
    });
  }
  
  // Agora reproduzimos os segmentos de fala sequencialmente
  playSpeechSegmentsQueue(speechSegments, 0);
}

function playSpeechSegmentsQueue(segments, index) {
  if (index >= segments.length) {
    stopAllNarration();
    // Se for a cena de vitória, dispara a tela final animada depois de um pequeno delay de 0.5s!
    if (state.currentScene && state.currentScene.interactive_prompt && state.currentScene.interactive_prompt.is_victory) {
      setTimeout(() => {
        showStoryEndScreen(state.currentStory);
      }, 800);
    }
    return;
  }
  
  const currentSeg = segments[index];
  
  if (currentSeg.isPause) {
    // Trata pausa real na narração por IA
    clearKaraokeHighlight();
    state.speechTimeout = setTimeout(() => {
      playSpeechSegmentsQueue(segments, index + 1);
    }, currentSeg.duration);
    return;
  }
  
  // Atualiza falante na interface
  updateSpeakerName(currentSeg.settings.role);
  
  const u = new SpeechSynthesisUtterance(currentSeg.text);
  state.currentSpeechUtterance = u;
  
  // Aplica Sliders Globais cumulativamente com os controles do personagem
  u.rate = state.narrationSpeed * currentSeg.settings.speed;
  u.pitch = state.narrationPitch * currentSeg.settings.pitch;
  u.volume = currentSeg.settings.volume;
  
  // Seleciona voz em português se disponível
  const voices = window.speechSynthesis.getVoices();
  const ptVoice = voices.find(v => v.lang.includes('PT') || v.lang.includes('pt'));
  if (ptVoice) {
    u.voice = ptVoice;
  }
  
  // MOCK de Clareza e Estabilidade
  // Estabilidade baixa = ligeiras modulações aleatórias na velocidade e pitch por sentença
  if (state.narrationStability < 0.4) {
    u.pitch += (Math.random() - 0.5) * 0.15;
    u.rate += (Math.random() - 0.5) * 0.1;
  }
  
  // Karaoke Sync - usa boundary event para sincronizar perfeitamente as palavras!
  u.onboundary = (event) => {
    if (event.name === 'word') {
      const charIdx = event.charIndex;
      highlightKaraokeWordByCharIndex(currentSeg.text, charIdx, currentSeg.settings.role);
    }
  };
  
  // Fallback de Sincronia caso o evento boundary falhe no navegador
  let wordsSimulatedCount = 0;
  const wordsArr = currentSeg.text.split(' ');
  const wordDurationAvg = (60000 / (150 * u.rate)); // Estimativa de WPM para duração
  
  u.onstart = () => {
    state.isNarrationPlaying = true;
  };
  
  u.onend = () => {
    playSpeechSegmentsQueue(segments, index + 1);
  };
  
  u.onerror = (e) => {
    console.error('Speech synthesis error, fallback to simulation:', e);
    // Fallback de simulação
    simulateSilentSpeech(0);
  };
  
  window.speechSynthesis.speak(u);
}

function updateSpeakerName(role) {
  let label = 'Narrador';
  let className = 'speaker-indicator speaker-narrator';
  
  if (role === 'rei_sabio') {
    label = '👴🏼 Rei Sábio';
    className = 'speaker-indicator speaker-wise_king';
  } else if (role === 'fada_travessa') {
    label = '🧚‍♀️ Fada Travessa';
    className = 'speaker-indicator speaker-playful_fairy';
  } else if (role === 'dragao_anciao') {
    label = '🐉 Dragão Ancião';
    className = 'speaker-indicator speaker-ancient_dragon';
  }
  
  els.speakerName.textContent = label;
  els.speakerName.className = className;
}

// Algoritmo de mapeamento charIndex -> Palavra correspondente no Karaoke
function highlightKaraokeWordByCharIndex(segmentText, charIndex, role) {
  // Descobre qual palavra do segmento texto foi acionada
  const segmentUpToChar = segmentText.substring(0, charIndex).trim();
  const wordCount = segmentUpToChar ? segmentUpToChar.split(/\s+/).length : 0;
  
  // Mapeia para a lista global de metadados de palavras
  // Apenas as palavras correspondentes ao falante atual na fila
  const segmentWords = state.wordsMetadata.filter(w => w.speaker === role);
  const targetWordToken = segmentWords[wordCount];
  
  if (targetWordToken) {
    clearKaraokeHighlight();
    const wordEl = document.getElementById(targetWordToken.elementId);
    if (wordEl) {
      wordEl.classList.add('active');
      // Adiciona animação de palco específica
      if (targetWordToken.emotion === 'gritando') {
        triggerHapticVisual(); // tremor visual
      }
    }
  }
}

function clearKaraokeHighlight() {
  const words = document.querySelectorAll('.spoken-word');
  words.forEach(w => w.classList.remove('active'));
}

// Simulação de fala para navegadores incompatíveis ou modo Silencioso
function simulateSilentSpeech(wordIdx) {
  if (!state.isNarrationPlaying && state.narrationMode !== 'texto') return;
  if (wordIdx >= state.wordsMetadata.length) {
    stopAllNarration();
    // Se for a cena de vitória, dispara a tela final animada!
    if (state.currentScene && state.currentScene.interactive_prompt && state.currentScene.interactive_prompt.is_victory) {
      setTimeout(() => {
        showStoryEndScreen(state.currentStory);
      }, 800);
    }
    return;
  }
  
  clearKaraokeHighlight();
  const token = state.wordsMetadata[wordIdx];
  const wordEl = document.getElementById(token.elementId);
  if (wordEl) {
    wordEl.classList.add('active');
    updateSpeakerName(token.speaker);
    if (token.emotion === 'gritando') {
      triggerHapticVisual();
    }
  }
  
  // Duração de leitura calculada proporcional à velocidade
  const duration = (250 / state.narrationSpeed) + (token.pauseBefore || 0);
  
  state.speechTimeout = setTimeout(() => {
    simulateSilentSpeech(wordIdx + 1);
  }, duration);
}

function stopAllNarration() {
  state.isNarrationPlaying = false;
  els.btnPlayPauseNarration.innerHTML = '<span>▶️</span> Tocar Narração';
  
  if (window.speechSynthesis) {
    window.speechSynthesis.cancel();
  }
  if (state.speechTimeout) {
    clearTimeout(state.speechTimeout);
    state.speechTimeout = null;
  }
  clearKaraokeHighlight();
}

// Repetir a última narração / 10s da cena atual
function repeatCurrentNarration() {
  if (state.currentScene && state.currentScene.narration) {
    speakNarrationText(state.currentScene.narration.text);
  }
}

// ==========================================================================
// ENGINE DE ÁUDIO WEB AUDIO API (SINTETIZADOR PROCEDURAL DE SFX & MÚSICA)
// ==========================================================================
function playProceduralSound(type) {
  if (!state.audioCtx) return;
  
  // Garante que o contexto está ativo
  if (state.audioCtx.state === 'suspended') {
    state.audioCtx.resume();
  }
  
  const osc1 = state.audioCtx.createOscillator();
  const osc2 = state.audioCtx.createOscillator();
  const gainNode = state.audioCtx.createGain();
  const filter = state.audioCtx.createBiquadFilter();
  
  osc1.connect(gainNode);
  osc2.connect(gainNode);
  gainNode.connect(filter);
  
  // Ajuste do modo Headphone (Mock de áudio espacial)
  if (state.headphoneMode) {
    const panner = state.audioCtx.createStereoPanner();
    panner.pan.value = (Math.random() * 2) - 1; // Panning estéreo aleatório
    filter.connect(panner);
    panner.connect(state.audioCtx.destination);
  } else {
    filter.connect(state.audioCtx.destination);
  }
  
  const now = state.audioCtx.currentTime;
  
  switch(type) {
    case 'whoosh': // Arrastando item
      osc1.type = 'triangle';
      osc1.frequency.setValueAtTime(150, now);
      osc1.frequency.exponentialRampToValueAtTime(450, now + 0.3);
      
      gainNode.gain.setValueAtTime(0.01, now);
      gainNode.gain.linearRampToValueAtTime(0.15, now + 0.15);
      gainNode.gain.exponentialRampToValueAtTime(0.01, now + 0.3);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1000, now);
      
      osc1.start(now);
      osc1.stop(now + 0.3);
      break;
      
    case 'ding': // Encaixe correto
      osc1.type = 'sine';
      osc2.type = 'triangle';
      
      osc1.frequency.setValueAtTime(880, now); // Nota A5
      osc1.frequency.exponentialRampToValueAtTime(1200, now + 0.4);
      
      osc2.frequency.setValueAtTime(440, now);
      
      gainNode.gain.setValueAtTime(0.01, now);
      gainNode.gain.linearRampToValueAtTime(0.2, now + 0.05);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.5);
      
      filter.type = 'highpass';
      filter.frequency.setValueAtTime(300, now);
      
      osc1.start(now);
      osc2.start(now);
      osc1.stop(now + 0.5);
      osc2.stop(now + 0.5);
      break;
      
    case 'boop': // Encaixe errado
      osc1.type = 'sawtooth';
      osc1.frequency.setValueAtTime(180, now);
      osc1.frequency.linearRampToValueAtTime(70, now + 0.35);
      
      gainNode.gain.setValueAtTime(0.2, now);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(400, now);
      
      osc1.start(now);
      osc1.stop(now + 0.4);
      break;
      
    case 'stone': // Efeito de pedra abrindo / rangendo
      osc1.type = 'triangle';
      osc1.frequency.setValueAtTime(80, now);
      osc1.frequency.setValueAtTime(90, now + 0.1);
      osc1.frequency.setValueAtTime(75, now + 0.25);
      
      gainNode.gain.setValueAtTime(0.25, now);
      gainNode.gain.linearRampToValueAtTime(0.25, now + 0.4);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
      
      filter.type = 'peaking';
      filter.frequency.setValueAtTime(120, now);
      
      osc1.start(now);
      osc1.stop(now + 0.6);
      break;
  }
}

// Sintetizador procedural contínuo para trilha sonora
function startAmbientSynth() {
  if (!state.audioCtx) return;
  
  state.musicGain = state.audioCtx.createGain();
  state.musicGain.gain.value = 0.04; // Trilha suave ao fundo
  state.musicGain.connect(state.audioCtx.destination);
  
  // LFO oscilador para simular efeito de harpa ou vento mágico
  const runSynthLoop = () => {
    if (!state.musicGain) return;
    
    const now = state.audioCtx.currentTime;
    const osc = state.audioCtx.createOscillator();
    const subOsc = state.audioCtx.createOscillator();
    const noteGain = state.audioCtx.createGain();
    
    osc.connect(noteGain);
    subOsc.connect(noteGain);
    noteGain.connect(state.musicGain);
    
    osc.type = 'sine';
    subOsc.type = 'triangle';
    
    // Escala pentatônica mágica (C, D, E, G, A) para exploração suave
    const scale = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25];
    const randomNote = scale[Math.floor(Math.random() * scale.length)];
    
    osc.frequency.setValueAtTime(randomNote, now);
    subOsc.frequency.setValueAtTime(randomNote / 2, now);
    
    noteGain.gain.setValueAtTime(0.001, now);
    noteGain.gain.linearRampToValueAtTime(0.2, now + 1.0);
    noteGain.gain.exponentialRampToValueAtTime(0.001, now + 4.0);
    
    osc.start(now);
    subOsc.start(now);
    osc.stop(now + 4.1);
    subOsc.stop(now + 4.1);
    
    // Agenda próxima nota (BPM controlado)
    const bpmDelay = state.currentScene && state.currentScene.visual_type === 'victory' ? 1200 : 2500;
    setTimeout(runSynthLoop, bpmDelay);
  };
  
  runSynthLoop();
}

function modulateAmbientSynth(theme) {
  if (!state.musicGain) return;
  const now = state.audioCtx ? state.audioCtx.currentTime : 0;
  
  if (theme === 'victory') {
    state.musicGain.gain.setValueAtTime(0.07, now); // Mais alto e festivo
  } else if (theme === 'cave') {
    state.musicGain.gain.setValueAtTime(0.03, now); // Silencioso e misterioso
  } else {
    state.musicGain.gain.setValueAtTime(0.04, now); // Normal
  }
}

// Simula a onda do Spectrum visualizador
function simulateWaveform() {
  const bars = els.waveformBars.children;
  if (!bars) return;
  
  for (let i = 0; i < bars.length; i++) {
    const bar = bars[i];
    if (state.isNarrationPlaying) {
      bar.classList.add('active');
      // Oscilação procedural
      const h = Math.floor(Math.random() * 26) + 6;
      bar.style.height = `${h}px`;
    } else {
      bar.classList.remove('active');
      bar.style.height = '8px';
    }
  }
}

// ==========================================================================
// SUPORTE COMPLETO DRAG AND DROP (TOUCH + DESKTOP)
// ==========================================================================
function setupDragItem(itemEl) {
  itemEl.addEventListener('dragstart', (e) => {
    state.draggedElementId = e.target.id;
    e.dataTransfer.setData('text/plain', e.target.id);
    playProceduralSound('whoosh');
    e.target.style.opacity = '0.5';
  });
  
  itemEl.addEventListener('dragend', (e) => {
    e.target.style.opacity = '1';
  });
  
  // Suporte a Touch para Celulares / Mobile Haptics
  itemEl.addEventListener('touchstart', (e) => {
    state.draggedElementId = e.target.id;
    playProceduralSound('whoosh');
    e.target.style.transform = 'scale(1.1)';
  }, { passive: true });
  
  itemEl.addEventListener('touchend', (e) => {
    e.target.style.transform = 'none';
    
    // Lógica para detectar em qual drop zone soltou via touch
    const touch = e.changedTouches[0];
    const elementUnderTouch = document.elementFromPoint(touch.clientX, touch.clientY);
    
    if (elementUnderTouch) {
      const dropZone = elementUnderTouch.closest('.dropzone-element');
      if (dropZone) {
        handleDropAction(state.draggedElementId, dropZone.id);
      }
    }
  });
}

function setupDropZones() {
  const zones = document.querySelectorAll('.dropzone-element');
  zones.forEach(zone => {
    zone.addEventListener('dragover', (e) => {
      e.preventDefault();
      zone.classList.add('active-hover');
    });
    
    zone.addEventListener('dragleave', () => {
      zone.classList.remove('active-hover');
    });
    
    zone.addEventListener('drop', (e) => {
      e.preventDefault();
      zone.classList.remove('active-hover');
      const draggedId = e.dataTransfer.getData('text/plain') || state.draggedElementId;
      handleDropAction(draggedId, zone.id);
    });
  });
}

// Validador lógico do Drop
function handleDropAction(draggedId, dropZoneId) {
  const scene = state.currentScene;
  const prompt = scene.interactive_prompt;
  if (!prompt) return;
  
  const itemEl = document.getElementById(draggedId);
  if (!itemEl) return;
  
  let isCorrect = false;
  
  // Se for o puzzle dos cristais ordenado
  if (prompt.is_ordered_puzzle && prompt.placements) {
    const expectedZone = prompt.placements[draggedId];
    if (expectedZone === dropZoneId) {
      isCorrect = true;
    }
  } 
  // Zonas simples
  else if (prompt.drop_zone === dropZoneId) {
    isCorrect = true;
  }
  
  const zoneEl = document.getElementById(dropZoneId);
  
  if (isCorrect) {
    // Efeito de sucesso no encaixe
    zoneEl.classList.add('correct');
    zoneEl.innerHTML = `<span>✅</span><div style="font-size:0.75rem; color:var(--secondary); font-weight:bold;">Perfeito!</div>`;
    
    // Remove o item da prateleira para evitar reutilização
    itemEl.remove();
    
    playProceduralSound('ding');
    triggerCelebration();
    
    // Executa a narração contextual de sucesso
    speakNarrationText(prompt.success_narration);
    
    // Avança a cena após 4 segundos (dá tempo para a narração de sucesso terminar)
    setTimeout(() => {
      advanceScene();
    }, 4500);
  } else {
    // Feedback de erro
    zoneEl.classList.add('wrong');
    triggerHapticVisual();
    playProceduralSound('boop');
    
    // Executa narração de erro
    speakNarrationText(prompt.fail_narration || "[suave] Tente outro lugar...");
    
    setTimeout(() => {
      zoneEl.classList.remove('wrong');
    }, 800);
  }
}

function advanceScene() {
  if (state.currentScene && state.currentScene.next_scene) {
    const nextId = state.currentScene.next_scene;
    const nextIdx = state.currentStory.scenes.findIndex(s => s.scene_id === nextId);
    if (nextIdx !== -1) {
      state.currentSceneIndex = nextIdx;
      loadScene(state.currentStory.scenes[nextIdx]);
    }
  }
}

// Simulação de Vibração háptica física e visual
function triggerHapticVisual() {
  // Mobile real API
  if (navigator.vibrate) {
    navigator.vibrate([80, 50, 80]);
  }
  
  // Efeito CSS de tremor no Palco
  els.stageCanvas.classList.add('canvas-shake');
  
  // Vibração física do frame do celular simulado!
  if (els.deviceFrameWrapper && els.deviceFrameWrapper.classList.contains('device-frame-active')) {
    els.deviceFrameWrapper.classList.add('device-vibrate');
  }
  
  setTimeout(() => {
    els.stageCanvas.classList.remove('canvas-shake');
    if (els.deviceFrameWrapper) {
      els.deviceFrameWrapper.classList.remove('device-vibrate');
    }
  }, 400);
}

// ==========================================================================
// SISTEMA DE POEIRA MÁGICA / PARTÍCULAS CANVAS 2D
// ==========================================================================
function setupParticleSystem() {
  const canvas = els.particlesOverlay;
  const ctx = canvas.getContext('2d');
  
  let particles = [];
  
  const resize = () => {
    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;
  };
  window.addEventListener('resize', resize);
  resize();
  
  class Star {
    constructor() {
      this.x = Math.random() * canvas.width;
      this.y = Math.random() * canvas.height;
      this.size = Math.random() * 2 + 1;
      this.speed = Math.random() * 0.3 + 0.1;
      this.alpha = Math.random() * 0.5 + 0.3;
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
      ctx.fillStyle = '#FFD700';
      ctx.shadowBlur = 10;
      ctx.shadowColor = '#FFD700';
      ctx.fillRect(this.x, this.y, this.size, this.size);
      ctx.restore();
    }
  }
  
  // Cria poeira mágica ambiente
  for (let i = 0; i < 40; i++) {
    particles.push(new Star());
  }
  
  // Loop de animação
  const animate = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    particles.forEach(p => {
      p.update();
      p.draw();
    });
    requestAnimationFrame(animate);
  };
  animate();
  
  // Função global de comemoração
  window.triggerCelebration = () => {
    // Adiciona centenas de faíscas coloridas explodindo
    for (let i = 0; i < 80; i++) {
      const p = new Star();
      p.x = canvas.width / 2 + (Math.random() - 0.5) * 100;
      p.y = canvas.height / 2 + (Math.random() - 0.5) * 100;
      p.speed = Math.random() * 3 + 1.5;
      p.size = Math.random() * 4 + 2;
      p.alpha = 1.0;
      // Direções aleatórias
      const angle = Math.random() * Math.PI * 2;
      const speedX = Math.cos(angle) * p.speed;
      const speedY = Math.sin(angle) * p.speed;
      
      p.update = function() {
        this.x += speedX;
        this.y += speedY;
        this.alpha -= 0.015;
        if (this.alpha <= 0) {
          this.alpha = 0;
        }
      };
      
      particles.push(p);
    }
  };
}

// ==========================================================================
// CONFIGURAÇÃO DOS SLIDERS & CONFIGURAÇÕES DA VOZ IA
// ==========================================================================
function setupSliders() {
  // Stability
  els.stabilitySlider.addEventListener('input', (e) => {
    state.narrationStability = parseFloat(e.target.value);
    els.stabilityVal.textContent = state.narrationStability.toFixed(2);
  });
  // Clarity
  els.claritySlider.addEventListener('input', (e) => {
    state.narrationClarity = parseFloat(e.target.value);
    els.clarityVal.textContent = state.narrationClarity.toFixed(2);
  });
  // Speed
  els.speedSlider.addEventListener('input', (e) => {
    state.narrationSpeed = parseFloat(e.target.value);
    els.speedVal.textContent = `${state.narrationSpeed.toFixed(1)}x`;
  });
  // Pitch
  els.pitchSlider.addEventListener('input', (e) => {
    state.narrationPitch = parseFloat(e.target.value);
    els.pitchVal.textContent = state.narrationPitch.toFixed(1);
  });
}

function setupModes() {
  const buttons = [els.modeTeatral, els.modeGuiado, els.modeDinamico, els.modeTexto];
  
  const setMode = (activeBtn, modeStr) => {
    buttons.forEach(btn => btn.classList.remove('active'));
    activeBtn.classList.add('active');
    state.narrationMode = modeStr;
    
    // Aplica ajustes de preset dependendo do modo
    if (modeStr === 'guiado') {
      state.narrationSpeed = 0.8;
      state.narrationPitch = 1.0;
      els.speedSlider.value = 0.8;
      els.speedVal.textContent = '0.8x';
    } else if (modeStr === 'dinamico') {
      state.narrationSpeed = 1.25;
      state.narrationPitch = 1.0;
      els.speedSlider.value = 1.25;
      els.speedVal.textContent = '1.3x';
    } else {
      state.narrationSpeed = 1.0;
      els.speedSlider.value = 1.0;
      els.speedVal.textContent = '1.0x';
    }
    
    // Recomeça narração para aplicar novas regras
    if (state.currentScene) {
      loadScene(state.currentScene);
    }
  };
  
  els.modeTeatral.addEventListener('click', () => setMode(els.modeTeatral, 'teatral'));
  els.modeGuiado.addEventListener('click', () => setMode(els.modeGuiado, 'guiado'));
  els.modeDinamico.addEventListener('click', () => setMode(els.modeDinamico, 'dinamico'));
  els.modeTexto.addEventListener('click', () => setMode(els.modeTexto, 'texto'));
}

function setupAccessibility() {
  // Repetir cláusula
  els.btnRepeatPhrase.addEventListener('click', () => {
    repeatCurrentNarration();
  });
  
  // Headphone mode / spatial audio simulation
  els.btnHeadphoneMode.addEventListener('click', () => {
    state.headphoneMode = !state.headphoneMode;
    els.btnHeadphoneMode.classList.toggle('active', state.headphoneMode);
    
    // Notifica visualmente ativação
    if (state.headphoneMode) {
      speakNarrationText("[suave] Modo fone de ouvido ativado. Áudio 3D ativado.");
    }
  });
  
  // Cores de personagens no karaoke
  els.btnCharacterColors.addEventListener('click', () => {
    state.characterColors = !state.characterColors;
    els.btnCharacterColors.classList.toggle('active', state.characterColors);
    els.karaokeBoard.classList.toggle('no-colors', !state.characterColors);
  });
  
  // Tocar/Pausar
  els.btnPlayPauseNarration.addEventListener('click', () => {
    if (state.isNarrationPlaying) {
      stopAllNarration();
    } else {
      if (state.currentScene && state.currentScene.narration) {
        speakNarrationText(state.currentScene.narration.text);
      }
    }
  });

  // Alternador do Modo Celular
  if (els.btnToggleDevice) {
    els.btnToggleDevice.addEventListener('click', () => {
      const isActive = els.deviceFrameWrapper.classList.toggle('device-frame-active');
      els.deviceFrameWrapper.classList.toggle('device-frame-desktop-full', !isActive);
      
      if (isActive) {
        els.deviceFrameWrapper.classList.add('device-portrait');
        els.deviceFrameWrapper.classList.remove('device-landscape');
        els.btnToggleDevice.innerHTML = '🖥️ Vista Cheia';
        els.btnRotateDevice.classList.remove('hidden');
      } else {
        els.deviceFrameWrapper.classList.remove('device-portrait', 'device-landscape');
        els.btnToggleDevice.innerHTML = '📱 Simulador';
        els.btnRotateDevice.classList.add('hidden');
      }
      
      // Ajusta as dimensões do canvas de poeira cósmica
      window.dispatchEvent(new Event('resize'));
    });
  }
  
  // Rotacionar Celular (Paisagem/Retrato)
  if (els.btnRotateDevice) {
    els.btnRotateDevice.addEventListener('click', () => {
      if (els.deviceFrameWrapper.classList.contains('device-frame-active')) {
        const isPortrait = els.deviceFrameWrapper.classList.toggle('device-portrait');
        els.deviceFrameWrapper.classList.toggle('device-landscape', !isPortrait);
        
        // Ajusta as dimensões do canvas após a rotação CSS concluir
        setTimeout(() => {
          window.dispatchEvent(new Event('resize'));
        }, 150);
      }
    });
  }

  // Retornar ao Menu Principal/Lobby
  if (els.btnHomeLobby) {
    els.btnHomeLobby.addEventListener('click', () => {
      showMainLobby();
    });
  }
}

// ==========================================================================
// VISUAL STORY EDITOR (CRIADOR DE CENAS PERSONALIZADAS)
// ==========================================================================
let customSceneBuilder = {
  scenes: []
};

function setupEditorForm() {
  els.addSceneBtn.addEventListener('click', () => {
    const title = els.editorSceneTitle.value.trim();
    const id = els.editorSceneId.value.trim();
    const theme = els.editorVisualTheme.value;
    const narration = els.editorNarrationText.value.trim();
    const dragItemType = els.editorDragItemSelect.value;
    const prompt = els.editorPromptText.value.trim();
    const success = els.editorSuccessText.value.trim();
    
    if (!title || !id || !narration || !prompt || !success) {
      alert('Por favor, preencha todos os campos obrigatórios para criar a cena!');
      return;
    }
    
    // Cria o objeto da cena com base no formulário
    const newScene = {
      scene_id: id,
      title: title,
      visual_type: theme,
      drag_elements: getDragItemMetadata(dragItemType),
      narration: {
        text: narration,
        emotion: "mysterious_warm",
        background_music: "adventure_theme",
        trigger_on_load: true
      },
      interactive_prompt: {
        instruction: prompt,
        voice_hint: prompt,
        drop_zone: dragItemType === 'backpack' ? 'backpack_ui' : (dragItemType === 'crown' ? 'wise_king' : 'pedestal_1'),
        success_narration: success,
        fail_narration: "[suave] Tente novamente..."
      }
    };
    
    // Adiciona lógica de transição automática
    if (customSceneBuilder.scenes.length > 0) {
      // O anterior aponta para este
      customSceneBuilder.scenes[customSceneBuilder.scenes.length - 1].next_scene = id;
    }
    
    customSceneBuilder.scenes.push(newScene);
    renderCustomScenesList();
    
    // Limpa campos específicos da cena
    els.editorSceneId.value = '';
    els.editorSceneTitle.value = '';
    els.editorNarrationText.value = '';
    els.editorPromptText.value = '';
    els.editorSuccessText.value = '';
    
    // Salva automaticamente a história no localStorage
    saveCustomStoryToLocal();
  });
  
  els.exportJsonBtn.addEventListener('click', () => {
    if (customSceneBuilder.scenes.length === 0) {
      alert('Adicione pelo menos uma cena antes de exportar a história!');
      return;
    }
    
    const storyId = `custom_story_${Date.now()}`;
    const fullStory = {
      story_id: storyId,
      title: els.editorStoryTitle.value.trim() || "Minha História Customizada",
      target_age: "Livre",
      voice_settings: {
        narrator_role: "ia_personalizada",
        base_stability: 0.5,
        base_clarity: 0.7,
        default_speed: 1.0
      },
      scenes: customSceneBuilder.scenes
    };
    
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(fullStory, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", `${storyId}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  });
}

function getDragItemMetadata(type) {
  if (type === 'backpack') {
    return [{"id": "backpack_custom", "type": "mochila", "label": "🎒 Mochila Custom", "description": "Seu inventário de criação."}];
  } else if (type === 'crown') {
    return [{"id": "crown_custom", "type": "coroa", "label": "👑 Coroa de Ouro", "description": "Brilha como o sol da realeza."}];
  } else {
    const color = type.split('_')[1];
    return [{"id": `crystal_${color}_custom`, "type": "cristal", "color": color, "label": `💎 Cristal ${color.toUpperCase()}`, "description": "Vibra com energias puras."}];
  }
}

function renderCustomScenesList() {
  els.customScenesList.innerHTML = '';
  
  if (customSceneBuilder.scenes.length === 0) {
    els.customScenesList.innerHTML = `
      <p class="text-muted" style="font-size:0.85rem; font-style:italic;">
        Nenhuma cena customizada criada ainda. Complete o formulário para criar a primeira!
      </p>
    `;
    return;
  }
  
  customSceneBuilder.scenes.forEach((sc, idx) => {
    const scCard = document.createElement('div');
    scCard.className = 'editor-scene-card';
    scCard.innerHTML = `
      <div class="editor-scene-info">
        <h4>${idx + 1}. ${sc.title}</h4>
        <p>ID: ${sc.scene_id} | Tema: ${sc.visual_type}</p>
      </div>
      <div class="editor-scene-actions">
        <button class="btn-small" onclick="testCustomScene(${idx})">▶️ Testar</button>
        <button class="btn-small btn-danger" onclick="removeCustomScene(${idx})">🗑️</button>
      </div>
    `;
    els.customScenesList.appendChild(scCard);
  });
}

window.testCustomScene = (index) => {
  const activeScene = customSceneBuilder.scenes[index];
  if (activeScene) {
    // Cria uma história mock de teste rápido
    const mockStory = {
      title: els.editorStoryTitle.value.trim() || "História de Teste",
      target_age: "Livre",
      scenes: [activeScene]
    };
    playStory(mockStory);
    speakNarrationText(activeScene.narration.text);
  }
};

window.removeCustomScene = (index) => {
  customSceneBuilder.scenes.splice(index, 1);
  
  // Reordena os ponteiros next_scene
  for (let i = 0; i < customSceneBuilder.scenes.length; i++) {
    if (i < customSceneBuilder.scenes.length - 1) {
      customSceneBuilder.scenes[i].next_scene = customSceneBuilder.scenes[i+1].scene_id;
    } else {
      delete customSceneBuilder.scenes[i].next_scene;
    }
  }
  
  renderCustomScenesList();
  saveCustomStoryToLocal();
};

function saveCustomStoryToLocal() {
  if (customSceneBuilder.scenes.length === 0) {
    return;
  }
  
  const storyId = "custom_story_local";
  const customStory = {
    story_id: storyId,
    title: els.editorStoryTitle.value.trim() || "Minha Aventura Mágica",
    target_age: "Livre",
    scenes: customSceneBuilder.scenes
  };
  
  // Filtra as antigas e adiciona esta
  const otherStories = state.customStories.filter(s => s.story_id !== storyId);
  state.customStories = [...otherStories, customStory];
  
  localStorage.setItem('reino_historias_custom', JSON.stringify(state.customStories));
  
  // Atualiza as histórias em tempo de execução
  const indexInStories = state.stories.findIndex(s => s.story_id === storyId);
  if (indexInStories !== -1) {
    state.stories[indexInStories] = customStory;
  } else {
    state.stories.push(customStory);
  }
  
  setupStorySelector();
}

// Drag and drop Touch API helpers
function setupDragAndDropSupport() {
  // Previne comportamentos padrão do scroll ao arrastar itens no touch
  document.body.addEventListener('touchmove', (e) => {
    if (state.draggedElementId) {
      const item = document.getElementById(state.draggedElementId);
      if (item) {
        e.preventDefault();
        
        // Move o item flutuando com o dedo do usuário
        const touch = e.touches[0];
        item.style.position = 'fixed';
        item.style.left = `${touch.clientX - 50}px`;
        item.style.top = `${touch.clientY - 20}px`;
        item.style.zIndex = '1000';
      }
    }
  }, { passive: false });
  
  document.body.addEventListener('touchend', (e) => {
    if (state.draggedElementId) {
      const item = document.getElementById(state.draggedElementId);
      if (item) {
        item.style.position = '';
        item.style.left = '';
        item.style.top = '';
        item.style.zIndex = '';
      }
      state.draggedElementId = null;
    }
  });
}

// ==========================================================================
// TELA DO PORTAL / LOBBY (MENU PRINCIPAL DO REINO)
// ==========================================================================
function showMainLobby() {
  state.currentStory = null;
  state.currentScene = null;
  state.currentSceneIndex = 0;
  
  stopAllNarration();
  if (endScreenTimeout) clearTimeout(endScreenTimeout);
  
  // Atualiza cabeçalho e progresso
  els.currentSceneTitle.textContent = "Castelo do Reino das Histórias";
  els.storyProgressFill.style.width = "0%";
  
  // Visual de Fundo do Lobby
  els.stageCanvas.className = "stage-canvas scene-lobby";
  
  // Limpa tudo
  els.activeZonesContainer.innerHTML = "";
  els.scenicActorsContainer.innerHTML = "";
  els.dragShelf.innerHTML = "";
  
  // Nome do falante e karaoke limpos
  els.speakerName.textContent = "Castelo";
  els.speakerName.className = "speaker-indicator speaker-narrator";
  els.karaokeBoard.innerHTML = '<span class="text-muted" style="font-size:1.1rem; font-style:italic;">Selecione um dos livros mágicos acima para iniciar sua jornada interativa!</span>';
  
  // Cria container do Lobby
  const lobbyDiv = document.createElement('div');
  lobbyDiv.className = 'lobby-container';
  
  let cardsHtml = '';
  state.stories.forEach((st, idx) => {
    cardsHtml += `
      <div class="lobby-card" onclick="selectStoryFromLobby(${idx})">
        <span class="lobby-card-book">📖</span>
        <h3 class="lobby-card-title">${st.title}</h3>
        <span class="lobby-card-age">🎯 ${st.target_age}</span>
        <button class="lobby-card-btn">📖 Iniciar Jornada</button>
      </div>
    `;
  });
  
  lobbyDiv.innerHTML = `
    <h2 class="lobby-header-title">🏰 Reino das Histórias</h2>
    <p class="lobby-header-sub">Escolha uma jornada mágica interativa para começar:</p>
    <div class="lobby-cards-grid">
      ${cardsHtml}
    </div>
  `;
  
  els.activeZonesContainer.appendChild(lobbyDiv);
  
  els.dragShelf.innerHTML = `
    <div style="text-align:center; padding:10px; width:100%; color:var(--text-muted); font-size:0.9rem;">
      ✨ Dica: Você também pode usar o seletor rápido no topo para trocar de história a qualquer momento!
    </div>
  `;
  
  // Modula som ambiente suave
  modulateAmbientSynth('cave');
}

// Handler global para cliques nos cards do lobby
window.selectStoryFromLobby = (index) => {
  const story = state.stories[index];
  if (story) {
    els.storySelector.value = index;
    playStory(story);
  }
};

let endScreenTimeout = null;

// ==========================================================================
// TELA FINAL ANIMADA (FIM DE HISTÓRIA)
// ==========================================================================
function showStoryEndScreen(story) {
  stopAllNarration();
  if (endScreenTimeout) clearTimeout(endScreenTimeout);
  
  // Trilha triunfal (procedural)
  playProceduralSound('ding');
  setTimeout(() => playProceduralSound('ding'), 200);
  setTimeout(() => playProceduralSound('stone'), 400);
  
  // Visual de vitória
  els.stageCanvas.className = "stage-canvas scene-victory";
  
  els.activeZonesContainer.innerHTML = "";
  els.scenicActorsContainer.innerHTML = "";
  els.dragShelf.innerHTML = "";
  
  els.speakerName.textContent = "Fim da Jornada";
  els.speakerName.className = "speaker-indicator speaker-wise_king";
  els.karaokeBoard.innerHTML = '<span class="text-cream" style="font-size:1.2rem; font-weight:bold; animation:pulse 1s infinite alternate;">Parabéns! Sua coragem e inteligência salvaram o Reino das Histórias!</span>';
  
  // Efeito de confete explosivo de estrelas!
  triggerCelebration();
  setTimeout(triggerCelebration, 800);
  setTimeout(triggerCelebration, 1600);
  
  const endCard = document.createElement('div');
  endCard.className = 'story-end-screen-card';
  
  let countdownSecs = 10;
  
  endCard.innerHTML = `
    <div class="end-scroll-box">
      <span class="end-crown">👑</span>
      <h2 class="end-title">FIM DA AVENTURA</h2>
      <p class="end-subtitle">Você completou com sucesso:</p>
      <h3 class="end-story-name">"${story.title}"</h3>
      <div class="end-badge">✨ Mestre dos Enigmas ✨</div>
      
      <div class="end-actions-row">
        <button class="btn-primary" onclick="restartActiveStoryFromEnd()" style="padding:10px 20px; font-size:0.9rem; flex:1; margin:0;">
          🔄 Jogar Novamente
        </button>
        <button class="btn-icon-text" onclick="showMainLobby()" style="padding:10px 20px; font-size:0.9rem; flex:1; background:rgba(255,255,255,0.08); margin:0;">
          🏰 Voltar ao Reino
        </button>
      </div>
      
      <p id="end-countdown" class="end-timer">Voltando ao Reino em ${countdownSecs}s...</p>
    </div>
  `;
  
  els.activeZonesContainer.appendChild(endCard);
  
  // Registra as funções auxiliares globais
  window.restartActiveStoryFromEnd = () => {
    if (endScreenTimeout) clearTimeout(endScreenTimeout);
    playStory(story);
  };
  
  const runCountdown = () => {
    countdownSecs--;
    const timerEl = document.getElementById('end-countdown');
    if (timerEl) {
      timerEl.textContent = `Voltando ao Reino em ${countdownSecs}s...`;
    }
    
    if (countdownSecs <= 0) {
      showMainLobby();
    } else {
      endScreenTimeout = setTimeout(runCountdown, 1000);
    }
  };
  
  endScreenTimeout = setTimeout(runCountdown, 1000);
}

