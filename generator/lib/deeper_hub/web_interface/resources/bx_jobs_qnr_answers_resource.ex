defmodule DeeperHub.WebInterface.Resources.BxJobsQnrAnswers do
  @moduledoc """
  Recurso REST para bx_jobs_qnr_answers.
  Fornece endpoints para gerenciar bx_jobs_qnr_answers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsQnrAnswers,
    resource_name: "bx_jobs_qnr_answer"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
