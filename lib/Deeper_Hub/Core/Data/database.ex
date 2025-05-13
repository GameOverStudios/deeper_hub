defmodule Deeper_Hub.Core.Data.Database do
  @moduledoc """
  Módulo responsável pela gestão do banco de dados Mnesia.
  Gerencia a inicialização, criação de tabelas e migrações.

  Segue princípios SOLID:
  - Single Responsibility: Gerencia exclusivamente operações de banco de dados
  - Open/Closed: Extensível para novas tabelas e migrações
  """

  alias Deeper_Hub.Core.Logger

  @doc """
  Inicializa o banco de dados Mnesia.
  Cria o banco de dados se não existir e realiza as migrações necessárias.
  """
  @spec init() :: :ok | {:error, any()}
  def init do
    # Certifica-se de que o Mnesia está parado antes de iniciar
    :mnesia.stop()

    # Cria o schema do Mnesia no nó atual
    case :mnesia.create_schema([node()]) do
      :ok ->
        :ok

      {:error, {_, {:already_exists, _}}} ->
        :ok

      {:error, reason} ->
        Deeper_Hub.Core.Logger.error("Erro ao criar schema: #{inspect(reason)}", %{
          module: __MODULE__
        })

        {:error, reason}
    end

    # Inicia o Mnesia
    :ok = :mnesia.start()

    # Cria tabelas necessárias
    result = create_tables()

    case result do
      :ok ->
        Deeper_Hub.Core.Logger.info("Banco de dados Mnesia inicializado com sucesso", %{
          module: __MODULE__
        })

        :ok

      {:error, reason} ->
        Deeper_Hub.Core.Logger.error(
          "Falha na inicialização do banco de dados: #{inspect(reason)}",
          %{module: __MODULE__}
        )

        {:error, reason}
    end
  end

  @doc """
  Cria as tabelas necessárias no banco de dados Mnesia.
  Trata tabelas já existentes sem gerar erro.
  """
  @spec create_tables(Keyword.t()) :: :ok | {:error, atom() | any()}
  def create_tables(opts \\ []) do
    # Verificar se estamos em modo de teste
    is_test = Keyword.get(opts, :test_mode, false)
    
    # Escolher o tipo de armazenamento com base no modo
    storage_type = if is_test, do: :ram_copies, else: :disc_copies
    storage_nodes = [node()]
    
    # Definição das tabelas
    table_definitions = [
      {:users,
       [
         {:attributes, [:id, :username, :email, :password_hash, :created_at]},
         {:type, :set},
         {storage_type, storage_nodes},
         {:record_name, :users} # Adicionado record_name para garantir compatibilidade
       ]},
      {:sessions,
       [
         {:attributes, [:id, :user_id, :token, :expires_at]},
         {:type, :set},
         {storage_type, storage_nodes},
         {:record_name, :sessions} # Adicionado record_name para garantir compatibilidade
       ]}
    ]

    # Cria as tabelas com tratamento de erros
    results =
      Enum.map(table_definitions, fn {table_name, table_opts} ->
        case :mnesia.create_table(table_name, table_opts) do
          {:atomic, :ok} ->
            Deeper_Hub.Core.Logger.info("Tabela #{table_name} criada com sucesso", %{
              module: __MODULE__
            })

            :ok

          {:aborted, {:already_exists, _}} ->
            Deeper_Hub.Core.Logger.info("Tabela #{table_name} já existe, pulando criação", %{
              module: __MODULE__
            })

            :ok

          {:aborted, reason} ->
            Deeper_Hub.Core.Logger.error(
              "Falha ao criar tabela #{table_name}: #{inspect(reason)}",
              %{module: __MODULE__}
            )

            {:error, reason}
        end
      end)

    # Verifica se todas as tabelas foram criadas ou já existiam
    if Enum.all?(results, &(&1 == :ok)) do
      # Aguarda a sincronização das tabelas
      case :mnesia.wait_for_tables(Keyword.keys(table_definitions), 5000) do
        :ok -> :ok
        {:timeout, _} -> {:error, :table_sync_timeout}
        error -> {:error, error}
      end
    else
      {:error, :table_creation_failed}
    end
  end

  @doc """
  Realiza uma migração no banco de dados.

  ## Parâmetros
    - migration_name: Nome da migração a ser executada
    - migration_fun: Função que realiza a migração
  """
  @spec migrate(String.t(), (-> :ok | {:error, any()})) :: :ok | {:error, any()}
  def migrate(migration_name, migration_fun) do
    Logger.info("Executando migração: #{migration_name}")

    try do
      migration_fun.()
      Logger.info("Migração #{migration_name} concluída com sucesso")
      :ok
    rescue
      error ->
        Logger.error("Erro na migração #{migration_name}: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Fecha a conexão com o banco de dados Mnesia.
  """
  @spec shutdown() :: :ok
  def shutdown do
    :mnesia.stop()
    Deeper_Hub.Core.Logger.info("Banco de dados Mnesia encerrado", %{module: __MODULE__})
  end
end
