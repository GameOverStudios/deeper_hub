defmodule Deeper_Hub.Core.Data.Repo do
  use Ecto.Repo,
    otp_app: :deeper_hub,
    adapter: Ecto.Adapters.SQLite3

  # Adiciona suporte à paginação com Scrivener
  use Scrivener, 
    page_size: Application.compile_env(:scrivener_ecto, :page_size, 10),
    max_page_size: Application.compile_env(:scrivener_ecto, :max_page_size, 100)
end
