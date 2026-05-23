/**
 * audioManifest.js
 * -----------------------------------------------------------------------------
 * Manifesto gerado por tools/tts/wire_audio_manifest.py.
 *
 * IMPORTANTE:
 *   - Metro resolve require() em build-time. Não dá pra checar existência de
 *     arquivo em runtime. Por isso este arquivo é REGENERADO sempre que novos
 *     .wav forem sintetizados — para incluir apenas referências válidas.
 *   - Edite à mão APENAS se souber o que está fazendo. O script sobrescreve.
 *
 * Para regenerar (depois de rodar azure_synthesize.py --bank):
 *     python tools\tts\wire_audio_manifest.py
 *
 * Estado inicial: vazio. Phases 1 e 3 funcionam em modo silencioso até o
 * primeiro `wire_audio_manifest.py` rodar.
 * -----------------------------------------------------------------------------
 */

export const AUDIO_MANIFEST = {
  // Gerado automaticamente. Não edite à mão.
};

export default AUDIO_MANIFEST;
