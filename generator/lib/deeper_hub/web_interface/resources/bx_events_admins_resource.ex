defmodule DeeperHub.WebInterface.Resources.BxEventsAdmins do
  @moduledoc """
  Recurso REST para bx_events_admins.
  Fornece endpoints para gerenciar bx_events_admins.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsAdmins,
    resource_name: "bx_events_admin"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
