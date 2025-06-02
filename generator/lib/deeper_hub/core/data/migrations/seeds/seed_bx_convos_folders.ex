defmodule DeeperHub.Core.Data.Migrations.Seeds.BxConvosFoldersSeed do
  @moduledoc """
  Seed para a tabela bx_convos_folders.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo

  @doc """
  Insere os registros na tabela.
  """
  def run do
    IO.puts("Inserindo registros na tabela bx_convos_folders...")

        Repo.execute("INSERT INTO bx_convos_folders (id, author, name) VALUES (?, ?, ?)", [1, 0, "_bx_cnv_folder_inbox"])
    Repo.execute("INSERT INTO bx_convos_folders (id, author, name) VALUES (?, ?, ?)", [2, 0, "_bx_cnv_folder_drafts"])
    Repo.execute("INSERT INTO bx_convos_folders (id, author, name) VALUES (?, ?, ?)", [3, 0, "_bx_cnv_folder_spam"])
    Repo.execute("INSERT INTO bx_convos_folders (id, author, name) VALUES (?, ?, ?)", [4, 0, "_bx_cnv_folder_trash"])

    IO.puts("Registros inseridos com sucesso!")
  end
end
