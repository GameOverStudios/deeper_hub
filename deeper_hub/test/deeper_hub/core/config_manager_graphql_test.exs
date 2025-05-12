defmodule DeeperHub.Core.ConfigManager.GraphQLTest do
  use ExUnit.Case, async: false

  alias DeeperHub.Core.ConfigManager.Schema.Setting
  alias DeeperHub.Core.ConfigManager.Services.Setting, as: SettingService
  alias DeeperHub.Core.ConfigManager.GraphQL.Schema, as: ConfigSchema

  setup do
    # Garantir que o Mnesia esteja rodando e as tabelas criadas
    :mnesia.start()
    :mnesia.clear_table(Setting)
    :ok
  end

  @query_get_config """
  query GetConfig($key: String!, $scope: String) {
    config(key: $key, scope: $scope) {
      id
      key
      value
      scope
      dataType
      description
    }
  }
  """

  @query_get_configs_by_scope """
  query GetConfigsByScope($scope: String) {
    configsByScope(scope: $scope) {
      key
      value
      scope
    }
  }
  """

  @mutation_set_config """
  mutation SetConfig($input: SettingInput!) {
    setConfig(input: $input) {
      id
      key
      value
      scope
      dataType
      description
      isSensitive
    }
  }
  """

  @mutation_delete_config """
  mutation DeleteConfig($key: String!, $scope: String) {
    deleteConfig(key: $key, scope: $scope) {
      key
      value
    }
  }
  """

  describe "GraphQL queries" do
    test "query: config - returns a specific config" do
      # Criar uma configuração de teste
      insert_config("graphql.test", "graphql value", "global")

      # Executar a query GraphQL
      variables = %{"key" => "graphql.test", "scope" => "global"}
      result = Absinthe.run(@query_get_config, ConfigSchema, variables: variables)

      # Verificar o resultado
      assert {:ok, %{data: %{"config" => config}}} = result
      assert config["key"] == "graphql.test"
      assert config["value"] == "graphql value"
      assert config["scope"] == "global"
    end

    test "query: configsByScope - returns configs for a scope" do
      # Criar algumas configurações de teste
      insert_config("graphql.test1", "value1", "test_scope")
      insert_config("graphql.test2", "value2", "test_scope")
      insert_config("graphql.test3", "value3", "other_scope")

      # Executar a query GraphQL
      variables = %{"scope" => "test_scope"}
      result = Absinthe.run(@query_get_configs_by_scope, ConfigSchema, variables: variables)

      # Verificar o resultado
      assert {:ok, %{data: %{"configsByScope" => configs}}} = result
      assert length(configs) == 2

      # Verificar que as configurações corretas foram retornadas
      keys = Enum.map(configs, & &1["key"])
      assert "graphql.test1" in keys
      assert "graphql.test2" in keys
      assert "graphql.test3" not in keys
    end
  end

  describe "GraphQL mutations" do
    test "mutation: setConfig - creates a new config" do
      # Dados para a configuração
      variables = %{
        "input" => %{
          "key" => "graphql.mutation",
          "value" => "mutation value",
          "scope" => "test_mutation",
          "description" => "Test mutation",
          "isSensitive" => false
        }
      }

      # Executar a mutation GraphQL
      result = Absinthe.run(@mutation_set_config, ConfigSchema, variables: variables)

      # Verificar o resultado
      assert {:ok, %{data: %{"setConfig" => config}}} = result
      assert config["key"] == "graphql.mutation"
      assert config["value"] == "mutation value"
      assert config["scope"] == "test_mutation"
      assert config["description"] == "Test mutation"
      assert config["isSensitive"] == false

      # Verificar que a configuração foi realmente salva
      {:ok, saved_config} = SettingService.get_by_key_and_scope("graphql.mutation", "test_mutation")
      assert saved_config.value == "mutation value"
    end

    test "mutation: deleteConfig - removes a config" do
      # Criar uma configuração para ser excluída
      insert_config("graphql.delete", "to be deleted", "test_delete")

      # Executar a mutation GraphQL
      variables = %{"key" => "graphql.delete", "scope" => "test_delete"}
      result = Absinthe.run(@mutation_delete_config, ConfigSchema, variables: variables)

      # Verificar o resultado
      assert {:ok, %{data: %{"deleteConfig" => deleted_config}}} = result
      assert deleted_config["key"] == "graphql.delete"

      # Verificar que a configuração foi realmente excluída
      assert {:error, :not_found} = SettingService.get_by_key_and_scope("graphql.delete", "test_delete")
    end
  end

  # Função auxiliar para inserir configurações de teste
  defp insert_config(key, value, scope) do
    attrs = %{
      key: key,
      value: value,
      scope: scope,
      data_type: infer_data_type(value),
      description: "Test configuration"
    }

    {:ok, setting} = SettingService.create(attrs)
    setting
  end

  defp infer_data_type(value) when is_binary(value), do: :string
  defp infer_data_type(value) when is_integer(value), do: :integer
  defp infer_data_type(value) when is_float(value), do: :float
  defp infer_data_type(value) when is_boolean(value), do: :boolean
  defp infer_data_type(value) when is_list(value), do: :list
  defp infer_data_type(value) when is_map(value), do: :map
  defp infer_data_type(_), do: :string
end
