defmodule DeeperHub.WebInterface.Resources.BxForumSubscribers do
  @moduledoc """
  Recurso REST para bx_forum_subscribers.
  Fornece endpoints para gerenciar bx_forum_subscribers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumSubscribers,
    resource_name: "bx_forum_subscriber"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
