defmodule DeeperHub.WebInterface.Resources.BxOrganizationsReactions do
  @moduledoc """
  Recurso REST para bx_organizations_reactions.
  Fornece endpoints para gerenciar bx_organizations_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsReactions,
    resource_name: "bx_organizations_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
