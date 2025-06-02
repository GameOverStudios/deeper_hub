defmodule DeeperHub.WebInterface.Resources.BxFdbQuestions do
  @moduledoc """
  Recurso REST para bx_fdb_questions.
  Fornece endpoints para gerenciar bx_fdb_questions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFdbQuestions,
    resource_name: "bx_fdb_question"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
