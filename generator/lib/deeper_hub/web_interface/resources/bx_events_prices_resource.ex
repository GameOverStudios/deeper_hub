defmodule DeeperHub.WebInterface.Resources.BxEventsPrices do
  @moduledoc """
  Recurso REST para bx_events_prices.
  Fornece endpoints para gerenciar bx_events_prices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsPrices,
    resource_name: "bx_events_price"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
