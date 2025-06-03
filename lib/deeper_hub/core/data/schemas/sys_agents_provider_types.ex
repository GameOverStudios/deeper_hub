defmodule DeeperHub.Core.Data.Schemas.SysAgentsProviderTypes do
  @moduledoc """
  Schema para a tabela sys_agents_provider_types.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "sys_agents_provider_types",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
