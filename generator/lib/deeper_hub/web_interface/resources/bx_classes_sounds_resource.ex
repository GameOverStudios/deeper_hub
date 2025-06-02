defmodule DeeperHub.WebInterface.Resources.BxClassesSounds do
  @moduledoc """
  Recurso REST para bx_classes_sounds.
  Fornece endpoints para gerenciar bx_classes_sounds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesSounds,
    resource_name: "bx_classes_sound"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
