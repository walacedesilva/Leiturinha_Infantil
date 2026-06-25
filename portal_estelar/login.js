/* =============================================================================
   LEITURA FELIZ - SCRIPT DE INTERAÇÃO LÚDICA DA TELA DE LOGIN
   ============================================================================= */

document.addEventListener('DOMContentLoaded', () => {
  
  // Elementos do DOM
  const authForm = document.getElementById('auth-form');
  const emailInput = document.getElementById('email');
  const passwordInput = document.getElementById('password');
  const btnTogglePwd = document.getElementById('btn-toggle-pwd');
  const btnGoogle = document.getElementById('btn-google-login');
  const card = document.getElementById('login-form-card');
  const toast = document.getElementById('playful-toast');
  const toastMsg = document.getElementById('toast-message');
  
  // 1. ANIMAÇÃO DE CARREGAMENTO SUAVE (ENTRADA DO CARD)
  if (card) {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px) scale(0.98)';
    
    setTimeout(() => {
      card.style.transition = 'all 0.8s cubic-bezier(0.165, 0.84, 0.44, 1)';
      card.style.opacity = '1';
      card.style.transform = 'translateY(0) scale(1)';
    }, 150);
  }

  // 2. EXIBIR / OCULTAR SENHA (EYE TOGGLE)
  if (btnTogglePwd && passwordInput) {
    btnTogglePwd.addEventListener('click', () => {
      const isPwd = passwordInput.getAttribute('type') === 'password';
      passwordInput.setAttribute('type', isPwd ? 'text' : 'password');
      btnTogglePwd.textContent = isPwd ? '🙈' : '👁️';
      
      // Feedback tátil visual
      btnTogglePwd.style.transform = 'scale(0.85)';
      setTimeout(() => {
        btnTogglePwd.style.transform = 'scale(1)';
      }, 100);
    });
  }

  // 3. EXIBIR NOTIFICAÇÃO LÚDICA (TOAST CUSTOMIZADO)
  function showPlayfulToast(message, emoji = '🌟') {
    if (!toast || !toastMsg) return;
    
    // Atualiza texto e emoji
    toastMsg.textContent = message;
    const emojiSpan = toast.querySelector('.toast-emoji');
    if (emojiSpan) emojiSpan.textContent = emoji;
    
    // Exibe o toast
    toast.classList.remove('hidden');
    
    // Oculta após 3.5 segundos
    setTimeout(() => {
      toast.classList.add('hidden');
    }, 3500);
  }

  // 4. SUBMIT DO FORMULÁRIO (SIMULAÇÃO DE LOGIN OU CADASTRO)
  let isRegisterMode = false;
  const signupPrompt = document.querySelector('.signup-prompt');
  const formTitle = document.querySelector('.form-title');
  const btnSubmit = document.getElementById('btn-signin');
  const dividerRow = document.querySelector('.divider-row');
  
  // Elemento do grupo de input para o Nome Completo no Registro
  const nameInputGroup = document.createElement('div');
  nameInputGroup.className = 'input-group name-group';
  nameInputGroup.style.transition = 'all 0.3s ease';
  nameInputGroup.innerHTML = `
    <label for="username" id="lbl-username">Nome Completo</label>
    <input 
      type="text" 
      id="username" 
      placeholder="Seu nome estelar" 
      required
      aria-labelledby="lbl-username"
    >
  `;

  // Listener para alternar dinamicamente entre Login e Registro
  if (signupPrompt) {
    signupPrompt.addEventListener('click', (e) => {
      if (e.target.classList.contains('signup-link')) {
        e.preventDefault();
        toggleRegisterMode(true);
      } else if (e.target.classList.contains('signin-link')) {
        e.preventDefault();
        toggleRegisterMode(false);
      }
    });
  }

  function toggleRegisterMode(enable) {
    isRegisterMode = enable;
    if (enable) {
      formTitle.textContent = 'Criar Conta';
      btnSubmit.textContent = 'Cadastrar e Explorar';
      
      // Insere campo de nome no topo do formulário
      const firstInputGroup = authForm.querySelector('.input-group');
      authForm.insertBefore(nameInputGroup, firstInputGroup);
      
      // Micro-animação para o campo de nome surgir suavemente
      nameInputGroup.style.opacity = '0';
      nameInputGroup.style.transform = 'translateY(-15px)';
      nameInputGroup.style.maxHeight = '0px';
      nameInputGroup.style.overflow = 'hidden';
      nameInputGroup.style.marginBottom = '0px';
      
      setTimeout(() => {
        nameInputGroup.style.transition = 'all 0.4s cubic-bezier(0.165, 0.84, 0.44, 1)';
        nameInputGroup.style.opacity = '1';
        nameInputGroup.style.transform = 'translateY(0)';
        nameInputGroup.style.maxHeight = '100px';
        nameInputGroup.style.marginBottom = '18px';
      }, 50);

      // Oculta login social do Google
      if (btnGoogle) btnGoogle.style.display = 'none';
      if (dividerRow) dividerRow.style.display = 'none';
      
      // Modifica prompt para voltar a tela de Login
      signupPrompt.innerHTML = `Já tem uma conta? <a href="#" class="signin-link" style="color: var(--primary-orange); font-weight: 700; text-decoration: none;">Fazer Login</a>`;
      
      const signinLink = signupPrompt.querySelector('.signin-link');
      if (signinLink) {
        signinLink.addEventListener('mouseover', () => signinLink.style.textDecoration = 'underline');
        signinLink.addEventListener('mouseout', () => signinLink.style.textDecoration = 'none');
      }
    } else {
      formTitle.textContent = 'Login';
      btnSubmit.textContent = 'Sign in';
      
      if (authForm.contains(nameInputGroup)) {
        authForm.removeChild(nameInputGroup);
      }
      
      if (btnGoogle) btnGoogle.style.display = 'flex';
      if (dividerRow) dividerRow.style.display = 'flex';
      
      signupPrompt.innerHTML = `Don't have an account yet? <a href="#" class="signup-link" style="color: var(--primary-orange); font-weight: 700; text-decoration: none;">Register for free</a>`;
      
      const signupLinkEl = signupPrompt.querySelector('.signup-link');
      if (signupLinkEl) {
        signupLinkEl.addEventListener('mouseover', () => signupLinkEl.style.textDecoration = 'underline');
        signupLinkEl.addEventListener('mouseout', () => signupLinkEl.style.textDecoration = 'none');
      }
    }
  }

  if (authForm) {
    authForm.addEventListener('submit', (e) => {
      e.preventDefault();
      
      const emailVal = emailInput.value.trim();
      const nameVal = isRegisterMode ? document.getElementById('username').value.trim() : '';
      
      // Animação de envio no botão
      const originalText = btnSubmit.textContent;
      btnSubmit.textContent = isRegisterMode ? 'Criando sua órbita... 🚀' : 'Verificando estrelas... 🔑';
      btnSubmit.style.opacity = '0.85';
      btnSubmit.style.pointerEvents = 'none';
      
      // Simula uma resposta do servidor após 1.5s
      setTimeout(() => {
        btnSubmit.textContent = originalText;
        btnSubmit.style.opacity = '1';
        btnSubmit.style.pointerEvents = 'auto';
        
        if (isRegisterMode) {
          showPlayfulToast(`Conta criada com sucesso! Bem-vindo(a), ${nameVal}! 🚀`, '✨');
        } else {
          showPlayfulToast(`Parabéns! Login efetuado para: ${emailVal}`, '🔑');
        }
        
        // Efeito de sucesso - treme as estrelinhas na tela
        const svg = document.querySelector('.girl-reading-svg');
        if (svg) {
          svg.classList.add('success-shake');
          setTimeout(() => svg.classList.remove('success-shake'), 600);
        }

        // Redireciona para o Portal Estelar após 2 segundos
        setTimeout(() => {
          window.location.href = 'index.html';
        }, 2000);
      }, 1500);
    });
  }

  // 5. LOGIN COM O GOOGLE (SIMULAÇÃO COM REDIRECIONAMENTO)
  if (btnGoogle) {
    btnGoogle.addEventListener('click', () => {
      btnGoogle.style.transform = 'scale(0.98)';
      setTimeout(() => btnGoogle.style.transform = 'scale(1)', 100);
      
      showPlayfulToast('Conectando de forma segura à sua Conta Google...', '🤖');
      
      setTimeout(() => {
        showPlayfulToast('Acesso concedido! Bem-vindo ao Leitura Feliz! 🌈', '🌈');
        
        // Redireciona para o Portal Estelar após 2 segundos
        setTimeout(() => {
          window.location.href = 'index.html';
        }, 2000);
      }, 1800);
    });
  }
  
  // 6. MICRO-INTERAÇÕES DE INPUTS
  const inputs = [emailInput, passwordInput];
  inputs.forEach(input => {
    if (input) {
      input.addEventListener('focus', () => {
        input.parentElement.style.transform = 'translateY(-1px)';
      });
      input.addEventListener('blur', () => {
        input.parentElement.style.transform = 'translateY(0)';
      });
    }
  });
});

