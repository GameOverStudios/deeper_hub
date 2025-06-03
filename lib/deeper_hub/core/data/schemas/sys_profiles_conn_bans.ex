defmodule DeeperHub.Core.Data.Schemas.SysProfilesConnBans do
  @moduledoc """
  Schema para a tabela sys_profiles_conn_bans.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "sys_profiles_conn_bans",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
