defmodule DeeperHub.Core.Data.Migrations.Seeds.{{MODULE_NAME}}Seed do
  @moduledoc """
  Seed para a tabela {{TABLE_NAME}}.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo

  @doc """
  Insere os registros na tabela.
  """
  def run do
    IO.puts("Inserindo registros na tabela {{TABLE_NAME}}...")

    {{SEED_INSERTS}}

    IO.puts("Registros inseridos com sucesso!")
  end
end
