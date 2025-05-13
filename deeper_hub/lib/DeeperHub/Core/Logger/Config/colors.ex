defmodule DeeperHub.Core.Logger.Config.Colors do
  @moduledoc """
  Configuração de cores para o Logger.

  Este módulo permite personalizar as cores usadas no Logger para diferentes
  níveis de log e componentes da mensagem de log.
  """

  @doc """
  Obtém a configuração de cores para o Logger.

  ## Retorno

  Um mapa com as configurações de cores:

  * `:level_colors` - Mapa com cores para cada nível de log
  * `:module_color` - Cor para o nome do módulo
  * `:timestamp_color` - Cor para o timestamp
  * `:default_color` - Cor padrão
  """
  def get_colors do
    %{
      level_colors: get_level_colors(),
      module_color: get_module_color(),
      timestamp_color: get_timestamp_color(),
      default_color: get_default_color()
    }
  end

  @doc """
  Obtém as cores para cada nível de log.

  Estas configurações podem ser sobrescritas via ConfigManager.

  ## Retorno

  Um mapa onde as chaves são os níveis de log e os valores são as cores correspondentes.
  As cores podem ser um átomo ou uma lista de átomos para combinações.
  """
  def get_level_colors do
    # Obter configuração do ConfigManager, se existir
    # Caso contrário, usar valores padrão
    default_colors = %{
      debug: :cyan,
      info: :green,
      warn: :yellow,
      error: :red,
      critical: [:red, :bright]
    }

    case get_config_value([:core, :logger, :colors, :levels]) do
      nil -> default_colors
      colors -> Map.merge(default_colors, colors)
    end
  end

  @doc """
  Obtém a cor para o nome do módulo.

  ## Retorno

  Um átomo ou lista de átomos representando a cor.
  """
  def get_module_color do
    get_config_value([:core, :logger, :colors, :module]) || [:blue, :bright]
  end

  @doc """
  Obtém a cor para o timestamp.

  ## Retorno

  Um átomo ou lista de átomos representando a cor.
  """
  def get_timestamp_color do
    get_config_value([:core, :logger, :colors, :timestamp]) || :white
  end

  @doc """
  Obtém a cor padrão para o texto.

  ## Retorno

  Um átomo ou lista de átomos representando a cor.
  """
  def get_default_color do
    get_config_value([:core, :logger, :colors, :default]) || :white
  end

  # Tenta obter um valor do ConfigManager, se existir
  # Se o módulo não estiver disponível ou a chave não existir, retorna nil
  defp get_config_value(key) do
    if Code.ensure_loaded?(DeeperHub.Core.ConfigManager.Facade) do
      DeeperHub.Core.ConfigManager.Facade.get(key, "global", nil)
    else
      nil
    end
  end
end
