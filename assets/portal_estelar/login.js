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

  // 4. SUBMIT DO FORMULÁRIO (SIMULAÇÃO DE LOGIN)
  if (authForm) {
    authForm.addEventListener('submit', (e) => {
      e.preventDefault();
      
      const emailVal = emailInput.value.trim();
      
      // Animação de envio no botão
      const btnSubmit = document.getElementById('btn-signin');
      const originalText = btnSubmit.textContent;
      btnSubmit.textContent = 'Verificando estrelas... Q';
      btnSubmit.style.opacity = '0.85';
      btnSubmit.style.pointerEvents = 'none';
      
      // Simula uma resposta do servidor após 1.5s
      setTimeout(() => {
        btnSubmit.textContent = originalText;
        btnSubmit.style.opacity = '1';
        btnSubmit.style.pointerEvents = 'auto';
        
        showPlayfulToast(`Parabéns! Login efetuado para: ${emailVal}`, '🔑');
        
        // Efeito de sucesso - treme as estrelinhas na tela
        const svg = document.querySelector('.girl-reading-svg');
        if (svg) {
          svg.classList.add('success-shake');
          setTimeout(() => svg.classList.remove('success-shake'), 600);
        }
      }, 1500);
    });
  }

  // 5. LOGIN COM O GOOGLE (SIMULAÇÃO)
  if (btnGoogle) {
    btnGoogle.addEventListener('click', () => {
      btnGoogle.style.transform = 'scale(0.98)';
      setTimeout(() => btnGoogle.style.transform = 'scale(1)', 100);
      
      showPlayfulToast('Conectando de forma segura à sua Conta Google...', '🤖');
      
      setTimeout(() => {
        showPlayfulToast('Acesso concedido! Bem-vindo ao Leitura Feliz!', '🌈');
      }, 2000);
    });
  }
  
  // 6. MICRO-INTERAÇÕES DE INPUTS (AUDIO MOCK OU SOM NO FUTURO)
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
