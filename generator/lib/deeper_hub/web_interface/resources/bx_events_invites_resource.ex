defmodule DeeperHub.WebInterface.Resources.BxEventsInvites do
  @moduledoc """
  Recurso REST para bx_events_invites.
  Fornece endpoints para gerenciar bx_events_invites.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsInvites,
    resource_name: "bx_events_invite"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
