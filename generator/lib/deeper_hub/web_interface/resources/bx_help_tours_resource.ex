defmodule DeeperHub.WebInterface.Resources.BxHelpTours do
  @moduledoc """
  Recurso REST para bx_help_tours.
  Fornece endpoints para gerenciar bx_help_tours.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxHelpTours,
    resource_name: "bx_help_tour"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
