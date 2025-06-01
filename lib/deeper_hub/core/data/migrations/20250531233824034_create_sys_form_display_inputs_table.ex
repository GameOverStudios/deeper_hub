# Migração gerada com ID único: V1748745504034 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysFormDisplayInputsTable do
  # Migração gerada com ID único: V1748745504034 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_form_display_inputs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_form_display_inputs.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_form_display_inputs...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL, -- Refere-se a sys_form_displays.display_name
      input_name TEXT NOT NULL, -- Refere-se a sys_form_inputs.name (dentro do mesmo form 'object')
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
      active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se o campo está visível/ativo nesta exibição)
      "order" INTEGER NOT NULL
      -- No UNA, a ligação é implícita pelo contexto do 'object' do formulário.
      -- Para FKs explícitas, seria necessário um 'form_object' aqui ou uma PK diferente
      -- em sys_form_displays e sys_form_inputs para referência direta.
    );

    -- Índice para buscar inputs de um display, ordenados.
    CREATE INDEX IF NOT EXISTS idx_sys_form_display_inputs_display_order ON sys_form_display_inputs(display_name, "order");
    -- Garante que um input_name não apareça duas vezes no mesmo display_name.
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_display_inputs_display_input ON sys_form_display_inputs(display_name, input_name);
    CREATE INDEX IF NOT EXISTS idx_sys_form_display_inputs_input_name ON sys_form_display_inputs(input_name);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_form_display_inputs criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_form_display_inputs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_form_display_inputs.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_form_display_inputs...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_form_display_inputs;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_form_display_inputs removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_form_display_inputs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end