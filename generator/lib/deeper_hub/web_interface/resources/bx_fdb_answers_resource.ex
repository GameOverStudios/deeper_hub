defmodule DeeperHub.WebInterface.Resources.BxFdbAnswers do
  @moduledoc """
  Recurso REST para bx_fdb_answers.
  Fornece endpoints para gerenciar bx_fdb_answers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFdbAnswers,
    resource_name: "bx_fdb_answer"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
