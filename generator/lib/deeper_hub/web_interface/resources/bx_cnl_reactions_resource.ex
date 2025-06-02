defmodule DeeperHub.WebInterface.Resources.BxCnlReactions do
  @moduledoc """
  Recurso REST para bx_cnl_reactions.
  Fornece endpoints para gerenciar bx_cnl_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCnlReactions,
    resource_name: "bx_cnl_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
