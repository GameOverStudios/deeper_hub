defmodule DeeperHub.WebInterface.Resources.BxOrganizationsPics do
  @moduledoc """
  Recurso REST para bx_organizations_pics.
  Fornece endpoints para gerenciar bx_organizations_pics.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsPics,
    resource_name: "bx_organizations_pic"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
