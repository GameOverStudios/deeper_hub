defmodule DeeperHub.WebInterface.Resources.BxConvosConv2folder do
  @moduledoc """
  Recurso REST para bx_convos_conv2folders.
  Fornece endpoints para gerenciar bx_convos_conv2folders.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxConvosConv2folder,
    resource_name: "bx_convos_conv2folder"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
