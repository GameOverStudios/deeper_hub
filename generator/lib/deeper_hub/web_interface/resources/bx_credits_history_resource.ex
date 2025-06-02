defmodule DeeperHub.WebInterface.Resources.BxCreditsHistory do
  @moduledoc """
  Recurso REST para bx_credits_historys.
  Fornece endpoints para gerenciar bx_credits_historys.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCreditsHistory,
    resource_name: "bx_credits_history"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
