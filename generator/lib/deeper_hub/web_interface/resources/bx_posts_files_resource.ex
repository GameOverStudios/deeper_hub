defmodule DeeperHub.WebInterface.Resources.BxPostsFiles do
  @moduledoc """
  Recurso REST para bx_posts_files.
  Fornece endpoints para gerenciar bx_posts_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsFiles,
    resource_name: "bx_posts_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
