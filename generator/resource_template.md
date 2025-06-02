defmodule DeeperHub.WebInterface.Resources.{{MODULE_NAME}} do
  @moduledoc """
  Recurso REST para {{SINGULAR_NAME}}s.
  Fornece endpoints para gerenciar {{SINGULAR_NAME}}s.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.{{MODULE_NAME}},
    resource_name: "{{SINGULAR_NAME}}"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
