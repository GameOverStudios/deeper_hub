defmodule DeeperHub.WebInterface.Resources.BxPhotosCmts do
  @moduledoc """
  Recurso REST para bx_photos_cmts.
  Fornece endpoints para gerenciar bx_photos_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosCmts,
    resource_name: "bx_photos_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
