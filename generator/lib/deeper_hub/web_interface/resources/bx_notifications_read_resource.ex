defmodule DeeperHub.WebInterface.Resources.BxNotificationsRead do
  @moduledoc """
  Recurso REST para bx_notifications_reads.
  Fornece endpoints para gerenciar bx_notifications_reads.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxNotificationsRead,
    resource_name: "bx_notifications_read"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
