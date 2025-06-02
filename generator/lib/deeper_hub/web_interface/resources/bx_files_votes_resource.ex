defmodule DeeperHub.WebInterface.Resources.BxFilesVotes do
  @moduledoc """
  Recurso REST para bx_files_votes.
  Fornece endpoints para gerenciar bx_files_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesVotes,
    resource_name: "bx_files_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
