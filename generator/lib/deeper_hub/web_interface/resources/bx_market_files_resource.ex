defmodule DeeperHub.WebInterface.Resources.BxMarketFiles do
  @moduledoc """
  Recurso REST para bx_market_files.
  Fornece endpoints para gerenciar bx_market_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketFiles,
    resource_name: "bx_market_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
