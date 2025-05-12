defmodule DeeperHub.Core.ConfigManagerTest do
  use ExUnit.Case, async: false

  alias DeeperHub.Core.ConfigManager
  alias DeeperHub.Core.ConfigManager.Schema.Setting
  alias DeeperHub.Core.ConfigManager.Services.Setting, as: SettingService

  setup do
    # Garantir que o Mnesia esteja rodando e as tabelas criadas
    :mnesia.start()
    :mnesia.clear_table(Setting)
    :ok
  end

  describe "get/3" do
    test "returns the value for an existing configuration" do
      # Inserir uma configuração diretamente no banco de dados para teste
      insert_config("test.key", "test value", "global")

      # Verificar se o valor é retornado corretamente
      assert "test value" == ConfigManager.get("test.key")
    end

    test "returns the default value when configuration does not exist" do
      assert "default" == ConfigManager.get("nonexistent.key", "global", "default")
    end

    test "returns value for a scoped configuration" do
      insert_config("test.key", "global value", "global")
      insert_config("test.key", "user value", "user:123")

      assert "user value" == ConfigManager.get("test.key", "user:123")
    end
  end

  describe "get_config/2" do
    test "converts a list of atoms to a string key" do
      insert_config("app.feature.enabled", "true", "global")

      assert "true" == ConfigManager.get_config([:app, :feature, :enabled])
    end
  end

  describe "set/3" do
    test "creates a new configuration" do
      {:ok, config} = ConfigManager.set("test.create", "created value")

      assert %{key: "test.create", value: "created value", scope: "global"} = config

      # Verificar se foi realmente salvo
      assert "created value" == ConfigManager.get("test.create")
    end

    test "updates an existing configuration" do
      insert_config("test.update", "old value", "global")

      {:ok, config} = ConfigManager.set("test.update", "new value")

      assert %{key: "test.update", value: "new value"} = config

      # Verificar se foi realmente atualizado
      assert "new value" == ConfigManager.get("test.update")
    end

    test "sets a configuration with custom options" do
      opts = [
        scope: "tenant:abc",
        data_type: :integer,
        description: "Test description",
        is_sensitive: true,
        created_by: "test_user"
      ]

      {:ok, config} = ConfigManager.set("test.options", 42, opts)

      assert config.key == "test.options"
      assert config.value == 42
      assert config.scope == "tenant:abc"
      assert config.data_type == :integer
      assert config.description == "Test description"
      assert config.is_sensitive == true
      assert config.created_by == "test_user"
    end
  end

  describe "delete/3" do
    test "removes an existing configuration" do
      insert_config("test.delete", "value to delete", "global")

      {:ok, _} = ConfigManager.delete("test.delete")

      # Verificar se foi realmente removido
      assert nil == ConfigManager.get("test.delete")
    end

    test "returns error for nonexistent configuration" do
      assert {:error, :not_found} = ConfigManager.delete("nonexistent.key")
    end
  end

  describe "subscribe/2" do
    test "subscriber receives notifications when configuration changes" do
      # Criar uma configuração
      insert_config("notification.test", "old value", "global")

      # Assinar para receber notificações
      ConfigManager.subscribe("notification.*", self())

      # Atualizar a configuração
      ConfigManager.set("notification.test", "new value")

      # Verificar se a notificação foi recebida
      assert_receive {:event, "config.notification.test", %{key: "notification.test", new_value: "new value"}, _}, 1000
    end
  end

  # Funções auxiliares para os testes

  defp insert_config(key, value, scope) do
    attrs = %{
      key: key,
      value: value,
      scope: scope,
      data_type: infer_data_type(value)
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
