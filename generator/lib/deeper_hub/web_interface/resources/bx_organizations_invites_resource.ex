defmodule DeeperHub.WebInterface.Resources.BxOrganizationsInvites do
  @moduledoc """
  Recurso REST para bx_organizations_invites.
  Fornece endpoints para gerenciar bx_organizations_invites.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsInvites,
    resource_name: "bx_organizations_invite"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
