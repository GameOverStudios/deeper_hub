defmodule Deeper_Hub.Core.WebSockets.Security.CsrfProtectionTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.CsrfProtection
  
  # Mock do objeto de requisição Cowboy para testes
  defp mock_req(headers \\ %{}) do
    %{headers: headers}
  end
  
  # Mock da função :cowboy_req.header/2
  defp mock_cowboy_req_header do
    :meck.new(:cowboy_req, [:passthrough])
    :meck.expect(:cowboy_req, :header, fn name, req, default \\ nil ->
      Map.get(req.headers, name, default)
    end)
    
    :meck.expect(:cowboy_req, :peer, fn _req ->
      {{127, 0, 0, 1}, 12345}
    end)
    
    on_exit(fn -> :meck.unload(:cowboy_req) end)
  end
  
  setup do
    mock_cowboy_req_header()
    
    # Cria um token de teste e o armazena
    session_id = "test_session_123"
    {:ok, token} = CsrfProtection.generate_token(session_id)
    
    %{
      session_id: session_id,
      token: token,
      state: %{}
    }
  end
  
  describe "validate_request/2" do
    test "permite requisição com origem permitida e token válido", %{session_id: session_id, token: token} do
      # Configura a requisição com origem permitida e token válido
      req = mock_req(%{
        "origin" => "http://localhost",
        "x-csrf-token" => token,
        "x-session-id" => session_id
      })
      
      assert {:ok, _state} = CsrfProtection.validate_request(req, %{})
    end
    
    test "rejeita requisição com origem não permitida", %{session_id: session_id, token: token} do
      # Configura a requisição com origem não permitida
      req = mock_req(%{
        "origin" => "http://malicious-site.com",
        "x-csrf-token" => token,
        "x-session-id" => session_id
      })
      
      assert {:error, _reason} = CsrfProtection.validate_request(req, %{})
    end
    
    test "rejeita requisição sem token CSRF", %{session_id: session_id} do
      # Configura a requisição sem token CSRF
      req = mock_req(%{
        "origin" => "http://localhost",
        "x-session-id" => session_id
      })
      
      assert {:error, _reason} = CsrfProtection.validate_request(req, %{})
    end
    
    test "rejeita requisição com token CSRF inválido", %{session_id: session_id} do
      # Configura a requisição com token CSRF inválido
      req = mock_req(%{
        "origin" => "http://localhost",
        "x-csrf-token" => "invalid-token",
        "x-session-id" => session_id
      })
      
      assert {:error, _reason} = CsrfProtection.validate_request(req, %{})
    end
    
    test "permite requisição sem origem mas com token válido", %{session_id: session_id, token: token} do
      # Configura a requisição sem origem mas com token válido
      req = mock_req(%{
        "x-csrf-token" => token,
        "x-session-id" => session_id
      })
      
      assert {:ok, _state} = CsrfProtection.validate_request(req, %{})
    end
  end
  
  describe "generate_token/1" do
    test "gera um token único para cada sessão" do
      {:ok, token1} = CsrfProtection.generate_token("session1")
      {:ok, token2} = CsrfProtection.generate_token("session2")
      
      assert token1 != token2
      assert is_binary(token1)
      assert is_binary(token2)
      assert String.length(token1) > 0
      assert String.length(token2) > 0
    end
  end
  
  describe "invalidate_token/2" do
    test "invalida um token existente", %{session_id: session_id, token: token} do
      # Verifica que o token é válido antes de invalidar
      req = mock_req(%{
        "origin" => "http://localhost",
        "x-csrf-token" => token,
        "x-session-id" => session_id
      })
      
      assert {:ok, _state} = CsrfProtection.validate_request(req, %{})
      
      # Invalida o token
      assert :ok = CsrfProtection.invalidate_token(session_id, token)
      
      # Verifica que o token não é mais válido
      assert {:error, _reason} = CsrfProtection.validate_request(req, %{})
    end
  end
end
