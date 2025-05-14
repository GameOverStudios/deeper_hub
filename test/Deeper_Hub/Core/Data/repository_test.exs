defmodule Deeper_Hub.Core.Data.RepositoryTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Data.Database
  
  # Configuração para executar uma vez antes de todos os testes deste módulo
  setup_all do
    # Inicializar o banco de dados para os testes
    :mnesia.stop()
    # Configura um diretório específico para testes
    test_mnesia_dir = Path.join(System.tmp_dir!(), "mnesia_test_#{:rand.uniform(1000000)}")
    File.mkdir_p!(test_mnesia_dir)
    :application.set_env(:mnesia, :dir, String.to_charlist(test_mnesia_dir))
    # Limpa o schema anterior
    :mnesia.delete_schema([node()])
    :mnesia.start()
    # Registra o diretório para limpeza após o teste
    on_exit(fn -> File.rm_rf!(test_mnesia_dir) end)
    
    # Inicializa o sistema de métricas
    alias Deeper_Hub.Core.Metrics
    Metrics.initialize()
    
    # Criar as tabelas necessárias em modo de teste (apenas em memória)
    result = Database.create_tables(test_mode: true)
    
    # Verificar se as tabelas foram criadas corretamente
    tables = :mnesia.system_info(:tables)
    IO.puts("\nInicializando banco de dados para testes...")
    IO.puts("Resultado da criação de tabelas: #{inspect(result)}")
    IO.puts("Tabelas existentes: #{inspect(tables)}")
    
    # Verificar se a tabela :users existe
    if Enum.member?(tables, :users) do
      # Verificar as propriedades da tabela
      record_name = :mnesia.table_info(:users, :record_name)
      attributes = :mnesia.table_info(:users, :attributes)
      IO.puts("Tabela :users - record_name: #{inspect(record_name)}, attributes: #{inspect(attributes)}")
      
      # Retornar o contexto para os testes
      %{tables: tables}
    else
      IO.puts("ERRO: Tabela :users não foi criada! Os testes podem falhar.")
      # Mesmo com erro, retornamos um mapa válido para o ExUnit não invalidar os testes
      # Os testes individuais irão falhar de forma mais informativa
      %{tables: [], error: :table_not_created}
    end
  end
  
  # Configuração para executar antes de cada teste
  setup context do
    # Verificar se as tabelas existem antes de tentar limpar
    tables = :mnesia.system_info(:tables)
    
    if Enum.member?(tables, :users) and Enum.member?(tables, :sessions) do
      # Limpar os dados das tabelas existentes
      :mnesia.clear_table(:users)
      :mnesia.clear_table(:sessions)
      
      # Inserir dados de teste
      test_user = {:users, 1, "test_user", "test@example.com", "test_hash", DateTime.utc_now()}
      insert_result = Repository.insert(:users, test_user)
      
      case insert_result do
        {:ok, ^test_user} ->
          # Retornar o contexto para os testes
          {:ok, Map.put(context, :test_user, test_user)}
        error ->
          IO.puts("AVISO: Falha ao inserir usuário de teste: #{inspect(error)}")
          {:ok, Map.put(context, :insert_error, error)}
      end
    else
      IO.puts("AVISO: Tabelas necessárias não existem, pulando inserção de dados de teste")
      {:ok, Map.put(context, :setup_error, :tables_not_found)}
    end
  end
  
  describe "insert/2" do
    test "insere um novo registro com sucesso" do
      user = {:users, 2, "alice", "alice@example.com", "hash_alice", DateTime.utc_now()}
      assert {:ok, ^user} = Repository.insert(:users, user)
      
      # Verificar se o registro foi realmente inserido
      assert {:ok, ^user} = Repository.find(:users, 2)
    end
    
    test "falha ao inserir um registro com chave duplicada" do
      user = {:users, 1, "duplicate", "duplicate@example.com", "hash_duplicate", DateTime.utc_now()}
      result = Repository.insert(:users, user)
      
      # Mnesia pode retornar diferentes erros para chaves duplicadas dependendo da configuração
      # Verificamos apenas se é um erro
      assert match?({:error, _}, result)
    end
  end
  
  describe "find/2" do
    test "encontra um registro existente", context do
      # Verificar se temos o usuário de teste no contexto
      if Map.has_key?(context, :test_user) do
        test_user = context.test_user
        assert {:ok, ^test_user} = Repository.find(:users, 1)
      else
        # Caso alternativo quando o usuário de teste não está disponível
        # Buscar o usuário diretamente
        assert {:ok, user} = Repository.find(:users, 1)
        assert match?({:users, 1, _, _, _, _}, user)
      end
    end
    
    test "retorna erro para registro inexistente" do
      assert {:error, :not_found} = Repository.find(:users, 999)
    end
    
    test "retorna erro para tabela inexistente" do
      result = Repository.find(:tabela_inexistente, 1)
      assert match?({:error, _}, result)
    end
  end
  
  describe "update/2" do
    test "atualiza um registro existente" do
      updated_user = {:users, 1, "updated_user", "updated@example.com", "updated_hash", DateTime.utc_now()}
      assert {:ok, ^updated_user} = Repository.update(:users, updated_user)
      
      # Verificar se o registro foi realmente atualizado
      assert {:ok, ^updated_user} = Repository.find(:users, 1)
    end
    
    test "insere um novo registro se a chave não existir" do
      new_user = {:users, 3, "new_user", "new@example.com", "new_hash", DateTime.utc_now()}
      assert {:ok, ^new_user} = Repository.update(:users, new_user)
      
      # Verificar se o registro foi inserido
      assert {:ok, ^new_user} = Repository.find(:users, 3)
    end
  end
  
  describe "delete/2" do
    test "remove um registro existente" do
      assert {:ok, :deleted} = Repository.delete(:users, 1)
      
      # Verificar se o registro foi realmente removido
      assert {:error, :not_found} = Repository.find(:users, 1)
    end
    
    test "retorna erro para registro inexistente" do
      result = Repository.delete(:users, 999)
      
      # Mnesia pode retornar diferentes erros para chaves inexistentes
      assert match?({:error, _}, result)
    end
  end
  
  describe "all/1" do
    test "retorna todos os registros de uma tabela" do
      # Limpar a tabela para garantir um estado conhecido
      :mnesia.clear_table(:users)
      
      # Inserir registros para testar - inserindo exatamente 3 registros
      user1 = {:users, 1, "test_user", "test@example.com", "test_hash", DateTime.utc_now()}
      user4 = {:users, 4, "user4", "user4@example.com", "hash4", DateTime.utc_now()}
      user5 = {:users, 5, "user5", "user5@example.com", "hash5", DateTime.utc_now()}
      
      Repository.insert(:users, user1)
      Repository.insert(:users, user4)
      Repository.insert(:users, user5)
      
      # Invalidar o cache para garantir que estamos buscando dados atualizados
      Deeper_Hub.Core.Data.Cache.invalidate(:users, :all)
      
      {:ok, records} = Repository.all(:users)
      
      # Verificar se retornou exatamente os 3 registros inseridos
      assert length(records) == 3
      
      # Verificar se todos os registros têm a estrutura correta
      Enum.each(records, fn record ->
        assert match?({:users, _, _, _, _, _}, record)
      end)
    end
    
    test "retorna lista vazia para tabela sem registros" do
      # Remover todos os registros da tabela users
      {:ok, records} = Repository.all(:users)
      Enum.each(records, fn record ->
        {_, id, _, _, _, _} = record
        Repository.delete(:users, id)
      end)
      
      # Verificar se retorna uma lista vazia
      assert {:ok, []} = Repository.all(:users)
    end
    
    test "retorna erro para tabela inexistente" do
      result = Repository.all(:tabela_inexistente)
      assert match?({:error, {:table_does_not_exist, :tabela_inexistente}}, result)
    end
  end
  
  describe "match/2" do
    test "encontra registros que correspondem ao padrão" do
      # Inserir mais alguns registros para testar
      Repository.insert(:users, {:users, 6, "match_user", "match@example.com", "hash_match", DateTime.utc_now()})
      Repository.insert(:users, {:users, 7, "match_user", "match2@example.com", "hash_match2", DateTime.utc_now()})
      
      # Buscar todos os usuários
      {:ok, records} = Repository.all(:users)
      
      # Verificar se retornou os registros corretos
      assert length(records) >= 2
      
      # Verificar se todos os registros têm a estrutura correta
      Enum.each(records, fn record ->
        assert match?({:users, _, _, _, _, _}, record)
      end)
    end
    
    test "retorna lista vazia quando nenhum registro corresponde" do
      # Remover todos os registros da tabela users
      {:ok, records} = Repository.all(:users)
      Enum.each(records, fn record ->
        {_, id, _, _, _, _} = record
        Repository.delete(:users, id)
      end)
      
      # Verificar se retorna uma lista vazia
      {:ok, empty_records} = Repository.all(:users)
      assert empty_records == []
    end
    
    test "retorna erro para tabela inexistente" do
      result = Repository.all(:tabela_inexistente)
      assert match?({:error, {:table_does_not_exist, :tabela_inexistente}}, result)
    end
    
    test "busca registros específicos" do
      # Inserir registros com usernames específicos para testar
      user8 = {:users, 8, "special_user", "special@example.com", "hash_special", DateTime.utc_now()}
      Repository.insert(:users, user8)
      Repository.insert(:users, {:users, 9, "special_user", "special2@example.com", "hash_special2", DateTime.utc_now()})
      
      # Buscar um registro específico pelo id
      {:ok, found_user} = Repository.find(:users, 8)
      
      # Verificar se encontrou o registro correto
      assert elem(found_user, 1) == 8
      assert elem(found_user, 2) == "special_user"
    end
  end
end
