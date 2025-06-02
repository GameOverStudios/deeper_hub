defmodule DeeperHub.WebInterface.Resources.BxFdbAnswers2users do
  @moduledoc """
  Recurso REST para bx_fdb_answers2users.
  Fornece endpoints para gerenciar bx_fdb_answers2users.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFdbAnswers2users,
    resource_name: "bx_fdb_answers2user"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
