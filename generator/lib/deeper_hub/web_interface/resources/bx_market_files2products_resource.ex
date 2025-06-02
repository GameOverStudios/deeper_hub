defmodule DeeperHub.WebInterface.Resources.BxMarketFiles2products do
  @moduledoc """
  Recurso REST para bx_market_files2products.
  Fornece endpoints para gerenciar bx_market_files2products.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketFiles2products,
    resource_name: "bx_market_files2product"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
