defmodule DeeperHub.WebInterface.Resources.BxAntispamBlockLog do
  @moduledoc """
  Recurso REST para bx_antispam_block_logs.
  Fornece endpoints para gerenciar bx_antispam_block_logs.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAntispamBlockLog,
    resource_name: "bx_antispam_block_log"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
