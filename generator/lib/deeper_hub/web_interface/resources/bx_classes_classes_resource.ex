defmodule DeeperHub.WebInterface.Resources.BxClassesClasses do
  @moduledoc """
  Recurso REST para bx_classes_classes.
  Fornece endpoints para gerenciar bx_classes_classes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesClasses,
    resource_name: "bx_classes_classe"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
