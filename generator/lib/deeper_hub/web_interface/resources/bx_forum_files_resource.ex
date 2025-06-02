defmodule DeeperHub.WebInterface.Resources.BxForumFiles do
  @moduledoc """
  Recurso REST para bx_forum_files.
  Fornece endpoints para gerenciar bx_forum_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumFiles,
    resource_name: "bx_forum_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
