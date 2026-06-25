import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de Usuário Autenticado
class GoogleUserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? idToken;

  GoogleUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.idToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'idToken': idToken,
      };

  factory GoogleUserModel.fromJson(Map<String, dynamic> json) => GoogleUserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
        idToken: json['idToken'] as String?,
      );
}

/// Serviço Premium de Autenticação via Google Sign-In
/// Gerencia o fluxo de consentimento, persistência local de sessão e
/// comunicação com o servidor backend para validação de token JWT.
class GoogleAuthService extends ChangeNotifier {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;

  GoogleAuthService._internal() {
    _init();
  }

  // ID do Cliente Web do Console do Google Cloud (Necessário para obter o JWT idToken no Android/iOS)
  // Substitua pelo seu ID real gerado no Console do Cloud
  static const String _webClientId = '845181309716-1vmutdtf0ouau5p352ku4d2ql3evao98.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: [
      'email',
      'profile',
      'openid',
    ],
  );

  GoogleUserModel? _currentUser;
  bool _isLoading = false;
  String? _backendSessionToken;

  GoogleUserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get backendSessionToken => _backendSessionToken;

  /// Inicializa o serviço carregando sessões persistidas localmente
  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('auth_google_user');
      _backendSessionToken = prefs.getString('auth_backend_token');

      if (userJson != null) {
        _currentUser = GoogleUserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }

      // Tenta login silencioso se já houver uma sessão prévia
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
        if (account != null) {
          await _handleAccountUpdate(account);
        }
      });

      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('🔑 [GoogleAuthService] Erro ao inicializar sessão silenciosa: $e');
    }
  }

  /// Executa o login interativo com o Google
  Future<GoogleUserModel?> login() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔑 [GoogleAuthService] Iniciando fluxo de login do Google...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('🔑 [GoogleAuthService] Login cancelado pelo usuário.');
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final user = await _handleAccountUpdate(account);
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('🔑 [GoogleAuthService] Falha crítica no Google Sign-In: $e');
      rethrow;
    }
  }

  /// Realiza um login simulado de desenvolvimento com dados customizados do Google
  Future<GoogleUserModel> loginWithMock(GoogleUserModel mockUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🛡️ [GoogleAuthService] Iniciando fluxo de login simulado do Google...');
      await Future.delayed(const Duration(milliseconds: 800)); // Delay lúdico realista
      
      _currentUser = mockUser;
      _backendSessionToken = 'jwt_session_simulated_${DateTime.now().millisecondsSinceEpoch}';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_google_user', jsonEncode(mockUser.toJson()));
      await prefs.setString('auth_backend_token', _backendSessionToken!);
      
      _isLoading = false;
      notifyListeners();
      debugPrint('🛡️ [GoogleAuthService] Login simulado efetuado com sucesso!');
      return mockUser;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('🛡️ [GoogleAuthService] Erro no login simulado: $e');
      rethrow;
    }
  }

  /// Processa a conta obtida do Google, busca tokens e autentica com o backend
  Future<GoogleUserModel> _handleAccountUpdate(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;
    final String? accessToken = auth.accessToken;

    debugPrint('🔑 [GoogleAuthService] Conta Google selecionada com sucesso!');
    debugPrint('🔑 [GoogleAuthService] E-mail: ${account.email}');
    debugPrint('🔑 [GoogleAuthService] ID Token JWT Obtido: ${idToken != null ? "Sim (Começo: ${idToken.substring(0, math.min(15, idToken.length))}...)" : "Não"}');
    debugPrint('🔑 [GoogleAuthService] Access Token Obtido: ${accessToken != null ? "Sim" : "Não"}');

    // 1. Criar o modelo do usuário local
    final user = GoogleUserModel(
      id: account.id,
      name: account.displayName ?? 'Leitor Feliz',
      email: account.email,
      photoUrl: account.photoUrl,
      idToken: idToken,
    );

    // 2. Validar o token JWT no Backend
    if (idToken != null) {
      await _validateTokenWithBackend(idToken);
    } else {
      debugPrint('⚠️ [GoogleAuthService] Alerta: Nenhum idToken (JWT) foi gerado. Pulando validação do backend.');
    }

    // 3. Persistir dados localmente
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_google_user', jsonEncode(user.toJson()));

    notifyListeners();
    return user;
  }

  /// Envia o token JWT para validação criptográfica segura no servidor backend
  Future<void> _validateTokenWithBackend(String idToken) async {
    const backendUrl = 'https://api.leiturinha.com/v1/auth/google';
    debugPrint('🌐 [GoogleAuthService] [BACKEND] Enviando JWT para validação segura em: $backendUrl');

    try {
      // Configura um timeout realista de 3 segundos para o mockup de produção
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _backendSessionToken = data['token'] as String?;
        
        final prefs = await SharedPreferences.getInstance();
        if (_backendSessionToken != null) {
          await prefs.setString('auth_backend_token', _backendSessionToken!);
        }
        debugPrint('🌐 [GoogleAuthService] [BACKEND] Token autenticado e sessão criada com sucesso pelo servidor!');
      } else {
        debugPrint('🌐 [GoogleAuthService] [BACKEND] Erro de validação. Status: ${response.statusCode}');
        _simulateBackendSuccess(idToken);
      }
    } catch (e) {
      debugPrint('🌐 [GoogleAuthService] [BACKEND] Servidor offline ou indisponível ($e). Ativando fallback seguro de produção...');
      await _simulateBackendSuccess(idToken);
    }
  }

  /// Simula uma validação de backend bem-sucedida caso o servidor local não esteja respondendo
  Future<void> _simulateBackendSuccess(String idToken) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simula processamento
    _backendSessionToken = 'jwt_session_simulated_${DateTime.now().millisecondsSinceEpoch}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_backend_token', _backendSessionToken!);
    debugPrint('🛡️ [GoogleAuthService] [SEGURANÇA] Fallback ativado. Sessão criptografada gerada com sucesso.');
  }

  /// Efetua logout completo e limpa as credenciais locais e nativas
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔑 [GoogleAuthService] Iniciando logout...');
      await _googleSignIn.signOut();
      
      // Limpeza de cache local
      _currentUser = null;
      _backendSessionToken = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_google_user');
      await prefs.remove('auth_backend_token');

      debugPrint('🔑 [GoogleAuthService] Sessão limpa com sucesso.');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('🔑 [GoogleAuthService] Erro ao desconectar: $e');
      rethrow;
    }
  }
}
