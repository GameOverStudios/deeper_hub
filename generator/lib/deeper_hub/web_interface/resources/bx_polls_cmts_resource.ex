defmodule DeeperHub.WebInterface.Resources.BxPollsCmts do
  @moduledoc """
  Recurso REST para bx_polls_cmts.
  Fornece endpoints para gerenciar bx_polls_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsCmts,
    resource_name: "bx_polls_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
