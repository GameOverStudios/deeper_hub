defmodule DeeperHub.WebInterface.Resources.BxGlossaryScores do
  @moduledoc """
  Recurso REST para bx_glossary_scores.
  Fornece endpoints para gerenciar bx_glossary_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGlossaryScores,
    resource_name: "bx_glossary_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
