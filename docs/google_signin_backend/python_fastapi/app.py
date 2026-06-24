# Servidor de Referência Python + FastAPI para Validação Segura de Google ID Token (JWT)
#
# Requisitos:
# pip install fastapi uvicorn google-auth requests pyjwt

import os
from datetime import datetime, timedelta
from typing import Optional
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests
import jwt

app = FastAPI(
    title="Leitura Feliz - Google Auth Backend",
    description="API de referência para autenticação segura via Google Sign-In"
)

# Configurar o ID do Cliente Web do Console do Google Cloud (Web Client ID)
# IMPORTANTE: Deve ser o mesmo Web Client ID passado ao frontend Flutter (serverClientId)
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "1234567890-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com")
JWT_SECRET = os.getenv("JWT_SECRET", "segredo_estelar_super_secreto_leiturinha_feliz")
JWT_ALGORITHM = "HS256"

class TokenRequest(BaseModel):
    idToken: str

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    photoUrl: Optional[str] = None

class AuthResponse(BaseModel):
    message: str
    token: str
    refreshToken: str
    user: UserResponse

@app.post("/v1/auth/google", response_model=AuthResponse)
async def authenticate_google(payload: TokenRequest):
    """
    Recebe o token JWT (idToken) gerado pelo Flutter e o valida criptograficamente
    com as chaves públicas do Google.
    """
    try:
        print("🛡️ [Backend Python] Iniciando validação de ID Token do Google...")
        
        # Valida criptograficamente o ID Token do Google
        # A biblioteca oficial do Google baixa as chaves públicas do Google automaticamente
        # e valida a expiração, assinatura e a audiência (GOOGLE_CLIENT_ID).
        id_info = id_token.verify_oauth2_token(
            payload.idToken, 
            requests.Request(), 
            GOOGLE_CLIENT_ID
        )

        # Extrair dados de perfil verificados
        userid = id_info.get("sub") # ID Único da Conta Google do Usuário
        email = id_info.get("email")
        email_verified = id_info.get("email_verified")
        name = id_info.get("name")
        picture = id_info.get("picture")

        if not email_verified:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="O endereço de e-mail da Conta Google não está verificado."
            )

        print("✅ [Backend Python] Token verificado com sucesso pelo Google!")
        print(f"👤 Usuário: {name} ({email})")

        # [LÓGICA DO BANCO DE DADOS]
        # Salve ou atualize o usuário em sua base de dados (Ex: PostgreSQL, MongoDB, MySQL)
        # user = db.users.find_or_create(google_id=userid, email=email, name=name)
        mock_user_db = {
            "id": f"user_db_{userid[:10]}",
            "name": name,
            "email": email,
            "photoUrl": picture,
            "role": "parent"
        }

        # Criação da sessão JWT própria do seu sistema
        expiration = datetime.utcnow() + timedelta(days=7)
        token_payload = {
            "sub": mock_user_db["id"],
            "email": mock_user_db["email"],
            "role": mock_user_db["role"],
            "exp": expiration
        }
        
        system_jwt = jwt.encode(token_payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
        mock_refresh_token = f"refresh_token_py_{os.urandom(8).hex()}"

        return AuthResponse(
            message="Autenticação realizada com sucesso",
            token=system_jwt,
            refreshToken=mock_refresh_token,
            user=UserResponse(
                id=mock_user_db["id"],
                name=mock_user_db["name"],
                email=mock_user_db["email"],
                photoUrl=mock_user_db["photoUrl"]
            )
        )

    except ValueError as e:
        # Token inválido ou expirado
        print(f"❌ [Backend Python] Erro ao validar token: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"ID Token inválido ou expirado: {str(e)}"
        )
    except Exception as e:
        print(f"❌ [Backend Python] Falha crítica de autenticação: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno de processamento de autenticação."
        )

if __name__ == "__main__":
    import uvicorn
    print("🚀 Iniciando servidor FastAPI...")
    uvicorn.run(app, host="0.0.0.0", port=3000)
