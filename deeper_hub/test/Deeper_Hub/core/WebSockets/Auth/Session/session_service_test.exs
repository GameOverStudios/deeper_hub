defmodule Deeper_Hub.Core.WebSockets.Auth.Session.SessionServiceTest do
  @moduledoc """
  Testes para o módulo SessionService.
  """
  
  use ExUnit.Case, async: false
  import Deeper_Hub.Factory
  
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionService
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionManager
  
  setup do
    # Garantir que o SessionManager esteja iniciado
    start_supervised(SessionManager)
    
    # Limpar todas as sessões após cada teste
    on_exit(fn ->
      :ets.tab2list(:sessions)
      |> Enum.each(fn {session_id, _} -> 
        :ets.delete(:sessions, session_id)
      end)
    end)
    
    :ok
  end
  
  describe "create_session/3" do
    test "cria uma nova sessão para um usuário" do
      user = build(:user)
      remember_me = false
      metadata = %{ip_address: "127.0.0.1", user_agent: "Test Browser"}
      
      {:ok, session} = SessionService.create_session(user.id, remember_me, metadata)
      
      assert session.user_id == user.id
      assert session.ip_address == "127.0.0.1"
      assert session.user_agent == "Test Browser"
      assert is_binary(session.id)
      assert is_binary(session.access_token)
      assert is_binary(session.refresh_token)
    end
    
    test "cria uma sessão com duração estendida quando remember_me é true" do
      user = build(:user)
      remember_me = true
      metadata = %{ip_address: "127.0.0.1", user_agent: "Test Browser"}
      
      {:ok, session} = SessionService.create_session(user.id, remember_me, metadata)
      
      # Verifica se a expiração é mais longa (pelo menos 7 dias)
      now = DateTime.utc_now()
      days_diff = DateTime.diff(session.expires_at, now, :second) / 86400
      
      assert days_diff >= 7
    end
  end
  
  describe "get_session/1" do
    test "retorna uma sessão existente" do
      # Criar uma sessão
      user = build(:user)
      {:ok, session} = SessionService.create_session(user.id)
      
      # Buscar a sessão
      {:ok, found_session} = SessionService.get_session(session.id)
      
      assert found_session.id == session.id
      assert found_session.user_id == user.id
    end
    
    test "retorna erro para sessão inexistente" do
      result = SessionService.get_session("nonexistent_session_id")
      assert result == {:error, :not_found}
    end
  end
  
  describe "get_user_sessions/1" do
    test "retorna todas as sessões de um usuário" do
      user = build(:user)
      
      # Criar múltiplas sessões para o mesmo usuário
      {:ok, session1} = SessionService.create_session(user.id)
      {:ok, session2} = SessionService.create_session(user.id)
      
      # Buscar as sessões do usuário
      sessions = SessionService.get_user_sessions(user.id)
      
      assert length(sessions) == 2
      assert Enum.any?(sessions, fn s -> s.id == session1.id end)
      assert Enum.any?(sessions, fn s -> s.id == session2.id end)
    end
    
    test "retorna lista vazia para usuário sem sessões" do
      sessions = SessionService.get_user_sessions("user_without_sessions")
      assert sessions == []
    end
  end
  
  describe "update_activity/1" do
    test "atualiza a última atividade de uma sessão" do
      user = build(:user)
      {:ok, session} = SessionService.create_session(user.id)
      
      # Esperar um pouco para garantir diferença de timestamp
      :timer.sleep(10)
      
      # Atualizar a atividade
      {:ok, updated_session} = SessionService.update_activity(session.id)
      
      # Verificar que o timestamp foi atualizado
      assert DateTime.compare(updated_session.last_activity, session.last_activity) == :gt
    end
  end
  
  describe "end_session/3" do
    test "remove uma sessão existente" do
      user = build(:user)
      {:ok, session} = SessionService.create_session(user.id)
      
      # Verificar que a sessão existe
      {:ok, _} = SessionService.get_session(session.id)
      
      # Remover a sessão
      :ok = SessionService.end_session(session.id, session.access_token, session.refresh_token)
      
      # Verificar que a sessão não existe mais
      result = SessionService.get_session(session.id)
      assert result == {:error, :not_found}
    end
  end
  
  describe "end_all_user_sessions/1" do
    test "remove todas as sessões de um usuário" do
      user = build(:user)
      
      # Criar múltiplas sessões para o mesmo usuário
      {:ok, _} = SessionService.create_session(user.id)
      {:ok, _} = SessionService.create_session(user.id)
      
      # Verificar que existem sessões
      sessions_before = SessionService.get_user_sessions(user.id)
      assert length(sessions_before) == 2
      
      # Remover todas as sessões
      :ok = SessionService.end_all_user_sessions(user.id)
      
      # Verificar que não existem mais sessões
      sessions_after = SessionService.get_user_sessions(user.id)
      assert sessions_after == []
    end
  end
end
