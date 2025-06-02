defmodule DeeperHub.WebInterface.Resources.BxClassesFiles do
  @moduledoc """
  Recurso REST para bx_classes_files.
  Fornece endpoints para gerenciar bx_classes_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesFiles,
    resource_name: "bx_classes_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
