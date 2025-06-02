defmodule DeeperHub.WebInterface.Resources.BxTasksMetaKeywords do
  @moduledoc """
  Recurso REST para bx_tasks_meta_keywords.
  Fornece endpoints para gerenciar bx_tasks_meta_keywords.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksMetaKeywords,
    resource_name: "bx_tasks_meta_keyword"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
