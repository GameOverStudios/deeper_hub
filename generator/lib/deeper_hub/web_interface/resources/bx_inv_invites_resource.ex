defmodule DeeperHub.WebInterface.Resources.BxInvInvites do
  @moduledoc """
  Recurso REST para bx_inv_invites.
  Fornece endpoints para gerenciar bx_inv_invites.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxInvInvites,
    resource_name: "bx_inv_invite"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
