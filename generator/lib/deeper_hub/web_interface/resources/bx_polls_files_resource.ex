defmodule DeeperHub.WebInterface.Resources.BxPollsFiles do
  @moduledoc """
  Recurso REST para bx_polls_files.
  Fornece endpoints para gerenciar bx_polls_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsFiles,
    resource_name: "bx_polls_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
