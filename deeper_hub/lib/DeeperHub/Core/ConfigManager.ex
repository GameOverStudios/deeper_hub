defmodule DeeperHub.Core.ConfigManager do
  @moduledoc """
  Serviço centralizado para gerenciar e acessar todas as configurações do sistema DeeperHub.

  Este módulo abstrai a origem das configurações (arquivos de configuração, banco de dados,
  variáveis de ambiente), fornecendo uma interface unificada para todos os outros módulos.

  Permite que configurações sejam alteradas em tempo de execução e notifica outros
  componentes do sistema sobre essas mudanças.
  """

  # Delegamos todas as chamadas públicas para a fachada
  defdelegate get(key, scope \\ "global", default \\ nil), to: DeeperHub.Core.ConfigManager.Facade
  defdelegate get_config(keys, default \\ nil), to: DeeperHub.Core.ConfigManager.Facade
  defdelegate set(key, value, opts \\ []), to: DeeperHub.Core.ConfigManager.Facade
  defdelegate delete(key, scope \\ "global", opts \\ []), to: DeeperHub.Core.ConfigManager.Facade
  defdelegate subscribe(event_key_pattern, subscriber), to: DeeperHub.Core.ConfigManager.Facade
end
