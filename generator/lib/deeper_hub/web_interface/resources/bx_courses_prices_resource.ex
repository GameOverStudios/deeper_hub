defmodule DeeperHub.WebInterface.Resources.BxCoursesPrices do
  @moduledoc """
  Recurso REST para bx_courses_prices.
  Fornece endpoints para gerenciar bx_courses_prices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesPrices,
    resource_name: "bx_courses_price"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
