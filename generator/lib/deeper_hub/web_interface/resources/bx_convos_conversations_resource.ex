defmodule DeeperHub.WebInterface.Resources.BxConvosConversations do
  @moduledoc """
  Recurso REST para bx_convos_conversations.
  Fornece endpoints para gerenciar bx_convos_conversations.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxConvosConversations,
    resource_name: "bx_convos_conversation"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
