defmodule DeeperHub.WebInterface.Resources.BxForumPolls do
  @moduledoc """
  Recurso REST para bx_forum_polls.
  Fornece endpoints para gerenciar bx_forum_polls.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumPolls,
    resource_name: "bx_forum_poll"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
