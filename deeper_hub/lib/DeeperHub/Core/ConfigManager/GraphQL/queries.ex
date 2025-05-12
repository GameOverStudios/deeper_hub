defmodule DeeperHub.Core.ConfigManager.GraphQL.Queries do
  @moduledoc """
  Queries GraphQL para o ConfigManager.

  Define as operações de consulta que permitem obter configurações do sistema.
  """

  use Absinthe.Schema.Notation

  alias DeeperHub.Core.ConfigManager
  alias DeeperHub.Core.ConfigManager.Services.Setting, as: SettingService

  @desc "Queries relacionadas às configurações do sistema"
  object :config_queries do
    @desc "Obtém uma configuração pelo par chave/escopo"
    field :config, :setting do
      arg :key, non_null(:string), description: "Chave da configuração"
      arg :scope, :string, description: "Escopo da configuração"

      resolve fn args, _context ->
        scope = args[:scope] || "global"
        case SettingService.get_by_key_and_scope(args.key, scope) do
          {:ok, setting} -> {:ok, setting}
          {:error, :not_found} -> {:error, "Configuração não encontrada"}
        end
      end
    end

    @desc "Lista todas as configurações para um escopo específico"
    field :configs_by_scope, list_of(:setting) do
      arg :scope, :string, description: "Escopo das configurações"

      resolve fn args, _context ->
        scope = args[:scope] || "global"
        settings = SettingService.list_by_scope(scope)
        {:ok, settings}
      end
    end

    @desc "Lista todas as configurações que correspondem a um padrão de chave"
    field :configs_by_pattern, list_of(:setting) do
      arg :pattern, non_null(:string), description: "Padrão regex para as chaves"
      arg :scope, :string, description: "Escopo das configurações"

      resolve fn args, _context ->
        scope = args[:scope] || "global"
        settings = SettingService.list_by_key_pattern(args.pattern, scope)
        {:ok, settings}
      end
    end

    @desc "Obtém o valor de uma configuração (wrapper para a API principal)"
    field :config_value, :string do
      arg :key, non_null(:string), description: "Chave da configuração"
      arg :scope, :string, description: "Escopo da configuração"
      arg :default, :string, description: "Valor padrão se a configuração não existir"

      resolve fn args, _context ->
        scope = args[:scope] || "global"
        default = args[:default]

        value = ConfigManager.get(args.key, scope, default)
        {:ok, to_string(value)}
      end
    end
  end
end
