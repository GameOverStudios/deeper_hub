defmodule DeeperHub.WebInterface.Resources.BxSpacesCmts do
  @moduledoc """
  Recurso REST para bx_spaces_cmts.
  Fornece endpoints para gerenciar bx_spaces_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesCmts,
    resource_name: "bx_spaces_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
