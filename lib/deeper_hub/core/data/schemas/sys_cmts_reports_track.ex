defmodule DeeperHub.Core.Data.Schemas.SysCmtsReportsTrack do
  @moduledoc """
  Schema para a tabela sys_cmts_reports_track.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "sys_cmts_reports_track",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
