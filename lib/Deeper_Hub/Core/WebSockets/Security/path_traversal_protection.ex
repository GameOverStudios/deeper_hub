defmodule Deeper_Hub.Core.WebSockets.Security.PathTraversalProtection do
  @moduledoc """
  Proteção contra ataques de Path Traversal para WebSockets.
  
  Este módulo implementa mecanismos para prevenir ataques de Path Traversal
  em mensagens WebSocket que podem conter caminhos de arquivos ou diretórios.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Verifica se um caminho contém potenciais ataques de Path Traversal.
  
  ## Parâmetros
  
    - `path`: Caminho a ser verificado
  
  ## Retorno
  
    - `{:ok, path}` se o caminho for seguro
    - `{:error, reason}` se o caminho contiver sequências suspeitas
  """
  def check_path(path) when is_binary(path) do
    path_traversal_patterns = [
      ~r/\.\.\//,      # "../"
      ~r/\.\.\\\\/, # "..\\"
      ~r/~\//,         # "~/"
      ~r/~\\\\/, # "~\"
      ~r/%2e%2e%2f/i,  # "../" URL encoded
      ~r/%2e%2e/i,     # ".." URL encoded
      ~r/%5c/i         # "\" URL encoded
    ]
    
    case Enum.find(path_traversal_patterns, fn pattern -> Regex.match?(pattern, path) end) do
      nil ->
        {:ok, path}
        
      pattern ->
        Logger.warning("Possível ataque Path Traversal detectado", %{
          module: __MODULE__,
          pattern: inspect(pattern),
          path: path
        })
        
        {:error, "Caminho potencialmente malicioso detectado"}
    end
  end
  
  def check_path(paths) when is_list(paths) do
    # Verifica cada caminho na lista
    Enum.reduce_while(paths, {:ok, paths}, fn path, acc ->
      case check_path(path) do
        {:ok, _} -> {:cont, acc}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  
  def check_path(path) do
    {:ok, path}
  end
  
  @doc """
  Normaliza e sanitiza um caminho para prevenir ataques de Path Traversal.
  
  ## Parâmetros
  
    - `path`: Caminho a ser sanitizado
    - `base_dir`: Diretório base permitido (opcional)
  
  ## Retorno
  
    - `{:ok, sanitized_path}` com o caminho sanitizado
    - `{:error, reason}` se o caminho não puder ser sanitizado com segurança
  """
  def sanitize_path(path, base_dir \\ nil) when is_binary(path) do
    # Normaliza o caminho
    normalized_path = normalize_path(path)
    
    # Verifica se o caminho normalizado contém sequências suspeitas
    case check_path(normalized_path) do
      {:ok, _} ->
        # Se um diretório base foi fornecido, verifica se o caminho está contido nele
        if base_dir do
          ensure_within_base_dir(normalized_path, base_dir)
        else
          {:ok, normalized_path}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se um caminho está contido dentro de um diretório base.
  
  ## Parâmetros
  
    - `path`: Caminho a ser verificado
    - `base_dir`: Diretório base permitido
  
  ## Retorno
  
    - `{:ok, path}` se o caminho estiver dentro do diretório base
    - `{:error, reason}` se o caminho estiver fora do diretório base
  """
  def ensure_within_base_dir(path, base_dir) when is_binary(path) and is_binary(base_dir) do
    # Normaliza ambos os caminhos
    normalized_path = normalize_path(path)
    normalized_base = normalize_path(base_dir)
    
    # Verifica se o caminho normalizado começa com o diretório base
    if String.starts_with?(normalized_path, normalized_base) do
      {:ok, normalized_path}
    else
      Logger.warning("Tentativa de acesso a caminho fora do diretório base", %{
        module: __MODULE__,
        path: path,
        base_dir: base_dir
      })
      
      {:error, "Caminho fora do diretório base permitido"}
    end
  end
  
  # Funções privadas para normalização de caminhos
  
  defp normalize_path(path) do
    # Remove caracteres de controle
    path = String.replace(path, ~r/[\x00-\x1F\x7F]/, "")
    
    # Substitui múltiplas barras por uma única
    path = String.replace(path, ~r/\/+/, "/")
    path = String.replace(path, ~r/\\+/, "\\")
    
    # Converte todas as barras para o formato do sistema operacional
    path = if :os.type() == {:win32, :nt} do
      String.replace(path, "/", "\\")
    else
      String.replace(path, "\\", "/")
    end
    
    # Resolve componentes do caminho (como ".." e ".")
    # Esta é uma implementação simplificada
    segments = String.split(path, if :os.type() == {:win32, :nt}, do: "\\", else: "/")
    resolved = resolve_path_segments(segments)
    
    # Reconstrói o caminho
    Enum.join(resolved, if :os.type() == {:win32, :nt}, do: "\\", else: "/")
  end
  
  defp resolve_path_segments(segments) do
    Enum.reduce(segments, [], fn segment, acc ->
      case segment do
        "." -> 
          # Ignora segmentos "."
          acc
          
        ".." -> 
          # Remove o último segmento para segmentos ".."
          if length(acc) > 0, do: Enum.drop(acc, -1), else: acc
          
        "" -> 
          # Mantém segmentos vazios apenas no início (para caminhos absolutos)
          if acc == [], do: ["" | acc], else: acc
          
        _ -> 
          # Adiciona segmentos normais
          acc ++ [segment]
      end
    end)
  end
end
