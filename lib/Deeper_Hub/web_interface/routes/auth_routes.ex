defmodule DeeperHub.WebInterface.Routes.AuthRoutes do
  @moduledoc """
  Definição de rotas para autenticação, sessões e verificação de e-mail.
  
  Este módulo define as rotas relacionadas à autenticação de usuários,
  gerenciamento de sessões e verificação de e-mail no DeeperHub.
  """
  
  alias DeeperHub.WebInterface.Controllers.SessionController
  alias DeeperHub.WebInterface.Controllers.EmailVerificationController
  
  @doc """
  Define as rotas de autenticação para o router.
  
  ## Parâmetros
    * `router` - Módulo do router
  """
  def define_routes(router) do
    # Rotas públicas (não requerem autenticação)
    router.scope "/api/auth", as: :auth do
      # Login
      router.post "/login", SessionController, :login
      
      # Refresh de tokens
      router.post "/refresh", SessionController, :refresh
      
      # Logout
      router.post "/logout", SessionController, :logout
      
      # Verificação de e-mail
      router.post "/verify-email", EmailVerificationController, :verify_email
    end
    
    # Rotas protegidas (requerem autenticação)
    router.scope "/api/auth", as: :auth do
      # Aplica o plug de autenticação
      router.pipe_through [:api, :auth_required]
      
      # Gerenciamento de sessões
      router.get "/sessions", SessionController, :list_sessions
      router.delete "/sessions/:session_id", SessionController, :terminate_session
      
      # Verificação de e-mail
      router.post "/request-verification", EmailVerificationController, :request_verification
      router.post "/resend-verification", EmailVerificationController, :resend_verification
      router.get "/verification-status", EmailVerificationController, :check_verification_status
    end
  end
end
