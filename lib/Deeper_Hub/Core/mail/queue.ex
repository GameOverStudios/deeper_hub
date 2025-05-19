defmodule DeeperHub.Core.Mail.Queue do
  @moduledoc """
  Módulo responsável pelo gerenciamento de filas de emails no DeeperHub.
  
  Este módulo implementa uma fila persistente para emails, garantindo que
  nenhuma mensagem seja perdida em caso de falha do sistema. Utiliza uma
  tabela ETS para armazenamento em memória e um arquivo para persistência.
  """
  
  use GenServer
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail.Sender
  
  @table_name :deeper_hub_mail_queue
  @persist_interval 30_000 # 30 segundos
  @process_interval 5_000  # 5 segundos
  @max_retries 3
  @retry_delay 10_000      # 10 segundos
  
  # API Pública
  
  @doc """
  Inicia o servidor de filas de emails.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Adiciona um email à fila para envio posterior.
  
  ## Parâmetros
  
  - `email` - Email construído com a biblioteca Mail
  - `priority` - Prioridade do email (:high, :normal, :low)
  
  ## Retorno
  
  - `{:ok, id}` - ID do email na fila
  """
  def enqueue(email, priority \\ :normal) do
    id = generate_id()
    timestamp = DateTime.utc_now()
    
    email_data = %{
      id: id,
      email: email,
      priority: priority_value(priority),
      status: :pending,
      attempts: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    :ets.insert(@table_name, {id, email_data})
    GenServer.cast(__MODULE__, :persist_queue)
    
    Logger.info("Email adicionado à fila",
      module: __MODULE__,
      email_id: id,
      to: get_recipients(email),
      subject: email.subject,
      priority: priority
    )
    
    {:ok, id}
  end
  
  @doc """
  Obtém o status de um email na fila.
  
  ## Parâmetros
  
  - `id` - ID do email na fila
  
  ## Retorno
  
  - `{:ok, status}` - Status do email (:pending, :processing, :sent, :failed)
  - `{:error, :not_found}` - Email não encontrado na fila
  """
  def get_status(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, email_data}] -> {:ok, email_data.status}
      [] -> {:error, :not_found}
    end
  end
  
  @doc """
  Obtém estatísticas da fila de emails.
  
  ## Retorno
  
  - Mapa com estatísticas da fila
  """
  def get_stats do
    all_emails = :ets.tab2list(@table_name)
    
    %{
      total: length(all_emails),
      pending: count_by_status(all_emails, :pending),
      processing: count_by_status(all_emails, :processing),
      sent: count_by_status(all_emails, :sent),
      failed: count_by_status(all_emails, :failed),
      high_priority: count_by_priority(all_emails, priority_value(:high)),
      normal_priority: count_by_priority(all_emails, priority_value(:normal)),
      low_priority: count_by_priority(all_emails, priority_value(:low))
    }
  end
  
  @doc """
  Limpa emails já enviados da fila.
  
  ## Parâmetros
  
  - `older_than` - Limpa emails enviados há mais tempo que este valor em segundos
  
  ## Retorno
  
  - `{:ok, count}` - Número de emails removidos
  """
  def clean_sent_emails(older_than \\ 86400) do
    threshold = DateTime.add(DateTime.utc_now(), -older_than, :second)
    
    # Encontra emails enviados mais antigos que o limite
    sent_emails = :ets.tab2list(@table_name)
                  |> Enum.filter(fn {_, data} -> 
                    data.status == :sent && 
                    DateTime.compare(data.updated_at, threshold) == :lt
                  end)
    
    # Remove os emails da tabela
    Enum.each(sent_emails, fn {id, _} -> :ets.delete(@table_name, id) end)
    
    # Persiste a fila atualizada
    GenServer.cast(__MODULE__, :persist_queue)
    
    {:ok, length(sent_emails)}
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(_opts) do
    # Cria a tabela ETS se não existir
    :ets.new(@table_name, [:named_table, :set, :public, {:read_concurrency, true}])
    
    # Carrega a fila do arquivo de persistência
    load_queue()
    
    # Agenda a persistência periódica da fila
    schedule_persist()
    
    # Agenda o processamento periódico da fila
    schedule_process()
    
    {:ok, %{}}
  end
  
  @impl true
  def handle_cast(:persist_queue, state) do
    persist_queue()
    {:noreply, state}
  end
  
  @impl true
  def handle_info(:persist_queue, state) do
    persist_queue()
    schedule_persist()
    {:noreply, state}
  end
  
  @impl true
  def handle_info(:process_queue, state) do
    process_pending_emails()
    schedule_process()
    {:noreply, state}
  end
  
  # Funções privadas
  
  # Agenda a persistência periódica da fila
  defp schedule_persist do
    Process.send_after(self(), :persist_queue, @persist_interval)
  end
  
  # Agenda o processamento periódico da fila
  defp schedule_process do
    Process.send_after(self(), :process_queue, @process_interval)
  end
  
  # Persiste a fila em um arquivo
  defp persist_queue do
    queue_file = get_queue_file()
    
    # Obtém todos os itens da tabela
    queue_data = :ets.tab2list(@table_name)
    
    # Cria o diretório se não existir
    queue_dir = Path.dirname(queue_file)
    File.mkdir_p!(queue_dir)
    
    # Salva a fila em um arquivo temporário primeiro
    temp_file = "#{queue_file}.tmp"
    
    result = try do
      File.write!(temp_file, :erlang.term_to_binary(queue_data))
      # Renomeia o arquivo temporário para o arquivo final
      File.rename!(temp_file, queue_file)
      :ok
    rescue
      e ->
        Logger.error("Erro ao persistir fila de emails: #{inspect(e)}",
          module: __MODULE__
        )
        {:error, e}
    end
    
    result
  end
  
  # Carrega a fila de um arquivo
  defp load_queue do
    queue_file = get_queue_file()
    
    if File.exists?(queue_file) do
      try do
        queue_data = File.read!(queue_file) |> :erlang.binary_to_term()
        
        # Insere os itens na tabela ETS
        Enum.each(queue_data, fn item -> :ets.insert(@table_name, item) end)
        
        Logger.info("Fila de emails carregada com sucesso",
          module: __MODULE__,
          count: length(queue_data)
        )
        
        :ok
      rescue
        e ->
          Logger.error("Erro ao carregar fila de emails: #{inspect(e)}",
            module: __MODULE__
          )
          {:error, e}
      end
    else
      Logger.info("Arquivo de fila de emails não encontrado, iniciando com fila vazia",
        module: __MODULE__
      )
      :ok
    end
  end
  
  # Processa emails pendentes na fila
  defp process_pending_emails do
    # Obtém todos os emails pendentes, ordenados por prioridade
    pending_emails = :ets.tab2list(@table_name)
                     |> Enum.filter(fn {_, data} -> data.status == :pending end)
                     |> Enum.sort_by(fn {_, data} -> {data.priority, data.created_at} end)
    
    # Processa cada email pendente
    Enum.each(pending_emails, &process_email/1)
  end
  
  # Processa um email específico
  defp process_email({id, email_data}) do
    # Atualiza o status para :processing
    updated_data = %{email_data | status: :processing, updated_at: DateTime.utc_now()}
    :ets.insert(@table_name, {id, updated_data})
    
    # Tenta enviar o email
    result = Sender.deliver(email_data.email)
    
    # Atualiza o status com base no resultado
    case result do
      {:ok, message_id} ->
        # Email enviado com sucesso
        final_data = %{updated_data | 
          status: :sent, 
          updated_at: DateTime.utc_now(),
          message_id: message_id
        }
        :ets.insert(@table_name, {id, final_data})
        
        Logger.info("Email da fila enviado com sucesso",
          module: __MODULE__,
          email_id: id,
          message_id: message_id,
          to: get_recipients(email_data.email),
          subject: email_data.email.subject
        )
      
      {:error, reason} ->
        # Falha no envio
        attempts = email_data.attempts + 1
        
        if attempts >= @max_retries do
          # Excedeu o número máximo de tentativas
          final_data = %{updated_data | 
            status: :failed, 
            attempts: attempts,
            updated_at: DateTime.utc_now(),
            error: inspect(reason)
          }
          :ets.insert(@table_name, {id, final_data})
          
          Logger.error("Falha definitiva ao enviar email da fila",
            module: __MODULE__,
            email_id: id,
            attempts: attempts,
            error: inspect(reason),
            to: get_recipients(email_data.email),
            subject: email_data.email.subject
          )
        else
          # Agenda para nova tentativa
          final_data = %{updated_data | 
            status: :pending, 
            attempts: attempts,
            updated_at: DateTime.utc_now(),
            next_attempt: DateTime.add(DateTime.utc_now(), @retry_delay, :millisecond)
          }
          :ets.insert(@table_name, {id, final_data})
          
          Logger.warn("Falha temporária ao enviar email da fila, agendando nova tentativa",
            module: __MODULE__,
            email_id: id,
            attempts: attempts,
            error: inspect(reason),
            to: get_recipients(email_data.email),
            subject: email_data.email.subject
          )
        end
    end
    
    # Persiste a fila após cada processamento
    GenServer.cast(__MODULE__, :persist_queue)
  end
  
  # Gera um ID único para o email
  defp generate_id do
    timestamp = System.system_time(:microsecond)
    random = :rand.uniform(1_000_000)
    "email_#{timestamp}_#{random}"
  end
  
  # Obtém o valor numérico da prioridade
  defp priority_value(:high), do: 1
  defp priority_value(:normal), do: 2
  defp priority_value(:low), do: 3
  defp priority_value(_), do: 2
  
  # Conta emails por status
  defp count_by_status(emails, status) do
    Enum.count(emails, fn {_, data} -> data.status == status end)
  end
  
  # Conta emails por prioridade
  defp count_by_priority(emails, priority) do
    Enum.count(emails, fn {_, data} -> data.priority == priority end)
  end
  
  # Obtém o caminho do arquivo de persistência da fila
  defp get_queue_file do
    data_dir = Application.get_env(:deeper_hub, :data_dir, "priv/data")
    Path.join([data_dir, "mail", "queue.dat"])
  end
  
  # Obtém os destinatários de um email
  defp get_recipients(email) do
    (email.to || []) ++ (email.cc || []) ++ (email.bcc || [])
  end
end
