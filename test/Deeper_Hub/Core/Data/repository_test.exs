defmodule Deeper_Hub.Core.Data.RepositoryTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Data.Database
  alias Deeper_Hub.Core.Data.Cache
  
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
    # Limpar o cache para garantir que cada teste comece com um estado limpo
    Cache.clear()
    
    # Verificar se as tabelas existem antes de tentar limpar
    tables = :mnesia.system_info(:tables)
    
    if Enum.member?(tables, :users) do
      # Limpar a tabela para garantir um estado conhecido
      :mnesia.clear_table(:users)
      
      # Inserir um usuário de teste para os testes que precisam de um registro existente
      test_user = {:users, 1, "test_user", "test@example.com", "test_hash", DateTime.utc_now()}
      
      case :mnesia.transaction(fn -> :mnesia.write(test_user) end) do
        {:atomic, :ok} ->
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
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      # Verificar se temos o usuário de teste no contexto
      if Map.has_key?(context, :test_user) do
        test_user = context.test_user
        
        # Verificar que o cache está vazio inicialmente
        assert :not_found = Cache.get(:users, :find, 1)
        
        # Buscar o usuário pelo id
        {:ok, found_user} = Repository.find(:users, 1)
        
        # Verificar se encontrou o registro correto
        assert found_user == test_user
        
        # Verificar se o resultado foi armazenado no cache
        assert {:ok, {:ok, ^found_user}} = Cache.get(:users, :find, 1)
      else
        flunk("Usuário de teste não disponível no contexto")
      end
    end
    
    test "retorna erro para registro inexistente" do
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      # Buscar um registro inexistente
      assert {:error, :not_found} = Repository.find(:users, 999)
      
      # Verificar que o erro não foi armazenado no cache
      # Erros não devem ser cacheados para permitir recuperação futura
      assert :not_found = Cache.get(:users, :find, 999)
    end
    
    test "retorna erro para tabela inexistente" do
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      result = Repository.find(:tabela_inexistente, 1)
      assert match?({:error, _}, result)
      
      # Verificar que o erro não foi armazenado no cache
      assert :not_found = Cache.get(:tabela_inexistente, :find, 1)
    end
  end
  
  describe "update/2" do
    test "atualiza um registro existente" do
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      # Buscar o registro original para armazenar no cache
      {:ok, original_user} = Repository.find(:users, 1)
      
      # Verificar que o registro original está no cache
      assert {:ok, {:ok, ^original_user}} = Cache.get(:users, :find, 1)
      
      # Atualizar o registro
      updated_user = {:users, 1, "updated_user", "updated@example.com", "updated_hash", DateTime.utc_now()}
      assert {:ok, ^updated_user} = Repository.update(:users, updated_user)
      
      # Verificar que o cache foi invalidado após a atualização
      assert :not_found = Cache.get(:users, :find, 1)
      
      # Buscar o registro atualizado
      assert {:ok, ^updated_user} = Repository.find(:users, 1)
      
      # Verificar que o registro atualizado foi armazenado no cache
      assert {:ok, {:ok, ^updated_user}} = Cache.get(:users, :find, 1)
    end
    
    test "insere um novo registro se a chave não existir" do
      new_user = {:users, 3, "new_user", "new@example.com", "new_hash", DateTime.utc_now()}
      assert {:ok, ^new_user} = Repository.update(:users, new_user)
      
      # Verificar se o registro foi inserido
      assert {:ok, ^new_user} = Repository.find(:users, 3)
    end
    
    test "retorna erro para tabela inexistente" do
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      user = {:tabela_inexistente, 1, "user", "email", "hash", DateTime.utc_now()}
      result = Repository.update(:tabela_inexistente, user)
      assert match?({:error, _}, result)
      
      # Verificar que o erro não foi armazenado no cache
      assert :not_found = Cache.get(:tabela_inexistente, :update, user)
    end
  end
  
  describe "delete/2" do
    test "remove um registro existente" do
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      # Buscar o registro para armazenar no cache
      {:ok, original_user} = Repository.find(:users, 1)
      
      # Verificar que o registro está no cache
      assert {:ok, {:ok, ^original_user}} = Cache.get(:users, :find, 1)
      
      # Remover o registro
      assert {:ok, _} = Repository.delete(:users, 1)
      
      # Verificar que o cache foi invalidado após a remoção
      assert :not_found = Cache.get(:users, :find, 1)
      
      # Verificar se o registro foi realmente removido
      assert {:error, :not_found} = Repository.find(:users, 1)
    end
    
    test "retorna erro para registro inexistente" do
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      result = Repository.delete(:users, 999)
      
      # Mnesia pode retornar diferentes erros para chaves inexistentes
      assert match?({:error, _}, result)
      
      # Verificar que o erro não foi armazenado no cache
      assert :not_found = Cache.get(:users, :delete, 999)
    end
  end
  
  describe "all/1" do
    test "retorna todos os registros de uma tabela" do
      # Limpar o cache e a tabela para garantir um estado conhecido
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Inserir registros para testar - inserindo exatamente 3 registros
      user1 = {:users, 1, "test_user", "test@example.com", "test_hash", DateTime.utc_now()}
      user4 = {:users, 4, "user4", "user4@example.com", "hash4", DateTime.utc_now()}
      user5 = {:users, 5, "user5", "user5@example.com", "hash5", DateTime.utc_now()}
      
      Repository.insert(:users, user1)
      Repository.insert(:users, user4)
      Repository.insert(:users, user5)
      
      # Invalidar o cache para garantir que estamos buscando dados atualizados
      Cache.invalidate(:users, :all)
      
      {:ok, records} = Repository.all(:users)
      
      # Verificar se retornou exatamente os 3 registros inseridos
      assert length(records) == 3
      
      # Verificar se todos os registros têm a estrutura correta
      Enum.each(records, fn record ->
        assert match?({:users, _, _, _, _, _}, record)
      end)
      
      # Verificar se o resultado foi armazenado no cache
      assert {:ok, {:ok, cached_records}} = Cache.get(:users, :all, nil)
      assert length(cached_records) == 3
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
      # Limpar o cache e a tabela para garantir um estado conhecido
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Inserir registros para testar
      Repository.insert(:users, {:users, 6, "match_user", "match@example.com", "hash_match", DateTime.utc_now()})
      Repository.insert(:users, {:users, 7, "match_user", "match2@example.com", "hash_match2", DateTime.utc_now()})
      Repository.insert(:users, {:users, 8, "other_user", "other@example.com", "hash_other", DateTime.utc_now()})
      
      # Criar um padrão para a busca
      pattern = {:users, :_, "match_user", :_, :_, :_}
      
      # Verificar que o cache está vazio inicialmente
      assert :not_found = Cache.get(:users, :match, pattern)
      
      # Buscar registros que correspondem ao padrão
      {:ok, matches} = Repository.match(:users, pattern)
      
      # Verificar se retornou os registros corretos
      assert length(matches) == 2
      
      # Verificar se todos os registros têm o username correto
      Enum.each(matches, fn record ->
        assert elem(record, 2) == "match_user"
      end)
      
      # Verificar se o resultado foi armazenado no cache
      assert {:ok, {:ok, cached_matches}} = Cache.get(:users, :match, pattern)
      assert length(cached_matches) == 2
    end
    
    test "retorna lista vazia quando nenhum registro corresponde" do
      # Limpar o cache e a tabela para garantir um estado conhecido
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Criar um padrão para a busca que não corresponde a nenhum registro
      pattern = {:users, :_, "nonexistent_user", :_, :_, :_}
      
      # Verificar que o cache está vazio inicialmente
      assert :not_found = Cache.get(:users, :match, pattern)
      
      # Buscar registros que correspondem ao padrão
      {:ok, empty_matches} = Repository.match(:users, pattern)
      
      # Verificar se retorna uma lista vazia
      assert empty_matches == []
      
      # Verificar se o resultado vazio foi armazenado no cache
      assert {:ok, {:ok, cached_empty}} = Cache.get(:users, :match, pattern)
      assert cached_empty == []
    end
    
    test "retorna erro para tabela inexistente" do
      # Limpar o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      # Criar um padrão para a busca
      pattern = {:tabela_inexistente, :_, :_, :_, :_, :_}
      
      # Buscar registros em uma tabela inexistente
      result = Repository.match(:tabela_inexistente, pattern)
      assert match?({:error, _}, result)
      
      # Verificar que o erro não foi armazenado no cache
      assert :not_found = Cache.get(:tabela_inexistente, :match, pattern)
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

  describe "integração com cache" do
    test "find armazena resultados no cache" do
      # Limpa o cache para garantir um estado inicial conhecido
      Cache.clear()
      
      # Insere um registro para teste
      test_user = {:users, 200, "cache_test", "cache@example.com", "hash_cache", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, test_user)
      
      # Verifica que o cache está vazio inicialmente
      assert :not_found = Cache.get(:users, :find, 200)
      
      # Executa a operação find que deve armazenar no cache
      {:ok, found_user} = Repository.find(:users, 200)
      assert elem(found_user, 1) == 200
      
      # Verifica se o resultado foi armazenado no cache
      assert {:ok, {:ok, ^found_user}} = Cache.get(:users, :find, 200)
    end
    
    test "all armazena resultados no cache" do
      # Limpa o cache e a tabela
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Insere alguns registros para teste
      user1 = {:users, 201, "user1", "user1@example.com", "hash1", DateTime.utc_now()}
      user2 = {:users, 202, "user2", "user2@example.com", "hash2", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user1)
      {:ok, _} = Repository.insert(:users, user2)
      
      # Verifica que o cache está vazio inicialmente
      assert :not_found = Cache.get(:users, :all, nil)
      
      # Executa a operação all que deve armazenar no cache
      {:ok, all_users} = Repository.all(:users)
      assert length(all_users) == 2
      
      # Verifica se o resultado foi armazenado no cache
      assert {:ok, {:ok, cached_users}} = Cache.get(:users, :all, nil)
      assert length(cached_users) == 2
    end
    
    test "match armazena resultados no cache" do
      # Limpa o cache e a tabela
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Insere alguns registros para teste
      user1 = {:users, 203, "match_user", "match1@example.com", "hash1", DateTime.utc_now()}
      user2 = {:users, 204, "match_user", "match2@example.com", "hash2", DateTime.utc_now()}
      user3 = {:users, 205, "other_user", "other@example.com", "hash3", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user1)
      {:ok, _} = Repository.insert(:users, user2)
      {:ok, _} = Repository.insert(:users, user3)
      
      # Cria um padrão para a busca
      pattern = {:users, :_, "match_user", :_, :_, :_}
      
      # Verifica que o cache está vazio inicialmente
      assert :not_found = Cache.get(:users, :match, pattern)
      
      # Executa a operação match que deve armazenar no cache
      {:ok, matches} = Repository.match(:users, pattern)
      assert length(matches) == 2
      
      # Verifica se o resultado foi armazenado no cache
      assert {:ok, {:ok, cached_matches}} = Cache.get(:users, :match, pattern)
      assert length(cached_matches) == 2
    end
    
    test "insert invalida o cache para operações relacionadas" do
      # Limpa o cache e a tabela
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Insere um registro inicial
      user1 = {:users, 206, "initial", "initial@example.com", "hash1", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user1)
      
      # Executa operações para preencher o cache
      {:ok, _} = Repository.find(:users, 206)
      {:ok, all_before} = Repository.all(:users)
      assert length(all_before) == 1
      
      # Verifica que os resultados estão no cache
      assert {:ok, _} = Cache.get(:users, :find, 206)
      assert {:ok, _} = Cache.get(:users, :all, nil)
      
      # Insere um novo registro
      user2 = {:users, 207, "new_user", "new@example.com", "hash2", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user2)
      
      # Verifica que o cache para all foi invalidado, mas o find específico não
      assert {:ok, _} = Cache.get(:users, :find, 206)  # Ainda válido
      assert :not_found = Cache.get(:users, :all, nil)  # Invalidado
      
      # Busca todos novamente
      {:ok, all_after} = Repository.all(:users)
      assert length(all_after) == 2
      
      # Verifica que o novo resultado foi armazenado no cache
      assert {:ok, {:ok, cached_all}} = Cache.get(:users, :all, nil)
      assert length(cached_all) == 2
    end
    
    test "update invalida o cache para o registro específico" do
      # Limpa o cache e a tabela
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Insere um registro para teste
      user = {:users, 208, "before_update", "before@example.com", "hash", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user)
      
      # Busca o registro para armazenar no cache
      {:ok, _} = Repository.find(:users, 208)
      
      # Verifica que o resultado está no cache
      assert {:ok, _} = Cache.get(:users, :find, 208)
      
      # Atualiza o registro
      updated_user = put_elem(user, 2, "after_update")
      {:ok, _} = Repository.update(:users, updated_user)
      
      # Verifica que o cache para o registro específico foi invalidado
      assert :not_found = Cache.get(:users, :find, 208)
      
      # Busca o registro atualizado
      {:ok, found_updated} = Repository.find(:users, 208)
      assert elem(found_updated, 2) == "after_update"
      
      # Verifica que o novo resultado foi armazenado no cache
      assert {:ok, {:ok, cached_updated}} = Cache.get(:users, :find, 208)
      assert elem(cached_updated, 2) == "after_update"
    end
    
    test "delete invalida o cache para o registro específico" do
      # Limpa o cache e a tabela
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Insere um registro para teste
      user = {:users, 209, "to_delete", "delete@example.com", "hash", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user)
      
      # Busca o registro para armazenar no cache
      {:ok, _} = Repository.find(:users, 209)
      
      # Verifica que o resultado está no cache
      assert {:ok, _} = Cache.get(:users, :find, 209)
      
      # Remove o registro
      {:ok, _} = Repository.delete(:users, 209)
      
      # Verifica que o cache para o registro específico foi invalidado
      assert :not_found = Cache.get(:users, :find, 209)
      
      # Tenta buscar o registro removido
      result = Repository.find(:users, 209)
      assert match?({:error, :not_found}, result)
    end
  end
end
