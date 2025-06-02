defmodule DeeperHub.WebInterface.Resources.BxFilesScores do
  @moduledoc """
  Recurso REST para bx_files_scores.
  Fornece endpoints para gerenciar bx_files_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesScores,
    resource_name: "bx_files_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
