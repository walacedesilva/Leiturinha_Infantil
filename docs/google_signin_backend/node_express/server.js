/**
 * Servidor de Referência Node.js + Express para Validação Segura de Google ID Token (JWT)
 * 
 * Requisitos:
 * npm install express body-parser google-auth-library jsonwebtoken cors
 */

const express = require('express');
const bodyParser = require('body-parser');
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Configurar o ID do Cliente Web do Console do Google Cloud (Web Client ID)
// IMPORTANTE: Deve ser o mesmo Web Client ID passado ao frontend Flutter (serverClientId)
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '1234567890-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com';
const JWT_SECRET = process.env.JWT_SECRET || 'segredo_estelar_super_secreto_leiturinha_feliz';

const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

app.use(cors());
app.use(bodyParser.json());

// Log de requisições simples
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

/**
 * ROTA: /v1/auth/google
 * Recebe o token JWT (idToken) gerado pelo Flutter e o valida criptograficamente
 * com as chaves públicas do Google.
 */
app.post('/v1/auth/google', async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({
      error: 'Token ausente',
      message: 'O parâmetro idToken é obrigatório no corpo da requisição.'
    });
  }

  try {
    console.log('🛡️ [Backend] Iniciando validação de ID Token do Google...');

    // Valida criptograficamente o token e extrai a carga útil (payload)
    const ticket = await googleClient.verifyIdToken({
      idToken: idToken,
      audience: GOOGLE_CLIENT_ID, // Garante que o token foi emitido para o SEU aplicativo
    });

    const payload = ticket.getPayload();
    
    // Verificações extras de segurança
    const userid = payload['sub']; // ID Único da Conta Google do Usuário
    const email = payload['email'];
    const emailVerified = payload['email_verified'];
    const name = payload['name'];
    const picture = payload['picture'];

    if (!emailVerified) {
      return res.status(401).json({
        error: 'E-mail não verificado',
        message: 'A conta Google precisa ter o e-mail verificado para autenticar.'
      });
    }

    console.log('✅ [Backend] Token verificado com sucesso pelo Google!');
    console.log(`👤 Usuário: ${name} (${email})`);
    console.log(`🆔 Google Sub ID: ${userid}`);

    // [LÓGICA DO BANCO DE DADOS]
    // Aqui você criaria ou atualizaria o registro do usuário em seu banco (ex: MongoDB, PostgreSQL)
    // const user = await User.findOrCreate({ googleId: userid, email, name, avatar: picture });
    const mockUserDbRecord = {
      id: `user_db_${userid.substring(0, 10)}`,
      name: name,
      email: email,
      photoUrl: picture,
      role: 'parent',
      createdAt: new Date().toISOString()
    };

    // Gera um token JWT próprio do seu sistema para manter a sessão segura sob HTTPS
    const systemToken = jwt.sign(
      {
        userId: mockUserDbRecord.id,
        email: mockUserDbRecord.email,
        role: mockUserDbRecord.role
      },
      JWT_SECRET,
      { expiresIn: '7d' } // Expira em 7 dias
    );

    // Refresh Token simulado para segurança extra
    const mockRefreshToken = `refresh_token_${Math.random().toString(36).substring(2, 15)}`;

    // Retorna a sessão para o aplicativo Flutter
    return res.status(200).json({
      message: 'Autenticação concluída com sucesso',
      token: systemToken,
      refreshToken: mockRefreshToken,
      user: {
        id: mockUserDbRecord.id,
        name: mockUserDbRecord.name,
        email: mockUserDbRecord.email,
        photoUrl: mockUserDbRecord.photoUrl
      }
    });

  } catch (error) {
    console.error('❌ [Backend] Erro ao validar ID Token do Google:', error.message);
    
    return res.status(401).json({
      error: 'Autenticação falhou',
      message: 'O token do Google é inválido ou expirou.',
      details: error.message
    });
  }
});

// Middleware genérico de tratamento de erros
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Erro interno no servidor' });
});

// Inicializar Servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor de referência do Leitura Feliz rodando na porta ${PORT}`);
  console.log(`🔗 Endpoint de autenticação ativo em: http://localhost:${PORT}/v1/auth/google`);
});
