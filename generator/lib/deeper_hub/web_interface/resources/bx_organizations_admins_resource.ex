defmodule DeeperHub.WebInterface.Resources.BxOrganizationsAdmins do
  @moduledoc """
  Recurso REST para bx_organizations_admins.
  Fornece endpoints para gerenciar bx_organizations_admins.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsAdmins,
    resource_name: "bx_organizations_admin"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
