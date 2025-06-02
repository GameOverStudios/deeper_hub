defmodule DeeperHub.WebInterface.Resources.BxCnlVotes do
  @moduledoc """
  Recurso REST para bx_cnl_votes.
  Fornece endpoints para gerenciar bx_cnl_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCnlVotes,
    resource_name: "bx_cnl_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
