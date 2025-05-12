defmodule DeeperHub.Core.ConfigManager.GraphQL.Schema do
  @moduledoc """
  Schema GraphQL para o ConfigManager.

  Integra os tipos, queries e mutations definidos nos outros módulos para
  criar um schema GraphQL completo para o ConfigManager.
  """

  use Absinthe.Schema

  # Importa os tipos, queries e mutations definidos nos outros módulos
  import_types DeeperHub.Core.ConfigManager.GraphQL.Types
  import_types DeeperHub.Core.ConfigManager.GraphQL.Queries
  import_types DeeperHub.Core.ConfigManager.GraphQL.Mutations

  # Define o schema raiz
  query do
    import_fields :config_queries
  end

  mutation do
    import_fields :config_mutations
  end

  # Funções para conversão e processamento de valores
  # Pode ser expandido se necessário para lidar com tipos personalizados
  scalar :json, name: "JSON" do
    description "Um valor JSON"
    parse &Jason.decode!/1
    serialize &Jason.encode!/1
  end
end
