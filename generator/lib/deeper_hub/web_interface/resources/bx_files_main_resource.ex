defmodule DeeperHub.WebInterface.Resources.BxFilesMain do
  @moduledoc """
  Recurso REST para bx_files_mains.
  Fornece endpoints para gerenciar bx_files_mains.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesMain,
    resource_name: "bx_files_main"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
