defmodule DeeperHub.WebInterface.Resources.BxClassesReactions do
  @moduledoc """
  Recurso REST para bx_classes_reactions.
  Fornece endpoints para gerenciar bx_classes_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesReactions,
    resource_name: "bx_classes_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
