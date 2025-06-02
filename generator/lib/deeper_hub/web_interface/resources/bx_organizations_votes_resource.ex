defmodule DeeperHub.WebInterface.Resources.BxOrganizationsVotes do
  @moduledoc """
  Recurso REST para bx_organizations_votes.
  Fornece endpoints para gerenciar bx_organizations_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsVotes,
    resource_name: "bx_organizations_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
