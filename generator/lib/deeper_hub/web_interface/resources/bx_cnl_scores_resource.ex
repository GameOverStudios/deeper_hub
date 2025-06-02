defmodule DeeperHub.WebInterface.Resources.BxCnlScores do
  @moduledoc """
  Recurso REST para bx_cnl_scores.
  Fornece endpoints para gerenciar bx_cnl_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCnlScores,
    resource_name: "bx_cnl_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
