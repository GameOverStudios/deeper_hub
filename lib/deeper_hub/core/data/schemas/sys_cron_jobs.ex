defmodule DeeperHub.Core.Data.Schemas.SysCronJobs do
  @moduledoc """
  Schema para a tabela sys_cron_jobs.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "sys_cron_jobs",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
