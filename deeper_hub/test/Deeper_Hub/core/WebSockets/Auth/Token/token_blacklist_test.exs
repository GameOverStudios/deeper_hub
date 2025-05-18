defmodule Deeper_Hub.Core.WebSockets.Auth.TokenBlacklistTest do
  @moduledoc """
  Testes para o módulo TokenBlacklist.
  """

  use ExUnit.Case, async: false
  alias Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist

  setup do
    # Garantir que a tabela ETS esteja criada
    TokenBlacklist.init()

    # Limpar a tabela ETS após cada teste
    on_exit(fn ->
      # Obtém todos os tokens e remove
      :ets.tab2list(:token_blacklist)
      |> Enum.each(fn {token, _} ->
        TokenBlacklist.remove(token)
      end)
    end)

    :ok
  end

  describe "add/2" do
    test "adiciona um token à blacklist" do
      token = "test_token"
      expiry = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()

      assert :ok = TokenBlacklist.add(token, expiry)
      assert TokenBlacklist.contains?(token)
    end
  end

  describe "contains?/1" do
    test "retorna true para token na blacklist" do
      token = "test_token_in_blacklist"
      expiry = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()

      TokenBlacklist.add(token, expiry)
      assert TokenBlacklist.contains?(token)
    end

    test "retorna false para token que não está na blacklist" do
      token = "test_token_not_in_blacklist"
      refute TokenBlacklist.contains?(token)
    end
  end

  describe "remove/1" do
    test "remove um token da blacklist" do
      token = "test_token_to_remove"
      expiry = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()

      TokenBlacklist.add(token, expiry)
      assert TokenBlacklist.contains?(token)

      TokenBlacklist.remove(token)
      refute TokenBlacklist.contains?(token)
    end
  end

  describe "list/0" do
    test "lista todos os tokens na blacklist" do
      # Limpar a tabela para garantir um estado conhecido
      :ets.tab2list(:token_blacklist)
      |> Enum.each(fn {token, _} -> TokenBlacklist.remove(token) end)

      # Adicionar alguns tokens
      token1 = "test_token_1"
      token2 = "test_token_2"
      expiry = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()

      TokenBlacklist.add(token1, expiry)
      TokenBlacklist.add(token2, expiry)

      tokens = TokenBlacklist.list()
      assert length(tokens) == 2
      assert Enum.any?(tokens, fn {token, _} -> token == token1 end)
      assert Enum.any?(tokens, fn {token, _} -> token == token2 end)
    end
  end

  describe "cleanup_expired_tokens/0" do
    test "remove tokens expirados da blacklist" do
      # Adicionar um token expirado
      expired_token = "expired_token"
      expired_time = DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.to_unix()
      TokenBlacklist.add(expired_token, expired_time)

      # Adicionar um token válido
      valid_token = "valid_token"
      valid_time = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
      TokenBlacklist.add(valid_token, valid_time)

      # Executar a limpeza
      TokenBlacklist.cleanup_expired_tokens()

      # Verificar que apenas o token válido permanece
      refute TokenBlacklist.contains?(expired_token)
      assert TokenBlacklist.contains?(valid_token)
    end
  end
end
