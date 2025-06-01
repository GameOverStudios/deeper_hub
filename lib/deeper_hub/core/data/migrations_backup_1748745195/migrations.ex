defmodule DeeperHub.Core.Data.Migrations do
  @moduledoc """
  Módulo responsável por gerenciar migrações de banco de dados para o DeeperHub.

  Este módulo é responsável por verificar e executar migrações de banco de dados
  automaticamente durante a inicialização da aplicação, garantindo que o esquema
  do banco de dados esteja sempre atualizado.

  Ele interage com o DeeperHub.Core.Data.Repo para executar as migrações
  e gerencia o controle de versão das migrações aplicadas.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Inicializa o sistema de migrações e executa todas as migrações pendentes.
  Esta função deve ser chamada durante a inicialização da aplicação.

  Retorna `:ok` se todas as migrações foram aplicadas com sucesso ou
  `{:error, reason}` se ocorreu algum erro.
  """
  @spec initialize() :: :ok | {:error, any()}
  def initialize do
    Logger.info("Inicializando sistema de migrações...", module: __MODULE__)

    # Aguarda até que o pool de conexões esteja disponível antes de prosseguir
    # Aumenta o número de tentativas e o tempo de espera para garantir que o pool esteja pronto
    max_attempts = 10
    wait_time_ms = 1000

    case wait_for_pool(max_attempts, wait_time_ms) do
      :ok ->
        Logger.info("Pool de conexões disponível. Prosseguindo com as migrações.", module: __MODULE__)

        # Primeiro, inicializa o banco de dados (garante que o diretório e arquivo existam)
        with :ok <- DeeperHub.Core.Data.Migrations.Initializer.initialize(),
             :ok <- ensure_migrations_table(),
             {:ok, applied_versions} <- get_applied_migrations(),
             {:ok, available_migrations} <- get_available_migrations(),
             pending_migrations = filter_pending_migrations(available_migrations, applied_versions),
             :ok <- apply_migrations(pending_migrations) do

          Logger.info("Sistema de migrações inicializado com sucesso.", module: __MODULE__)
          :ok
        else
          {:error, reason} = error ->
            Logger.error("Falha ao inicializar sistema de migrações: #{inspect(reason)}", module: __MODULE__)
            error
        end
      {:error, :pool_not_found} ->
        Logger.error("Pool de conexões não está disponível para executar migrações após #{max_attempts} tentativas", module: __MODULE__)
        {:error, :pool_not_found}
    end
  end

  # Função auxiliar para aguardar até que o pool de conexões esteja disponível
  @spec wait_for_pool(integer(), integer()) :: :ok | {:error, :pool_not_found}
  defp wait_for_pool(max_attempts, wait_time_ms) do
    wait_for_pool(1, max_attempts, wait_time_ms)
  end

  defp wait_for_pool(attempt, max_attempts, wait_time_ms) do
    Logger.debug("Verificando disponibilidade do pool de conexões (tentativa #{attempt}/#{max_attempts})...", module: __MODULE__)

    # Verifica se o processo do pool existe e está registrado
    pool_name = Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])
                |> Keyword.get(:pool_name, DeeperHub.DBConnectionPool)

    pool_pid = Process.whereis(pool_name)

    cond do
      # Se o processo existe e está vivo
      is_pid(pool_pid) and Process.alive?(pool_pid) ->
        # Tenta executar uma consulta simples para verificar se o pool está realmente funcional
        try_test_query(pool_name, attempt, max_attempts, wait_time_ms)

      # Se o processo não existe ou não está vivo
      true ->
        if attempt < max_attempts do
          Logger.warn("Pool de conexões #{inspect(pool_name)} não encontrado ou não está ativo. Aguardando #{wait_time_ms}ms antes da próxima tentativa...", module: __MODULE__)
          Process.sleep(wait_time_ms)
          wait_for_pool(attempt + 1, max_attempts, wait_time_ms)
        else
          Logger.error("Pool de conexões #{inspect(pool_name)} não encontrado ou não está ativo após #{max_attempts} tentativas.", module: __MODULE__)
          {:error, :pool_not_found}
        end
    end
  end

  # Tenta executar uma consulta simples para verificar se o pool está realmente funcional
  defp try_test_query(pool_name, attempt, max_attempts, wait_time_ms) do
    # Em vez de tentar executar uma consulta diretamente com DBConnection.execute,
    # vamos usar o módulo Repo que já está configurado corretamente
    try do
      # Verifica se o processo do pool existe e está ativo
      if Process.alive?(Process.whereis(pool_name)) do
        Logger.info("Pool de conexões #{inspect(pool_name)} está registrado e ativo.", module: __MODULE__)

        # Aguarda um curto período para permitir que o pool seja completamente inicializado
        Process.sleep(500)

        # Tenta executar uma consulta simples usando o módulo Repo
        case DeeperHub.Core.Data.Repo.query("SELECT 1 AS test;") do
          {:ok, _rows} ->
            Logger.info("Pool de conexões #{inspect(pool_name)} está funcional.", module: __MODULE__)
            :ok
          {:error, error} ->
            Logger.warn("Erro ao executar consulta de teste via Repo: #{inspect(error)}", module: __MODULE__)
            retry_or_fail(attempt, max_attempts, wait_time_ms)
        end
      else
        Logger.warn("Pool de conexões #{inspect(pool_name)} não está ativo.", module: __MODULE__)
        retry_or_fail(attempt, max_attempts, wait_time_ms)
      end
    rescue
      error ->
        Logger.warn("Exceção ao verificar pool de conexões: #{inspect(error)}", module: __MODULE__)
        retry_or_fail(attempt, max_attempts, wait_time_ms)
    end
  end

  # Função auxiliar para decidir se deve tentar novamente ou falhar
  defp retry_or_fail(attempt, max_attempts, wait_time_ms) do
    if attempt < max_attempts do
      Logger.warn("Tentando novamente em #{wait_time_ms}ms (tentativa #{attempt}/#{max_attempts})...", module: __MODULE__)
      Process.sleep(wait_time_ms)
      wait_for_pool(attempt + 1, max_attempts, wait_time_ms)
    else
      Logger.error("Falha ao verificar funcionalidade do pool após #{max_attempts} tentativas.", module: __MODULE__)
      {:error, :pool_not_found}
    end
  end

  @doc """
  Garante que a tabela de controle de migrações exista no banco de dados.
  Se a tabela não existir, ela será criada.

  Retorna `:ok` se a tabela já existe ou foi criada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec ensure_migrations_table() :: :ok | {:error, any()}
  def ensure_migrations_table do
    sql = """
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      inserted_at TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.debug("Tabela de migrações verificada/criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de migrações: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Obtém a lista de migrações já aplicadas no banco de dados.

  Retorna `{:ok, [version]}` com a lista de versões aplicadas,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec get_applied_migrations() :: {:ok, [String.t()]} | {:error, any()}
  def get_applied_migrations do
    sql = "SELECT version FROM schema_migrations ORDER BY version;"

    case Repo.query(sql) do
      {:ok, rows} ->
        # O Exqlite retorna os resultados como listas, não como mapas
        # Cada linha é uma lista onde o primeiro elemento é o valor da coluna 'version'
        versions = Enum.map(rows, fn [version] -> version end)
        Logger.debug("Migrações aplicadas: #{inspect(versions)}", module: __MODULE__)
        {:ok, versions}
      {:error, reason} ->
        Logger.error("Falha ao obter migrações aplicadas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Obtém a lista de migrações disponíveis no sistema.

  Retorna `{:ok, [{version, module}]}` com a lista de versões e módulos disponíveis,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec get_available_migrations() :: {:ok, [{String.t(), module()}]} | {:error, any()}
  def get_available_migrations do
    # Lista de migrações disponíveis
    # Cada migração é representada por uma tupla {versão, módulo}
    migrations = [
      {"20250518000001", DeeperHub.Core.Data.Migrations.CreateUsersTable},
      {"20250531233823800", DeeperHub.Core.Data.Migrations.CreateDeeperConnBansTable},
      {"20250531233823803", DeeperHub.Core.Data.Migrations.CreateDeeperConnFriendsTable},
      {"20250531233823809", DeeperHub.Core.Data.Migrations.CreateDeeperConnSubscriptionsTable},
      {"20250531233823816", DeeperHub.Core.Data.Migrations.CreateBxMarketCategoriesTable},
      {"20250531233823819", DeeperHub.Core.Data.Migrations.CreateBxMarketEntriesTable},
      {"20250531233823822", DeeperHub.Core.Data.Migrations.CreateBxMarketPhotosTable},
      {"20250531233823824", DeeperHub.Core.Data.Migrations.CreateBxOrganizationsCategoriesTable},
      {"20250531233823827", DeeperHub.Core.Data.Migrations.CreateBxOrganizationsDataTable},
      {"20250531233823831", DeeperHub.Core.Data.Migrations.CreateBxOrganizationsMembersTable},
      {"20250531233823836", DeeperHub.Core.Data.Migrations.CreateBxPersonsCmtsTable},
      {"20250531233823843", DeeperHub.Core.Data.Migrations.CreateBxPersonsFavoritesTrackTable},
      {"20250531233823845", DeeperHub.Core.Data.Migrations.CreateBxPersonsMetaKeywordsTable},
      {"20250531233823848", DeeperHub.Core.Data.Migrations.CreateBxPersonsMetaLocationsTable},
      {"20250531233823851", DeeperHub.Core.Data.Migrations.CreateBxPersonsMetaMentionsTable},
      {"20250531233823854", DeeperHub.Core.Data.Migrations.CreateBxPersonsPicturesResizedTable},
      {"20250531233823857", DeeperHub.Core.Data.Migrations.CreateBxPersonsPicturesTable},
      {"20250531233823863", DeeperHub.Core.Data.Migrations.CreateBxPersonsReportsTrackTable},
      {"20250531233823869", DeeperHub.Core.Data.Migrations.CreateBxPersonsScoresTrackTable},
      {"20250531233823872", DeeperHub.Core.Data.Migrations.CreateBxPersonsSkillsTable},
      {"20250531233823874", DeeperHub.Core.Data.Migrations.CreateBxPersonsViewsTrackTable},
      {"20250531233823878", DeeperHub.Core.Data.Migrations.CreateBxPersonsVotesTrackTable},
      {"20250531233823880", DeeperHub.Core.Data.Migrations.CreateDeeperArticlesCategoriesTable},
      {"20250531233823882", DeeperHub.Core.Data.Migrations.CreateDeeperArticlesEntriesTable},
      {"20250531233823886", DeeperHub.Core.Data.Migrations.CreateDeeperArticlesTable},
      {"20250531233823891", DeeperHub.Core.Data.Migrations.CreateDeeperArticlesTagsTable},
      {"20250531233823895", DeeperHub.Core.Data.Migrations.CreateDeeperArticlesTagsToEntriesTable},
      {"20250531233823898", DeeperHub.Core.Data.Migrations.CreateDeeperArticlesToCategoriesTable},
      {"20250531233823900", DeeperHub.Core.Data.Migrations.CreateDeeperArticleCategoriesTable},
      {"20250531233823902", DeeperHub.Core.Data.Migrations.CreateDeeperEventsTable},
      {"20250531233823906", DeeperHub.Core.Data.Migrations.CreateDeeperEventsToCategoriesTable},
      {"20250531233823910", DeeperHub.Core.Data.Migrations.CreateDeeperEventCategoriesTable},
      {"20250531233823917", DeeperHub.Core.Data.Migrations.CreateDeeperEventRsvpsTable},
      {"20250531233823920", DeeperHub.Core.Data.Migrations.CreateDeeperForumsTable},
      {"20250531233823923", DeeperHub.Core.Data.Migrations.CreateDeeperForumCategoriesTable},
      {"20250531233823926", DeeperHub.Core.Data.Migrations.CreateDeeperForumPostsTable},
      {"20250531233823929", DeeperHub.Core.Data.Migrations.CreateDeeperForumReadTopicsTable},
      {"20250531233823932", DeeperHub.Core.Data.Migrations.CreateDeeperForumSubscriptionsTable},
      {"20250531233823937", DeeperHub.Core.Data.Migrations.CreateDeeperForumTopicsTable},
      {"20250531233823943", DeeperHub.Core.Data.Migrations.CreateDeeperGroupsTable},
      {"20250531233823946", DeeperHub.Core.Data.Migrations.CreateDeeperGroupContentPostsTable},
      {"20250531233823949", DeeperHub.Core.Data.Migrations.CreateDeeperGroupMembersTable},
      {"20250531233823952", DeeperHub.Core.Data.Migrations.CreateDeeperAlbumPhotosTable},
      {"20250531233823956", DeeperHub.Core.Data.Migrations.CreateDeeperPhotoAlbumsTable},
      {"20250531233823960", DeeperHub.Core.Data.Migrations.CreateDeeperPollsTable},
      {"20250531233823970", DeeperHub.Core.Data.Migrations.CreateDeeperPollOptionsTable},
      {"20250531233823977", DeeperHub.Core.Data.Migrations.CreateDeeperPollVotesTable},
      {"20250531233823980", DeeperHub.Core.Data.Migrations.CreateDeeperFilesTable},
      {"20250531233823983", DeeperHub.Core.Data.Migrations.CreateSysFilesTable},
      {"20250531233823986", DeeperHub.Core.Data.Migrations.CreateSysObjectsStorageTable},
      {"20250531233823997", DeeperHub.Core.Data.Migrations.CreateSysStorageGhostsTable},
      {"20250531233824003", DeeperHub.Core.Data.Migrations.CreateSysStorageTokensTable},
      {"20250531233824010", DeeperHub.Core.Data.Migrations.CreateSysStorageUserQuotasTable},
      {"20250531233824026", DeeperHub.Core.Data.Migrations.CreateSysFormDisplaysTable},
      {"20250531233824034", DeeperHub.Core.Data.Migrations.CreateSysFormDisplayInputsTable},
      {"20250531233824040", DeeperHub.Core.Data.Migrations.CreateSysFormInputsTable},
      {"20250531233824053", DeeperHub.Core.Data.Migrations.CreateSysFormPreListsTable},
      {"20250531233824059", DeeperHub.Core.Data.Migrations.CreateSysFormPreValuesTable},
      {"20250531233824065", DeeperHub.Core.Data.Migrations.CreateSysObjectsFormTable},
      {"20250531233824068", DeeperHub.Core.Data.Migrations.CreateSysGridActionsTable},
      {"20250531233824074", DeeperHub.Core.Data.Migrations.CreateSysGridFieldsTable},
      {"20250531233824084", DeeperHub.Core.Data.Migrations.CreateSysObjectsGridTable},
      {"20250531233824088", DeeperHub.Core.Data.Migrations.CreateDeeperCommentsTable},
      {"20250531233824091", DeeperHub.Core.Data.Migrations.CreateDeeperCommentVotesTrackTable},
      {"20250531233824095", DeeperHub.Core.Data.Migrations.CreateExampleModuleCmtsTable},
      {"20250531233824101", DeeperHub.Core.Data.Migrations.CreateSysCmtsIdsTable},
      {"20250531233824106", DeeperHub.Core.Data.Migrations.CreateSysObjectsCmtsTable},
      {"20250531233824110", DeeperHub.Core.Data.Migrations.CreateExampleFavoritesTrackTable},
      {"20250531233824116", DeeperHub.Core.Data.Migrations.CreateSysObjectsFavoriteTable},
      {"20250531233824118", DeeperHub.Core.Data.Migrations.CreateExampleReactionsSummaryTable},
      {"20250531233824123", DeeperHub.Core.Data.Migrations.CreateExampleReactionsTrackTable},
      {"20250531233824127", DeeperHub.Core.Data.Migrations.CreateGenericReactionsSummaryTable},
      {"20250531233824132", DeeperHub.Core.Data.Migrations.CreateGenericReactionsTrackTable},
      {"20250531233824136", DeeperHub.Core.Data.Migrations.CreateSysObjectsReactionTable},
      {"20250531233824140", DeeperHub.Core.Data.Migrations.CreateBxPersonsReportsTable},
      {"20250531233824144", DeeperHub.Core.Data.Migrations.CreateExampleReportsSummaryTable},
      {"20250531233824149", DeeperHub.Core.Data.Migrations.CreateExampleReportsTrackTable},
      {"20250531233824152", DeeperHub.Core.Data.Migrations.CreateSysObjectsReportTable},
      {"20250531233824155", DeeperHub.Core.Data.Migrations.CreateBxPersonsScoresTable},
      {"20250531233824159", DeeperHub.Core.Data.Migrations.CreateExampleScoresSummaryTable},
      {"20250531233824163", DeeperHub.Core.Data.Migrations.CreateExampleScoresTrackTable},
      {"20250531233824167", DeeperHub.Core.Data.Migrations.CreateSysObjectsScoreTable},
      {"20250531233824171", DeeperHub.Core.Data.Migrations.CreateBxPersonsVotesTable},
      {"20250531233824175", DeeperHub.Core.Data.Migrations.CreateExampleVotesSummaryTable},
      {"20250531233824179", DeeperHub.Core.Data.Migrations.CreateExampleVotesTrackTable},
      {"20250531233824185", DeeperHub.Core.Data.Migrations.CreateSysObjectsVoteTable},
      {"20250531233824190", DeeperHub.Core.Data.Migrations.CreateSysMenuItemsTable},
      {"20250531233824195", DeeperHub.Core.Data.Migrations.CreateSysMenuSetsTable},
      {"20250531233824200", DeeperHub.Core.Data.Migrations.CreateSysMenuTemplatesTable},
      {"20250531233824204", DeeperHub.Core.Data.Migrations.CreateSysObjectsMenuTable},
      {"20250531233824208", DeeperHub.Core.Data.Migrations.CreateSysObjectsPageTable},
      {"20250531233824211", DeeperHub.Core.Data.Migrations.CreateSysPagesBlocksDataTable},
      {"20250531233824213", DeeperHub.Core.Data.Migrations.CreateSysPagesBlocksTable},
      {"20250531233824216", DeeperHub.Core.Data.Migrations.CreateSysPagesDesignBoxesTable},
      {"20250531233824220", DeeperHub.Core.Data.Migrations.CreateSysPagesLayoutsTable},
      {"20250531233824222", DeeperHub.Core.Data.Migrations.CreateSysPagesTypesTable},
      {"20250531233824226", DeeperHub.Core.Data.Migrations.CreateSysCronJobsTable},
      {"20250531233824230", DeeperHub.Core.Data.Migrations.CreateSysAccountsTable},
      {"20250531233824234", DeeperHub.Core.Data.Migrations.CreateSysAclActionsTable},
      {"20250531233824242", DeeperHub.Core.Data.Migrations.CreateSysAclActionsTrackTable},
      {"20250531233824247", DeeperHub.Core.Data.Migrations.CreateSysAclLevelsMembersTable},
      {"20250531233824255", DeeperHub.Core.Data.Migrations.CreateSysAclLevelsTable},
      {"20250531233824267", DeeperHub.Core.Data.Migrations.CreateSysAclMatrixTable},
      {"20250531233824272", DeeperHub.Core.Data.Migrations.CreateSysLocalizationCategoriesTable},
      {"20250531233824279", DeeperHub.Core.Data.Migrations.CreateSysLocalizationKeysTable},
      {"20250531233824285", DeeperHub.Core.Data.Migrations.CreateSysLocalizationLanguagesTable},
      {"20250531233824292", DeeperHub.Core.Data.Migrations.CreateSysLocalizationStringsTable},
      {"20250531233824295", DeeperHub.Core.Data.Migrations.CreateSysModulesTable},
      {"20250531233824300", DeeperHub.Core.Data.Migrations.CreateSysOptionsCategoriesTable},
      {"20250531233824329", DeeperHub.Core.Data.Migrations.CreateSysOptionsMixes2OptionsTable},
      {"20250531233824332", DeeperHub.Core.Data.Migrations.CreateSysOptionsMixesTable},
      {"20250531233824335", DeeperHub.Core.Data.Migrations.CreateSysOptionsTable},
      {"20250531233824339", DeeperHub.Core.Data.Migrations.CreateSysOptionsTypesTable},
      {"20250531233824342", DeeperHub.Core.Data.Migrations.CreateSysPermalinksTable},
      {"20250531233824345", DeeperHub.Core.Data.Migrations.CreateSysRewriteRulesTable},
      {"20250531233824354", DeeperHub.Core.Data.Migrations.CreateSysStdPagesTable},
      {"20250531233824359", DeeperHub.Core.Data.Migrations.CreateSysStdPagesWidgetsTable},
      {"20250531233824363", DeeperHub.Core.Data.Migrations.CreateSysStdRolesActions2RolesTable},
      {"20250531233824368", DeeperHub.Core.Data.Migrations.CreateSysStdRolesActionsTable},
      {"20250531233824371", DeeperHub.Core.Data.Migrations.CreateSysStdRolesMembersTable},
      {"20250531233824380", DeeperHub.Core.Data.Migrations.CreateSysStdRolesTable},
      {"20250531233824386", DeeperHub.Core.Data.Migrations.CreateSysStdWidgetsBookmarksTable},
      {"20250531233824391", DeeperHub.Core.Data.Migrations.CreateSysStdWidgetsTable}
    ]

    Logger.debug("Migrações disponíveis: #{inspect(migrations)}", module: __MODULE__)
    {:ok, migrations}
  end

  @doc """
  Filtra as migrações pendentes, comparando as migrações disponíveis com as já aplicadas.

  Retorna uma lista de tuplas `{version, module}` com as migrações pendentes.
  """
  @spec filter_pending_migrations([{String.t(), module()}], [String.t()]) :: [{String.t(), module()}]
  def filter_pending_migrations(available_migrations, applied_versions) do
    pending = Enum.filter(available_migrations, fn {version, _module} ->
      not Enum.member?(applied_versions, version)
    end)

    Logger.info("Migrações pendentes: #{length(pending)}", module: __MODULE__)
    pending
  end

  @doc """
  Aplica as migrações pendentes em ordem crescente de versão.

  Retorna `:ok` se todas as migrações foram aplicadas com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec apply_migrations([{String.t(), module()}]) :: :ok | {:error, any()}
  def apply_migrations([]) do
    Logger.info("Nenhuma migração pendente para aplicar.", module: __MODULE__)
    :ok
  end

  def apply_migrations(pending_migrations) do
    # Ordena as migrações por versão
    sorted_migrations = Enum.sort_by(pending_migrations, fn {version, _} -> version end)

    Enum.reduce_while(sorted_migrations, :ok, fn {version, module}, _acc ->
      Logger.info("Aplicando migração #{version} (#{inspect(module)})...", module: __MODULE__)

      result = Repo.transaction(fn _conn ->
        result_of_up = apply(module, :up, [])
        case result_of_up do
          success_indicator when success_indicator == :ok or 
                                 (is_tuple(success_indicator) and 
                                  elem(success_indicator, 0) == :ok and 
                                  tuple_size(success_indicator) == 2) ->
            # Função 'up' da migração executada com sucesso
            timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
            insert_sql = "INSERT INTO schema_migrations (version, inserted_at) VALUES (?, ?);"
            case Repo.execute(insert_sql, [version, timestamp]) do
              {:ok, _} -> 
                :ok # Indica sucesso para a função da transação
              {:error, reason_insert} -> 
                Logger.error("Falha ao registrar migração #{version} (#{inspect(module)}) na tabela schema_migrations: #{inspect(reason_insert)}", module: __MODULE__)
                {:error, {:schema_migrations_insert_failed, version, module, reason_insert}}
            end
          {:error, reason_up} -> # Função 'up' da migração retornou um erro
            Logger.error("Função up da migração #{version} (#{inspect(module)}) retornou erro: #{inspect(reason_up)}", module: __MODULE__)
            {:error, {:migration_up_failed, version, module, reason_up}}
          unexpected_result ->
            Logger.error("Resultado inesperado da função up da migração #{version} (#{inspect(module)}): #{inspect(unexpected_result)}", module: __MODULE__)
            {:error, {:unexpected_migration_result, version, module, unexpected_result}}
        end
      end)

      case result do
        {:ok, :ok} ->
          Logger.info("Migração #{version} aplicada com sucesso.", module: __MODULE__)
          {:cont, :ok}
        {:error, reason} ->
          Logger.error("Falha ao aplicar migração #{version}: #{inspect(reason)}", module: __MODULE__)
          {:halt, {:error, reason}}
      end
    end)
  end
end
