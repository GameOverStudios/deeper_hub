defmodule DeeperHub.WebInterface.Resources.BxConvosCmts do
  @moduledoc """
  Recurso REST para bx_convos_cmts.
  Fornece endpoints para gerenciar bx_convos_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxConvosCmts,
    resource_name: "bx_convos_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
