import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/reading_game/data/avatar_data.dart';
import 'gamification_service.dart';

/// Serviço de personalização do avatar.
/// Persiste: estilo equipado, chapéu, roupa, pet, efeito, e itens comprados.
class AvatarService extends ChangeNotifier {
  final SharedPreferences _prefs;

  static const _keyStyle    = 'av_style';
  static const _keyHat      = 'av_hat';
  static const _keyClothes  = 'av_clothes';
  static const _keyPet      = 'av_pet';
  static const _keyEffect   = 'av_effect';
  static const _keyPurchased = 'av_purchased';

  // Equipped item IDs per category (null = nenhum / padrão)
  String? _equippedStyle;
  String? _equippedHat;
  String? _equippedClothes;
  String? _equippedPet;
  String? _equippedEffect;

  // Itens comprados com moedas
  Set<String> _purchased = {};

  AvatarService(this._prefs) {
    _load();
  }

  // ── Getters ─────────────────────────────────────────────────────────────
  String? get equippedStyle   => _equippedStyle;
  String? get equippedHat     => _equippedHat;
  String? get equippedClothes => _equippedClothes;
  String? get equippedPet     => _equippedPet;
  String? get equippedEffect  => _equippedEffect;
  Set<String> get purchased   => Set.unmodifiable(_purchased);

  // Retorna o AvatarItem equipado para cada categoria
  AvatarItem? get activeStyle   => getAvatarItemById(_equippedStyle   ?? 'style_default');
  AvatarItem? get activeHat     => _equippedHat     != null ? getAvatarItemById(_equippedHat!)     : null;
  AvatarItem? get activeClothes => getAvatarItemById(_equippedClothes ?? 'clothes_default');
  AvatarItem? get activePet     => _equippedPet     != null ? getAvatarItemById(_equippedPet!)     : null;
  AvatarItem? get activeEffect  => _equippedEffect  != null ? getAvatarItemById(_equippedEffect!)  : null;

  // ── Estado de cada item ──────────────────────────────────────────────────

  /// Item disponível para uso (desbloqueado por badge ou comprado, ou sempre livre)
  bool isUnlocked(AvatarItem item, Set<String> earnedBadgeIds) {
    if (item.startsUnlocked) return true;
    if (item.id == 'hat_none' || item.id == 'pet_none' || item.id == 'effect_none') {
      return true;
    }
    // Item gratuito por badge
    if (item.cost == 0 && item.badge != null) {
      return earnedBadgeIds.contains(item.badge!.name);
    }
    // Item gratuito sem condição
    if (item.cost == 0 && item.badge == null) return true;
    // Item pago: verifica se comprou
    return _purchased.contains(item.id);
  }

  /// Item pode ser comprado agora (tem badge se exigido, mas ainda não comprou)
  bool isPurchasable(AvatarItem item, Set<String> earnedBadgeIds) {
    if (item.cost == 0) return false;
    if (_purchased.contains(item.id)) return false;
    if (item.badge != null && !earnedBadgeIds.contains(item.badge!.name)) return false;
    return true;
  }

  bool isEquipped(String id) =>
      id == _equippedStyle ||
      id == _equippedHat ||
      id == _equippedClothes ||
      id == _equippedPet ||
      id == _equippedEffect;

  // ── Equipar / Desequipar ─────────────────────────────────────────────────

  void equip(AvatarItem item) {
    // Itens "none" = desequipa a categoria
    switch (item.category) {
      case AvatarCategory.style:
        _equippedStyle = item.id;
      case AvatarCategory.hat:
        _equippedHat = (item.id == 'hat_none') ? null : item.id;
      case AvatarCategory.clothes:
        _equippedClothes = (item.id == 'clothes_default') ? null : item.id;
      case AvatarCategory.pet:
        _equippedPet = (item.id == 'pet_none') ? null : item.id;
      case AvatarCategory.effect:
        _equippedEffect = (item.id == 'effect_none') ? null : item.id;
    }
    _save();
    notifyListeners();
  }

  void unequip(AvatarCategory category) {
    switch (category) {
      case AvatarCategory.style:
        _equippedStyle = null;
      case AvatarCategory.hat:
        _equippedHat = null;
      case AvatarCategory.clothes:
        _equippedClothes = null;
      case AvatarCategory.pet:
        _equippedPet = null;
      case AvatarCategory.effect:
        _equippedEffect = null;
    }
    _save();
    notifyListeners();
  }

  void resetAvatar() {
    _equippedStyle   = null;
    _equippedHat     = null;
    _equippedClothes = null;
    _equippedPet     = null;
    _equippedEffect  = null;
    _save();
    notifyListeners();
  }

  // ── Comprar item com moedas ──────────────────────────────────────────────

  /// Retorna true se a compra foi concluída, false se não há moedas suficientes.
  Future<bool> purchase(AvatarItem item, GamificationService gam) async {
    if (_purchased.contains(item.id)) return true; // já possui
    if (gam.state.coins < item.cost) return false;
    final ok = await gam.spendCoins(item.cost);
    if (!ok) return false;
    _purchased.add(item.id);
    _save();
    notifyListeners();
    return true;
  }

  // ── Persistência ─────────────────────────────────────────────────────────

  void _load() {
    _equippedStyle   = _prefs.getString(_keyStyle);
    _equippedHat     = _prefs.getString(_keyHat);
    _equippedClothes = _prefs.getString(_keyClothes);
    _equippedPet     = _prefs.getString(_keyPet);
    _equippedEffect  = _prefs.getString(_keyEffect);

    final raw = _prefs.getString(_keyPurchased);
    if (raw != null) {
      _purchased = Set<String>.from(jsonDecode(raw) as List);
    }
  }

  void _save() {
    if (_equippedStyle != null) {
      _prefs.setString(_keyStyle, _equippedStyle!);
    } else {
      _prefs.remove(_keyStyle);
    }
    if (_equippedHat != null) {
      _prefs.setString(_keyHat, _equippedHat!);
    } else {
      _prefs.remove(_keyHat);
    }
    if (_equippedClothes != null) {
      _prefs.setString(_keyClothes, _equippedClothes!);
    } else {
      _prefs.remove(_keyClothes);
    }
    if (_equippedPet != null) {
      _prefs.setString(_keyPet, _equippedPet!);
    } else {
      _prefs.remove(_keyPet);
    }
    if (_equippedEffect != null) {
      _prefs.setString(_keyEffect, _equippedEffect!);
    } else {
      _prefs.remove(_keyEffect);
    }
    _prefs.setString(_keyPurchased, jsonEncode(_purchased.toList()));
  }
}
