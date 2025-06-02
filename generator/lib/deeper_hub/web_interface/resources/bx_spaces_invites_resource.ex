defmodule DeeperHub.WebInterface.Resources.BxSpacesInvites do
  @moduledoc """
  Recurso REST para bx_spaces_invites.
  Fornece endpoints para gerenciar bx_spaces_invites.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesInvites,
    resource_name: "bx_spaces_invite"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
