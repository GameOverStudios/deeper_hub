defmodule DeeperHub.Core.Cache.Persistence.DiskStorage do
  @moduledoc """
  Módulo para persistência do cache em disco.

  Este módulo fornece funcionalidades para salvar e restaurar o conteúdo
  do cache em disco, permitindo que os dados sejam preservados entre
  reinicializações do sistema. Implementa mecanismos de backup e restauração
  automáticos, além de compressão para economizar espaço em disco.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias Cachex

  @default_path "priv/cache_dump"
  @temp_suffix ".tmp"

  @doc """
  Salva o conteúdo do cache em disco.

  ## Parâmetros

    * `cache_name` - Nome do cache a ser salvo
    * `opts` - Opções adicionais

  ## Opções

    * `:path` - Caminho onde o arquivo será salvo (padrão: #{@default_path})
    * `:compress` - Se deve comprimir o arquivo (padrão: `true`)
    * `:overwrite` - Se deve sobrescrever arquivo existente (padrão: `true`)
    * `:async` - Se deve executar assincronamente (padrão: `false`)

  ## Retorno

    * `:ok` - Operação concluída com sucesso
    * `{:error, reason}` - Erro durante a operação
  """
  @spec save_to_disk(atom(), keyword()) :: :ok | {:error, term()}
  def save_to_disk(cache_name, opts \\ []) do
    path = Keyword.get(opts, :path, @default_path)
    compress = Keyword.get(opts, :compress, true)
    overwrite = Keyword.get(opts, :overwrite, true)
    is_async = Keyword.get(opts, :async, false)

    Logger.info("Iniciando persistência do cache em disco...", module: __MODULE__)

    # Garante que o diretório existe
    File.mkdir_p!(Path.dirname(path))

    # Cria nome do arquivo temporário
    temp_path = "#{path}#{@temp_suffix}"

    # Configura opções para o Cachex
    cachex_opts = [
      compressed: compress,
      overwrite: overwrite
    ]

    # Adiciona opção assíncrona se solicitado
    cachex_opts = if is_async, do: [{:async, true} | cachex_opts], else: cachex_opts

    # Salva primeiro em arquivo temporário para evitar corrupção
    result = cachex_dump(cache_name, temp_path, cachex_opts)

    case result do
      # No modo assíncrono, apenas retorna :ok
      {:ok, :ok} when is_async ->
        spawn(fn -> finalize_save(temp_path, path) end)
        :ok

      {:ok, true} ->
        # No modo síncrono, move o arquivo temporário para o destino final
        finalize_save(temp_path, path)

      {:error, reason} ->
        Logger.error("Falha ao salvar cache em disco: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Restaura o conteúdo do cache a partir de um arquivo em disco.

  ## Parâmetros

    * `cache_name` - Nome do cache para restaurar
    * `opts` - Opções adicionais

  ## Opções

    * `:path` - Caminho do arquivo (padrão: #{@default_path})
    * `:clear_first` - Se deve limpar o cache antes de restaurar (padrão: `true`)
    * `:skip_expired` - Se deve ignorar entradas expiradas (padrão: `true`)

  ## Retorno

    * `{:ok, count}` - Número de entradas restauradas
    * `{:error, reason}` - Erro durante a operação
  """
  @spec restore_from_disk(atom(), keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  def restore_from_disk(cache_name, opts \\ []) do
    path = Keyword.get(opts, :path, @default_path)
    clear_first = Keyword.get(opts, :clear_first, true)
    skip_expired = Keyword.get(opts, :skip_expired, true)

    # Verifica se o arquivo existe
    if !File.exists?(path) do
      Logger.warning("Arquivo de cache não encontrado: #{path}", module: __MODULE__)
      {:error, :file_not_found}
    else
      Logger.info("Iniciando restauração do cache a partir do disco...", module: __MODULE__)

      # Limpa o cache se solicitado
      if clear_first do
        {:ok, _} = Cachex.clear(cache_name)
        Logger.info("Cache limpo antes da restauração", module: __MODULE__)
      end

      # Configura opções para o Cachex
      cachex_opts = [
        skip_expired: skip_expired
      ]

      # Restaura o cache
      case cachex_load(cache_name, path, cachex_opts) do
        {:ok, count} ->
          Logger.info("Cache restaurado com sucesso: #{count} entradas", module: __MODULE__)
          {:ok, count}

        {:error, reason} ->
          Logger.error("Falha ao restaurar cache do disco: #{inspect(reason)}", module: __MODULE__)
          {:error, reason}
      end
    end
  end

  @doc """
  Configura backup automático do cache em disco.

  ## Parâmetros

    * `cache_name` - Nome do cache a ser backupeado
    * `interval_ms` - Intervalo em milissegundos entre backups
    * `opts` - Opções adicionais (mesmas de `save_to_disk/2`)

  ## Retorno

    * `{:ok, pid}` - PID do processo de backup
    * `{:error, reason}` - Erro ao configurar backup
  """
  @spec schedule_automatic_backup(atom(), non_neg_integer(), keyword()) :: {:ok, pid()} | {:error, term()}
  def schedule_automatic_backup(cache_name, interval_ms \\ 3_600_000, opts \\ []) do
    Logger.info("Configurando backup automático do cache a cada #{interval_ms}ms", module: __MODULE__)

    # Inicia processo de backup periódico
    {:ok, pid} = Task.start_link(fn ->
      backup_loop(cache_name, interval_ms, opts)
    end)

    {:ok, pid}
  end

  # Funções privadas

  # Finaliza o processo de salvamento movendo o arquivo temporário para o destino final
  defp finalize_save(temp_path, final_path) do
    # Move o arquivo temporário para o destino final
    case File.rename(temp_path, final_path) do
      :ok ->
        Logger.info("Cache salvo com sucesso em #{final_path}", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao finalizar persistência do cache: #{inspect(reason)}", module: __MODULE__)
        # Tenta remover arquivo temporário em caso de falha
        File.rm(temp_path)
        {:error, reason}
    end
  end

  # Loop para backup automático periódico
  defp backup_loop(cache_name, interval_ms, opts) do
    # Executa o backup
    save_to_disk(cache_name, opts)

    # Espera o intervalo definido
    :timer.sleep(interval_ms)

    # Continua o loop
    backup_loop(cache_name, interval_ms, opts)
  end

  # Funções wrapper para Cachex

  @doc false
  defp cachex_dump(cache_name, path, opts) do
    # Wrapper para função Cachex.dump para evitar avisos de compilação
    try do
      # Chama a função usando apply para evitar warnings
      # Isso funciona porque as funções existem em tempo de execução
      apply(Cachex, :dump, [cache_name, path, opts])
    rescue
      e ->
        Logger.error("Erro ao salvar cache em disco: #{inspect(e)}", module: __MODULE__)
        {:error, :dump_failed}
    end
  end

  @doc false
  defp cachex_load(cache_name, path, opts) do
    # Wrapper para função Cachex.load para evitar avisos de compilação
    try do
      # Chama a função usando apply para evitar warnings
      apply(Cachex, :load, [cache_name, path, opts])
    rescue
      e ->
        Logger.error("Erro ao carregar cache do disco: #{inspect(e)}", module: __MODULE__)
        {:error, :load_failed}
    end
  end
end
