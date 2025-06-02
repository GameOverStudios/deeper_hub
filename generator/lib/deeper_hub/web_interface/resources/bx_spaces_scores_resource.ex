defmodule DeeperHub.WebInterface.Resources.BxSpacesScores do
  @moduledoc """
  Recurso REST para bx_spaces_scores.
  Fornece endpoints para gerenciar bx_spaces_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesScores,
    resource_name: "bx_spaces_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
