import '../../../services/progress_service.dart';

/// Política central de bloqueio de fases/distritos.
///
/// Antes existia um `// TODO: restaurar lock sequencial para produção`
/// espalhado em 6 telas de mapa, que deixava TUDO liberado para teste.
/// Esta classe centraliza a regra para que não volte a "vazar" liberado.
///
/// Para destravar tudo durante o desenvolvimento, basta ligar [kUnlockAll]
/// num único lugar — NUNCA publicar com ele em `true`.
const bool kUnlockAll = false;

/// Decide se uma fase (ainda NÃO concluída) de um mapa deve ficar liberada.
///
/// Regra de bloqueio sequencial usada por todas as telas de mapa de fases
/// (vogais, sílabas, famílias, palavras, construção). Uma fase abre quando:
///   • a fase anterior já foi concluída ([prevCompleted]); ou
///   • ela já tem algum progresso salvo ([hasProgress]) — defensivo, para nunca
///     re-bloquear algo que a criança já começou; ou
///   • o modo de testes [kUnlockAll] está ligado.
///
/// A primeira fase de cada mapa é tratada passando `prevCompleted: true`.
bool isLevelUnlocked({
  required bool prevCompleted,
  bool hasProgress = false,
}) =>
    kUnlockAll || prevCompleted || hasProgress;

/// Conclusão de cada distrito do mapa principal (Praça Central).
///
/// Só consideramos distritos cujo progresso é rastreável por família
/// (vogais → círculo). Os distritos avançados (aventura, dígrafos,
/// encontros, portal) ainda não têm rastreamento de conclusão próprio,
/// então o mapa os trata à parte (ver `_stateOf` em praca_central).
class DistrictCompletion {
  const DistrictCompletion._();

  /// Maior índice de distrito com conclusão rastreável (0..5 = vogais..circo).
  static const int lastTrackedIndex = 5;

  static bool isComplete(String id, ProgressService p) {
    bool fam(String key, int total) =>
        p.getFamilyProgress(key, total).isCompleted;
    switch (id) {
      case 'vogais':
        return const ['A', 'E', 'I', 'O', 'U'].every((v) => fam('vogal_$v', 3));
      case 'silabas':
        return const ['B', 'C', 'D', 'F', 'M']
            .every((c) => fam('consonant_$c', 5));
      case 'familias':
        return const ['J', 'L', 'M', 'N'].every((c) => fam('consonant_$c', 5));
      case 'palavras':
        return const ['P', 'R', 'S', 'T', 'V']
            .every((c) => fam('consonant_$c', 5));
      case 'construcao':
        return const ['G', 'X', 'Z'].every((c) => fam('consonant_$c', 5));
      case 'circo':
        return fam('circo_rimas', 5) && fam('circo_danca', 4);
      default:
        return false;
    }
  }
}
