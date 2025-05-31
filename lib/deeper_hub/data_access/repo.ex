defmodule DeeperHub.DataAccess.Repo do
  @moduledoc """
  Repositório principal do DeeperHub para acesso ao banco de dados SQLite.
  
  Este módulo utiliza o Ecto.Repo com o adaptador SQLite3 para fornecer
  uma camada de abstração para operações de banco de dados. Implementa
  a interface do DBConnection para garantir conexões eficientes e gerenciamento
  adequado de transações.
  """
  use Ecto.Repo,
    otp_app: :deeper_hub,
    adapter: Ecto.Adapters.SQLite3
end
