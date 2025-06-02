defmodule DeeperHub.WebInterface.Resources.BxSpacesPrices do
  @moduledoc """
  Recurso REST para bx_spaces_prices.
  Fornece endpoints para gerenciar bx_spaces_prices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesPrices,
    resource_name: "bx_spaces_price"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
