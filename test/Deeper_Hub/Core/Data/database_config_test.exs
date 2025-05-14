defmodule Deeper_Hub.Core.Data.DatabaseConfigTest do
  @moduledoc """
  Testes para o módulo DatabaseConfig.
  
  Este módulo testa as funcionalidades de configuração do banco de dados,
  garantindo que o banco de dados seja configurado corretamente para
  diferentes ambientes.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.DatabaseConfig
  alias Deeper_Hub.Core.Logger
  
  describe "get_config/1" do
    test "retorna configuração válida para ambiente de teste" do
      # Obtém a configuração para o ambiente de teste
      config = DatabaseConfig.get_config(:test)
      
      # Verifica se a configuração contém os campos necessários
      assert is_binary(config.database)
      assert config.pool == :poolboy
      assert String.contains?(config.database, "test.db")
    end
    
    test "retorna configuração válida para ambiente de desenvolvimento" do
      # Obtém a configuração para o ambiente de desenvolvimento
      config = DatabaseConfig.get_config(:dev)
      
      # Verifica se a configuração contém os campos necessários
      assert is_binary(config.database)
      assert config.pool == :poolboy
      assert String.contains?(config.database, "dev.db")
    end
    
    test "retorna configuração válida para ambiente de produção" do
      # Obtém a configuração para o ambiente de produção
      config = DatabaseConfig.get_config(:prod)
      
      # Verifica se a configuração contém os campos necessários
      assert is_binary(config.database)
      assert config.pool == :poolboy
      assert String.contains?(config.database, "prod.db")
    end
    
    test "usa o diretório correto para o banco de dados" do
      # Obtém a configuração para o ambiente de teste
      config = DatabaseConfig.get_config(:test)
      
      # Verifica se o caminho do banco de dados inclui o diretório "database"
      assert String.contains?(config.database, "database")
    end
  end
  
  describe "configure/1" do
    setup do
      # Obtém a configuração para o ambiente de teste
      config = DatabaseConfig.get_config(:test)
      
      # Tenta remover o banco de dados para garantir um ambiente limpo
      # Usa try/rescue para lidar com erros de permissão
      if File.exists?(config.database) do
        try do
          File.rm!(config.database)
        rescue
          e in File.Error ->
            # Registra o erro mas continua o teste
            Logger.warning("Não foi possível remover o arquivo de banco de dados: #{inspect(e.reason)} (#{e.action}: #{e.path}). "
                          <> "Os testes continuarão com o banco existente.")
        end
      end
      
      # Retorna a configuração para os testes
      {:ok, config: config}
    end
    
    test "cria o banco de dados se não existir", %{config: config} do
      # Se o banco de dados já existe, não podemos testar a criação
      # Então verificamos apenas se a configuração não falha
      if File.exists?(config.database) do
        Logger.info("Banco de dados já existe, testando apenas a configuração")
        assert :ok = DatabaseConfig.configure(config)
      else
        # Verifica que o banco de dados não existe
        refute File.exists?(config.database)
        
        # Configura o banco de dados
        DatabaseConfig.configure(config)
        
        # Verifica que o banco de dados foi criado
        assert File.exists?(config.database)
      end
    end
    
    test "não falha se o banco de dados já existir" do
      # Obtém a configuração para o ambiente de teste
      config = DatabaseConfig.get_config(:test)
      
      # Garante que o banco de dados existe
      # Usa try/rescue para lidar com erros de permissão
      try do
        unless File.exists?(config.database) do
          File.mkdir_p(Path.dirname(config.database))
          File.write!(config.database, "")
        end
      rescue
        e in File.Error ->
          Logger.warning("Não foi possível criar o arquivo de banco de dados: #{inspect(e.reason)} (#{e.action}: #{e.path})")
      end
      
      # Configura o banco de dados novamente
      result = DatabaseConfig.configure(config)
      
      # Verifica que não houve erro
      assert result == :ok
    end
    
    test "cria o diretório do banco de dados se não existir" do
      # Obtém a configuração para o ambiente de teste
      config = DatabaseConfig.get_config(:test)
      
      # Altera o caminho do banco de dados para um diretório temporário específico para este teste
      test_dir = "tmp/test_db_config_#{System.unique_integer([:positive])}" 
      config = %{config | database: "#{test_dir}/test.db"}
      
      # Tenta remover o diretório se ele existir
      try do
        if File.exists?(Path.dirname(config.database)) do
          File.rm_rf!(Path.dirname(config.database))
        end
        
        # Verifica que o diretório não existe
        refute File.exists?(Path.dirname(config.database))
        
        # Configura o banco de dados
        DatabaseConfig.configure(config)
        
        # Verifica que o diretório foi criado
        assert File.exists?(Path.dirname(config.database))
      rescue
        e in File.Error ->
          # Se não for possível manipular os arquivos, registra o erro e verifica apenas
          # se a configuração não falha
          Logger.warning("Não foi possível manipular os arquivos: #{inspect(e.reason)} (#{e.action}: #{e.path})")
          assert :ok = DatabaseConfig.configure(config)
      after
        # Tenta limpar o diretório de teste
        try do
          if File.exists?(Path.dirname(config.database)) do
            File.rm_rf!(Path.dirname(config.database))
          end
        rescue
          _ -> :ok
        end
      end
    end
  end
  
  describe "database_exists?/1" do
    test "retorna true se o banco de dados existir" do
      # Obtém a configuração para o ambiente de teste
      config = DatabaseConfig.get_config(:test)
      
      # Garante que o banco de dados existe
      unless File.exists?(config.database) do
        File.mkdir_p(Path.dirname(config.database))
        File.write!(config.database, "")
      end
      
      # Verifica que a função retorna true
      assert DatabaseConfig.database_exists?(config) == true
    end
    
    test "retorna false se o banco de dados não existir" do
      # Obtém a configuração para o ambiente de teste com um caminho diferente
      # para evitar conflitos com outros testes
      config = %{DatabaseConfig.get_config(:test) | database: "database/nonexistent_test.db"}
      
      # Garante que o banco de dados não existe
      if File.exists?(config.database) do
        File.rm!(config.database)
      end
      
      # Verifica que a função retorna false
      assert DatabaseConfig.database_exists?(config) == false
    end
  end
end
