defmodule Deeper_Hub.Core.Data.RepositoryCrud do
  @moduledoc """
  Módulo para operações CRUD (Create, Read, Update, Delete) no repositório.
  
  Este módulo fornece funções para realizar operações básicas de banco de dados,
  como inserção, consulta, atualização e exclusão de registros, além de funções
  para listar e buscar registros com condições específicas.
  
  Utiliza o pool de conexões gerenciado pela biblioteca DBConnection para otimizar
  o uso de recursos e melhorar o desempenho das operações de banco de dados.
  
  ## Telemetria e Métricas
  
  Este módulo emite eventos de telemetria para todas as operações CRUD, permitindo
  o monitoramento detalhado do desempenho e comportamento do sistema. Os eventos
  seguem o formato `[:deeper_hub, :core, :data, :repository, :operation]`.
  
  ## CircuitBreaker
  
  Todas as operações de banco de dados são protegidas por um CircuitBreaker para
  evitar sobrecarga do banco de dados em situações de falha. Quando o circuito está
  aberto, as operações de leitura tentam usar o cache como fallback.
  
  ## Cache
  
  Operações de leitura (get, list, find) utilizam cache para melhorar a performance
  e reduzir a carga no banco de dados. Operações de escrita (insert, update, delete)
  invalidam automaticamente as entradas relevantes no cache.
  
  ## Eventos
  
  O módulo publica eventos para operações de escrita bem-sucedidas, permitindo que
  outros componentes do sistema reajam a mudanças nos dados.
  """

  import Ecto.Query
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.RepositoryCore
  alias Deeper_Hub.Core.Data.DBConnection.DBConnectionFacade, as: DBConn
  alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CB
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  alias Deeper_Hub.Core.EventBus.EventBusFacade, as: EventBus
  
  # Nome do serviço para o CircuitBreaker
  @db_service :database_service
  
  # Configurações padrão para o CircuitBreaker
  @circuit_breaker_config %{
    failure_threshold: 5,      # Número de falhas antes de abrir o circuito
    reset_timeout_ms: 30_000  # Tempo para resetar o circuito (30 segundos)
  }
  
  # TTL padrão para itens em cache (1 hora)
  @default_cache_ttl 3_600_000
  
  # Inicializa o CircuitBreaker quando o módulo é carregado
  @on_load :init_circuit_breaker
  
  @doc false
  def init_circuit_breaker do
    # Registra o CircuitBreaker para operações de banco de dados
    CB.register(@db_service, @circuit_breaker_config)
    :ok
  end

  @doc """
  Executa uma função dentro de uma transação do banco de dados.
  
  Utiliza o pool de conexões gerenciado pela biblioteca DBConnection para
  garantir o uso eficiente das conexões e o isolamento das operações.
  
  ## Parâmetros
  
    - `fun`: Função a ser executada dentro da transação
    - `opts`: Opções para a transação
  
  ## Retorno
  
    - `{:ok, result}`: Resultado da função se a transação for bem-sucedida
    - `{:error, reason}`: Erro se a transação falhar
  
  ## Exemplo
  
  ```elixir
  RepositoryCrud.transaction(fn ->
    {:ok, user} = RepositoryCrud.insert(User, %{name: "Alice"})
    {:ok, _} = RepositoryCrud.insert(Log, %{action: "user_created", user_id: user.id})
    user
  end)
  ```
  """
  @spec transaction((-> any()), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def transaction(fun, opts \\ []) do
    start_time = System.monotonic_time()
    
    Logger.debug("Iniciando transação", %{
      module: __MODULE__
    })
    
    # Usa o DBConnectionFacade para gerenciar a transação
    result = DBConn.transaction(fun, opts)
    
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      {:ok, value} ->
        Logger.debug("Transação concluída com sucesso", %{
          module: __MODULE__,
          duration_ms: duration_ms
        })
        
        {:ok, value}
        
      {:error, reason} ->
        Logger.error("Erro na transação", %{
          module: __MODULE__,
          reason: inspect(reason),
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
  end

  @doc """
  Insere um novo registro no banco de dados.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `attrs`: Os atributos para inserir

  ## Retorno

    - `{:ok, struct}` se a inserção for bem-sucedida
    - `{:error, changeset}` em caso de falha
  """
  @spec insert(module(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, term()}
  def insert(schema, attrs) do
    # Executa a operação com telemetria
    :telemetry.span(
      [:deeper_hub, :core, :data, :repository, :insert],
      %{schema: schema},
      fn ->
        # Registra métrica de início da operação
        Metrics.increment("deeper_hub.core.data.repository.insert.started", %{
          schema: inspect(schema)
        })
        
        # Registra a operação nos logs
        Logger.debug("Inserindo registro", %{
          module: __MODULE__,
          schema: schema,
          attrs: attrs
        })

        # Cria um changeset para validar os dados
        changeset = struct(schema) |> Ecto.Changeset.cast(attrs, schema.__schema__(:fields))

        # Verifica se o changeset é válido
        result = if changeset.valid? do
          # Executa a operação protegida pelo CircuitBreaker
          CB.run(
            @db_service,
            fn ->
              # Insere no banco de dados
              case Repo.insert(changeset) do
                {:ok, record} ->
                  # Registro inserido com sucesso
                  
                  # Publica evento de inserção bem-sucedida
                  EventBus.publish(
                    :repository_record_inserted,
                    %{
                      schema: schema,
                      id: record.id,
                      timestamp: DateTime.utc_now()
                    }
                  )
                  
                  # Registra métrica de sucesso na inserção
                  Metrics.increment("deeper_hub.core.data.repository.insert.success", %{
                    schema: inspect(schema)
                  })
                  
                  {:ok, record}

                {:error, changeset} ->
                  # Falha ao inserir registro
                  Logger.warning("Falha ao inserir registro devido a erros de validação", %{
                    module: __MODULE__,
                    schema: schema,
                    errors: inspect(changeset.errors)
                  })
                  
                  # Registra métrica de falha na inserção
                  Metrics.increment("deeper_hub.core.data.repository.insert.validation_error", %{
                    schema: inspect(schema)
                  })
                  
                  {:error, changeset}
              end
            end,
            fn _error ->
              # Fallback em caso de falha no banco de dados ou circuito aberto
              Logger.error("Falha ao inserir registro devido a indisponibilidade do banco de dados", %{
                module: __MODULE__,
                schema: schema,
                reason: "circuit_open_or_db_error"
              })
              
              # Registra métrica de falha na inserção
              Metrics.increment("deeper_hub.core.data.repository.insert.failed", %{
                schema: inspect(schema),
                reason: "circuit_open_or_db_error"
              })
              
              {:error, :service_unavailable}
            end
          )
        else
          # Changeset inválido
          Logger.debug("Changeset inválido", %{
            module: __MODULE__,
            schema: schema,
            errors: inspect(changeset.errors)
          })
          
          # Registra métrica de falha na inserção devido a validação
          Metrics.increment("deeper_hub.core.data.repository.insert.invalid_data", %{
            schema: inspect(schema)
          })

          # Retorna o erro
          {:error, changeset}
        end
        
        # Prepara metadados para telemetria
        metadata = %{
          schema: schema,
          result: case result do
            {:ok, record} -> %{success: true, id: record.id}
            {:error, %Ecto.Changeset{}} -> %{success: false, reason: :validation_error}
            {:error, reason} -> %{success: false, reason: reason}
          end
        }
        
        # Retorna o resultado e os metadados para telemetria
        {result, metadata}
      end
    )
  end

  @doc """
  Busca um registro pelo ID.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser buscado

  ## Retorno

    - `{:ok, struct}` se o registro for encontrado
    - `{:error, :not_found}` se o registro não for encontrado
  """
  @spec get(module(), term()) :: {:ok, Ecto.Schema.t()} | {:error, :not_found} | {:error, term()}
  def get(schema, id) do
    # Executa a operação com telemetria
    :telemetry.span(
      [:deeper_hub, :core, :data, :repository, :get],
      %{schema: schema, id: id},
      fn ->
        # Registra métrica de início da operação
        Metrics.increment("deeper_hub.core.data.repository.get.started", %{
          schema: inspect(schema)
        })
        
        # Registra a operação nos logs
        Logger.debug("Buscando registro por ID", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })
        
        # Tenta obter do cache primeiro
        cache_result = RepositoryCore.get_from_cache(schema, id)
        
        result = case cache_result do
          {:ok, record} ->
            # Registro encontrado no cache
            Logger.debug("Registro encontrado no cache", %{
              module: __MODULE__,
              schema: schema,
              id: id
            })
            
            # Registra métrica de cache hit
            Metrics.increment("deeper_hub.core.data.repository.cache.hit", %{
              schema: inspect(schema)
            })
            
            {:ok, record}
            
          :not_found ->
            # Registro não encontrado no cache, busca no banco de dados
            Logger.debug("Registro não encontrado no cache, buscando no banco de dados", %{
              module: __MODULE__,
              schema: schema,
              id: id
            })
            
            # Registra métrica de cache miss
            Metrics.increment("deeper_hub.core.data.repository.cache.miss", %{
              schema: inspect(schema)
            })
            
            # Executa a operação protegida pelo CircuitBreaker
            CB.run(
              @db_service,
              fn ->
                # Busca o registro no banco de dados
                case Repo.get(schema, id) do
                  nil ->
                    # Registro não encontrado no banco de dados
                    Logger.debug("Registro não encontrado no banco de dados", %{
                      module: __MODULE__,
                      schema: schema,
                      id: id
                    })
                    
                    {:error, :not_found}
                    
                  record ->
                    # Armazena o registro no cache para futuras consultas
                    RepositoryCore.put_in_cache(schema, id, record)
                    
                    # Registra métrica de sucesso na busca
                    Metrics.increment("deeper_hub.core.data.repository.get.success", %{
                      schema: inspect(schema)
                    })

                    # Registro encontrado no banco de dados
                    {:ok, record}
                end
              end,
              fn _error ->
                # Fallback em caso de falha no banco de dados ou circuito aberto
                Logger.warning("Falha ao buscar registro no banco de dados", %{
                  module: __MODULE__,
                  schema: schema,
                  id: id,
                  reason: "circuit_open_or_db_error"
                })
                
                # Registra métrica de falha na busca
                Metrics.increment("deeper_hub.core.data.repository.get.failed", %{
                  schema: inspect(schema),
                  reason: "circuit_open_or_db_error"
                })
                
                {:error, :service_unavailable}
              end
            )
        end
        
        # Registra o resultado nos logs
        case result do
          {:ok, _} ->
            Logger.debug("Registro encontrado", %{
              module: __MODULE__,
              schema: schema,
              id: id
            })
            
          {:error, :not_found} ->
            Logger.debug("Registro não encontrado", %{
              module: __MODULE__,
              schema: schema,
              id: id
            })
            
          {:error, reason} ->
            Logger.error("Erro ao buscar registro", %{
              module: __MODULE__,
              schema: schema,
              id: id,
              reason: reason
            })
        end
        
        # Prepara metadados para telemetria
        metadata = %{
          schema: schema,
          id: id,
          result: case result do
            {:ok, _} -> :success
            {:error, :not_found} -> :not_found
            {:error, _} -> :error
          end
        }
        
        # Retorna o resultado e os metadados para telemetria
        {result, metadata}
      end
    )
  end

  @doc """
  Atualiza um registro existente.

  ## Parâmetros

    - `struct`: A struct a ser atualizada
    - `attrs`: Os atributos para atualizar

  ## Retorno

    - `{:ok, struct}` se a atualização for bem-sucedida
    - `{:error, changeset}` em caso de falha
  """
  @spec update(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, term()}
  def update(struct, attrs) do
    schema = struct.__struct__
    id = struct.id
    
    # Executa a operação com telemetria
    :telemetry.span(
      [:deeper_hub, :core, :data, :repository, :update],
      %{schema: schema, id: id},
      fn ->
        # Registra métrica de início da operação
        Metrics.increment("deeper_hub.core.data.repository.update.started", %{
          schema: inspect(schema)
        })
        
        # Registra a operação nos logs
        Logger.debug("Atualizando registro", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          attrs: attrs
        })

        # Cria um changeset para validar os dados
        changeset = schema.changeset(struct, attrs)

        # Verifica se o changeset é válido
        result = if changeset.valid? do
          # Executa a operação protegida pelo CircuitBreaker
          CB.run(
            @db_service,
            fn ->
              # Atualiza no banco de dados
              case Repo.update(changeset) do
                {:ok, updated_record} ->
                  # Registro atualizado com sucesso
                  
                  # Atualiza o cache
                  RepositoryCore.put_in_cache(schema, id, updated_record)
                  
                  # Publica evento de atualização bem-sucedida
                  EventBus.publish(
                    :repository_record_updated,
                    %{
                      schema: schema,
                      id: id,
                      timestamp: DateTime.utc_now()
                    }
                  )
                  
                  # Registra métrica de sucesso na atualização
                  Metrics.increment("deeper_hub.core.data.repository.update.success", %{
                    schema: inspect(schema)
                  })
                  
                  {:ok, updated_record}

                {:error, changeset} ->
                  # Falha ao atualizar registro
                  Logger.warning("Falha ao atualizar registro devido a erros de validação", %{
                    module: __MODULE__,
                    schema: schema,
                    id: id,
                    errors: inspect(changeset.errors)
                  })
                  
                  # Registra métrica de falha na atualização
                  Metrics.increment("deeper_hub.core.data.repository.update.validation_error", %{
                    schema: inspect(schema)
                  })
                  
                  {:error, changeset}
              end
            end,
            fn _error ->
              # Fallback em caso de falha no banco de dados ou circuito aberto
              Logger.error("Falha ao atualizar registro devido a indisponibilidade do banco de dados", %{
                module: __MODULE__,
                schema: schema,
                id: id,
                reason: "circuit_open_or_db_error"
              })
              
              # Registra métrica de falha na atualização
              Metrics.increment("deeper_hub.core.data.repository.update.failed", %{
                schema: inspect(schema),
                reason: "circuit_open_or_db_error"
              })
              
              {:error, :service_unavailable}
            end
          )
        else
          # Changeset inválido
          Logger.debug("Changeset inválido para atualização", %{
            module: __MODULE__,
            schema: schema,
            id: id,
            errors: inspect(changeset.errors)
          })
          
          # Registra métrica de falha na atualização devido a validação
          Metrics.increment("deeper_hub.core.data.repository.update.invalid_data", %{
            schema: inspect(schema)
          })

          # Retorna o erro
          {:error, changeset}
        end
        
        # Prepara metadados para telemetria
        metadata = %{
          schema: schema,
          id: id,
          result: case result do
            {:ok, _record} -> %{success: true}
            {:error, %Ecto.Changeset{}} -> %{success: false, reason: :validation_error}
            {:error, reason} -> %{success: false, reason: reason}
          end
        }
        
        # Retorna o resultado e os metadados para telemetria
        {result, metadata}
      end
    )
  end

  @doc """
  Remove um registro existente.

  ## Parâmetros

    - `struct`: A struct a ser removida

  ## Retorno

    - `{:ok, :deleted}` se a remoção for bem-sucedida
    - `{:error, changeset}` em caso de falha
  """
  @spec delete(Ecto.Schema.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, term()}
  def delete(struct) do
    schema = struct.__struct__
    id = struct.id
    
    # Executa a operação com telemetria
    :telemetry.span(
      [:deeper_hub, :core, :data, :repository, :delete],
      %{schema: schema, id: id},
      fn ->
        # Registra métrica de início da operação
        Metrics.increment("deeper_hub.core.data.repository.delete.started", %{
          schema: inspect(schema)
        })
        
        # Registra a operação nos logs
        Logger.debug("Excluindo registro", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

        # Executa a operação protegida pelo CircuitBreaker
        result = CB.run(
          @db_service,
          fn ->
            # Exclui no banco de dados
            case Repo.delete(struct) do
              {:ok, deleted_record} ->
                # Registro excluído com sucesso
                
                # Remove do cache
                RepositoryCore.delete_from_cache(schema, id)
                
                # Publica evento de exclusão bem-sucedida
                EventBus.publish(
                  :repository_record_deleted,
                  %{
                    schema: schema,
                    id: id,
                    timestamp: DateTime.utc_now()
                  }
                )
                
                # Registra métrica de sucesso na exclusão
                Metrics.increment("deeper_hub.core.data.repository.delete.success", %{
                  schema: inspect(schema)
                })
                
                {:ok, deleted_record}

              {:error, changeset} ->
                # Falha ao excluir registro
                Logger.warning("Falha ao excluir registro devido a erros de validação", %{
                  module: __MODULE__,
                  schema: schema,
                  id: id,
                  errors: inspect(changeset.errors)
                })
                
                # Registra métrica de falha na exclusão
                Metrics.increment("deeper_hub.core.data.repository.delete.validation_error", %{
                  schema: inspect(schema)
                })
                
                {:error, changeset}
            end
          end,
          fn _error ->
            # Fallback em caso de falha no banco de dados ou circuito aberto
            Logger.error("Falha ao excluir registro devido a indisponibilidade do banco de dados", %{
              module: __MODULE__,
              schema: schema,
              id: id,
              reason: "circuit_open_or_db_error"
            })
            
            # Registra métrica de falha na exclusão
            Metrics.increment("deeper_hub.core.data.repository.delete.failed", %{
              schema: inspect(schema),
              reason: "circuit_open_or_db_error"
            })
            
            {:error, :service_unavailable}
          end
        )
        
        # Prepara metadados para telemetria
        metadata = %{
          schema: schema,
          id: id,
          result: case result do
            {:ok, _record} -> %{success: true}
            {:error, %Ecto.Changeset{}} -> %{success: false, reason: :validation_error}
            {:error, reason} -> %{success: false, reason: reason}
          end
        }
        
        # Retorna o resultado e os metadados para telemetria
        {result, metadata}
      end
    )
  end

  @doc """
  Lista todos os registros de um schema.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `opts`: Opções adicionais (como limit, offset, preload, etc.)

  ## Retorno

    - `{:ok, list}` com a lista de registros
    - `{:error, reason}` em caso de falha

  ## Exemplo

      # Listar todos os usuários
      {:ok, users} = RepositoryCrud.list(User)

      # Listar com paginação (limite de 10 registros)
      {:ok, users} = RepositoryCrud.list(User, limit: 10, offset: 0)

      # Listar com pré-carregamento de associações
      {:ok, users} = RepositoryCrud.list(User, preload: [:profile, :posts])
  """
  @spec list(module(), Keyword.t()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def list(schema, opts \\ []) do
    # Executa a operação com telemetria
    :telemetry.span(
      [:deeper_hub, :core, :data, :repository, :list],
      %{schema: schema, opts: opts},
      fn ->
        # Registra métrica de início da operação
        Metrics.increment("deeper_hub.core.data.repository.list.started", %{
          schema: inspect(schema)
        })
        
        # Registra a operação nos logs
        Logger.debug("Listando registros", %{
          module: __MODULE__,
          schema: schema,
          opts: opts
        })

        # Cria uma chave de cache para a consulta
        cache_key = "list_#{schema}_#{inspect(opts)}"

        # Verifica se os resultados estão no cache
        result = case RepositoryCore.get_from_cache(:query_cache, cache_key) do
          {:ok, records} ->
            # Registra que os resultados foram encontrados no cache
            Logger.debug("Resultados encontrados no cache", %{
              module: __MODULE__,
              schema: schema,
              cache_key: cache_key
            })
            
            # Registra métrica de cache hit
            Metrics.increment("deeper_hub.core.data.repository.cache.hit", %{
              schema: inspect(schema),
              operation: "list"
            })

            # Resultados encontrados no cache
            {:ok, records}

          :not_found ->
            # Registra métrica de cache miss
            Metrics.increment("deeper_hub.core.data.repository.cache.miss", %{
              schema: inspect(schema),
              operation: "list"
            })
            
            # Executa a operação protegida pelo CircuitBreaker
            CB.run(
              @db_service,
              fn ->
                try do
                  # Cria a query base
                  query = from(item in schema)

                  # Aplica pré-carregamento se especificado
                  query = case Keyword.get(opts, :preload) do
                    nil -> query
                    preloads -> Ecto.Query.preload(query, ^preloads)
                  end

                  # Ordenação padrão por ID ascendente se não for especificada
                  query = if Keyword.has_key?(opts, :order_by) do
                    order_by = Keyword.get(opts, :order_by, asc: :id)
                    from(item in query, order_by: ^order_by)
                  else
                    from(item in query, order_by: [asc: item.id])
                  end

                  # Aplica limit e offset se fornecidos
                  query = RepositoryCore.apply_limit_offset(query, opts)

                  # Executa a query
                  records = Repo.all(query)

                  # Armazena os resultados no cache para futuras consultas
                  # Usa um TTL menor para listas, pois podem ficar desatualizadas mais rapidamente
                  RepositoryCore.put_in_cache(:query_cache, cache_key, records, 60_000) # 1 minuto
                  
                  # Registra métrica de sucesso na listagem
                  Metrics.increment("deeper_hub.core.data.repository.list.success", %{
                    schema: inspect(schema),
                    count: length(records)
                  })

                  # Retorna os registros encontrados
                  {:ok, records}
                rescue
                  e in [UndefinedFunctionError] ->
                    # Tabela pode não existir
                    error_msg = "Tabela para schema #{inspect(schema)} não encontrada"
                    Logger.error(error_msg, %{
                      module: __MODULE__,
                      schema: schema,
                      error: e,
                      stacktrace: __STACKTRACE__
                    })
                    
                    # Registra métrica de falha na listagem
                    Metrics.increment("deeper_hub.core.data.repository.list.table_not_found", %{
                      schema: inspect(schema)
                    })

                    # Tabela não encontrada
                    {:error, :table_not_found}

                  e ->
                    # Outros erros
                    Logger.error("Falha ao listar registros", %{
                      module: __MODULE__,
                      schema: schema,
                      error: e,
                      stacktrace: __STACKTRACE__
                    })
                    
                    # Registra métrica de falha na listagem
                    Metrics.increment("deeper_hub.core.data.repository.list.error", %{
                      schema: inspect(schema)
                    })

                    # Erro ao listar registros
                    {:error, e}
                end
              end,
              fn _error ->
                # Fallback em caso de falha no banco de dados ou circuito aberto
                Logger.warning("Falha ao listar registros devido a indisponibilidade do banco de dados", %{
                  module: __MODULE__,
                  schema: schema,
                  reason: "circuit_open_or_db_error"
                })
                
                # Registra métrica de falha na listagem
                Metrics.increment("deeper_hub.core.data.repository.list.failed", %{
                  schema: inspect(schema),
                  reason: "circuit_open_or_db_error"
                })
                
                {:error, :service_unavailable}
              end
            )
        end
        
        # Prepara metadados para telemetria
        metadata = %{
          schema: schema,
          result: case result do
            {:ok, records} -> %{success: true, count: length(records)}
            {:error, reason} -> %{success: false, reason: reason}
          end
        }
        
        # Retorna o resultado e os metadados para telemetria
        {result, metadata}
      end
    )
  end

  @doc """
  Busca registros com base em condições.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `conditions`: Mapa com as condições de busca
    - `opts`: Opções adicionais (como limit, offset, preload, etc.)

  ## Retorno

    - `{:ok, list}` com a lista de registros
    - `{:error, reason}` em caso de falha

  ## Exemplo

      # Buscar usuários por nome
      {:ok, users} = RepositoryCrud.find(User, %{name: "João"})

      # Buscar com múltiplas condições
      {:ok, users} = RepositoryCrud.find(User, %{name: "João", active: true})

      # Com paginação
      {:ok, users} = RepositoryCrud.find(User, %{active: true}, limit: 10, offset: 0)
  """
  @spec find(module(), map(), Keyword.t()) :: {:ok, [Ecto.Schema.t()]} | {:error, term()}
  def find(schema, conditions, opts \\ []) do
    # Executa a operação com telemetria
    :telemetry.span(
      [:deeper_hub, :core, :data, :repository, :find],
      %{schema: schema, conditions: conditions, opts: opts},
      fn ->
        # Registra métrica de início da operação
        Metrics.increment("deeper_hub.core.data.repository.find.started", %{
          schema: inspect(schema)
        })
        
        # Registra a operação nos logs
        Logger.debug("Buscando registros", %{
          module: __MODULE__,
          schema: schema,
          conditions: conditions,
          opts: opts
        })

        # Cria uma chave de cache para a consulta
        cache_key = "find_#{schema}_#{inspect(conditions)}_#{inspect(opts)}"

        # Verifica se os resultados estão no cache
        result = case RepositoryCore.get_from_cache(:query_cache, cache_key) do
          {:ok, records} ->
            # Registra que os resultados foram encontrados no cache
            Logger.debug("Resultados encontrados no cache", %{
              module: __MODULE__,
              schema: schema,
              cache_key: cache_key
            })
            
            # Registra métrica de cache hit
            Metrics.increment("deeper_hub.core.data.repository.cache.hit", %{
              schema: inspect(schema),
              operation: "find"
            })

            # Resultados encontrados no cache
            {:ok, records}

          :not_found ->
            # Registra métrica de cache miss
            Metrics.increment("deeper_hub.core.data.repository.cache.miss", %{
              schema: inspect(schema),
              operation: "find"
            })
            
            # Executa a operação protegida pelo CircuitBreaker
            CB.run(
              @db_service,
              fn ->
                try do
                  # Constrói a query base
                  query = from(item in schema)

                  # Aplica as condições de busca
                  query = Enum.reduce(conditions, query, fn
                    {field_name, nil}, acc_query ->
                      # Busca por valores nulos
                      from(item in acc_query, where: is_nil(field(item, ^field_name)))

                    {field_name, :not_null}, acc_query ->
                      # Busca por valores não nulos
                      from(item in acc_query, where: not is_nil(field(item, ^field_name)))

                    {field_name, {:in, values}}, acc_query ->
                      # Busca por valores em uma lista (IN)
                      if is_list(values) do
                        from(item in acc_query, where: field(item, ^field_name) in ^values)
                      else
                        acc_query
                      end

                    {field_name, {:not_in, values}}, acc_query ->
                      # Exclui valores em uma lista (NOT IN)
                      if is_list(values) do
                        from(item in acc_query, where: field(item, ^field_name) not in ^values)
                      else
                        acc_query
                      end

                    {field_name, {:like, term}}, acc_query ->
                      # Busca com LIKE (case-sensitive)
                      from(item in acc_query, where: like(field(item, ^field_name), ^"%#{term}%"))

                    {field_name, {:ilike, term}}, acc_query ->
                      # Busca com ILIKE (case-insensitive)
                      from(item in acc_query, where: like(fragment("lower(?)", field(item, ^field_name)), ^String.downcase("%#{term}%")))

                    {field_name, value}, acc_query ->
                      # Igualdade simples
                      from(item in acc_query, where: field(item, ^field_name) == ^value)
                  end)

                  # Aplica pré-carregamento se especificado
                  query = case Keyword.get(opts, :preload) do
                    nil -> query
                    preloads -> Ecto.Query.preload(query, ^preloads)
                  end

                  # Ordenação padrão por ID ascendente se não for especificada
                  query = if Keyword.has_key?(opts, :order_by) do
                    order_by = Keyword.get(opts, :order_by, asc: :id)
                    from(item in query, order_by: ^order_by)
                  else
                    from(item in query, order_by: [asc: item.id])
                  end

                  # Aplica limit e offset se fornecidos
                  query = RepositoryCore.apply_limit_offset(query, opts)

                  # Executa a query
                  records = Repo.all(query)
                  
                  # Armazena os resultados no cache para futuras consultas
                  # Usa um TTL menor para buscas, pois podem ficar desatualizadas mais rapidamente
                  RepositoryCore.put_in_cache(:query_cache, cache_key, records, 60_000) # 1 minuto
                  
                  # Registra métrica de sucesso na busca
                  Metrics.increment("deeper_hub.core.data.repository.find.success", %{
                    schema: inspect(schema),
                    count: length(records)
                  })

                  # Retorna os registros encontrados
                  {:ok, records}
                rescue
                  e in [UndefinedFunctionError] ->
                    # Tabela pode não existir
                    error_msg = "Tabela para schema #{inspect(schema)} não encontrada"
                    Logger.error(error_msg, %{
                      module: __MODULE__,
                      schema: schema,
                      error: e,
                      stacktrace: __STACKTRACE__
                    })
                    
                    # Registra métrica de falha na busca
                    Metrics.increment("deeper_hub.core.data.repository.find.table_not_found", %{
                      schema: inspect(schema)
                    })

                    # Tabela não encontrada
                    {:error, :table_not_found}

                  e in [CaseClauseError] ->
                    # Condições inválidas
                    error_msg = "Condições de busca inválidas: #{inspect(conditions)}"
                    Logger.error(error_msg, %{
                      module: __MODULE__,
                      schema: schema,
                      conditions: conditions,
                      error: e,
                      stacktrace: __STACKTRACE__
                    })
                    
                    # Registra métrica de falha na busca
                    Metrics.increment("deeper_hub.core.data.repository.find.invalid_conditions", %{
                      schema: inspect(schema)
                    })

                    # Condições de busca inválidas
                    {:error, :invalid_conditions}

                  e ->
                    # Outros erros
                    Logger.error("Falha ao buscar registros", %{
                      module: __MODULE__,
                      schema: schema,
                      conditions: conditions,
                      error: e,
                      stacktrace: __STACKTRACE__
                    })
                    
                    # Registra métrica de falha na busca
                    Metrics.increment("deeper_hub.core.data.repository.find.error", %{
                      schema: inspect(schema)
                    })

                    # Erro ao buscar registros
                    {:error, e}
                end
              end,
              fn _error ->
                # Fallback em caso de falha no banco de dados ou circuito aberto
                Logger.warning("Falha ao buscar registros devido a indisponibilidade do banco de dados", %{
                  module: __MODULE__,
                  schema: schema,
                  reason: "circuit_open_or_db_error"
                })
                
                # Registra métrica de falha na busca
                Metrics.increment("deeper_hub.core.data.repository.find.failed", %{
                  schema: inspect(schema),
                  reason: "circuit_open_or_db_error"
                })
                
                {:error, :service_unavailable}
              end
            )
        end
        
        # Prepara metadados para telemetria
        metadata = %{
          schema: schema,
          result: case result do
            {:ok, records} -> %{success: true, count: length(records)}
            {:error, reason} -> %{success: false, reason: reason}
          end
        }
        
        # Retorna o resultado e os metadados para telemetria
        {result, metadata}
      end
    )
  end
end
