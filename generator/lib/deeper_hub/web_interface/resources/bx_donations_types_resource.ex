defmodule DeeperHub.WebInterface.Resources.BxDonationsTypes do
  @moduledoc """
  Recurso REST para bx_donations_types.
  Fornece endpoints para gerenciar bx_donations_types.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxDonationsTypes,
    resource_name: "bx_donations_type"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
