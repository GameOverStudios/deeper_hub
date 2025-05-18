defmodule Deeper_Hub.Core.WebSockets.Security.PathTraversalProtectionTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.PathTraversalProtection
  
  describe "check_path/1" do
    test "detecta caminhos com potencial Path Traversal" do
      # Teste com ../
      assert {:error, _} = PathTraversalProtection.check_path("../config/config.exs")
      
      # Teste com ..\\
      assert {:error, _} = PathTraversalProtection.check_path("..\\config\\config.exs")
      
      # Teste com ~/
      assert {:error, _} = PathTraversalProtection.check_path("~/config/config.exs")
      
      # Teste com URL encoded ../
      assert {:error, _} = PathTraversalProtection.check_path("%2e%2e%2fconfig%2fconfig.exs")
      
      # Teste com URL encoded ..
      assert {:error, _} = PathTraversalProtection.check_path("%2e%2e/config/config.exs")
    end
    
    test "permite caminhos sem Path Traversal" do
      # Teste com caminho absoluto
      assert {:ok, _} = PathTraversalProtection.check_path("/var/www/html/index.html")
      
      # Teste com caminho relativo sem traversal
      assert {:ok, _} = PathTraversalProtection.check_path("images/logo.png")
      
      # Teste com caminho Windows
      assert {:ok, _} = PathTraversalProtection.check_path("C:\\Users\\Public\\Documents\\file.txt")
    end
    
    test "detecta Path Traversal em listas de caminhos" do
      # Teste com lista contendo Path Traversal
      input = [
        "/var/www/html/index.html",
        "../config/config.exs"
      ]
      
      assert {:error, _} = PathTraversalProtection.check_path(input)
    end
    
    test "permite listas sem Path Traversal" do
      # Teste com lista sem Path Traversal
      input = [
        "/var/www/html/index.html",
        "/var/www/html/images/logo.png"
      ]
      
      assert {:ok, _} = PathTraversalProtection.check_path(input)
    end
  end
  
  describe "sanitize_path/2" do
    test "sanitiza caminhos com potencial Path Traversal" do
      # Teste com ../
      input = "../config/config.exs"
      assert {:error, _} = PathTraversalProtection.sanitize_path(input)
      
      # Teste com múltiplos ../
      input = "../../config/config.exs"
      assert {:error, _} = PathTraversalProtection.sanitize_path(input)
      
      # Teste com ../ no meio do caminho
      input = "uploads/../config/config.exs"
      assert {:error, _} = PathTraversalProtection.sanitize_path(input)
    end
    
    test "normaliza caminhos válidos" do
      # Teste com caminho com ./
      input = "./uploads/file.txt"
      {:ok, sanitized} = PathTraversalProtection.sanitize_path(input)
      
      assert sanitized == "uploads/file.txt"
      
      # Teste com barras múltiplas
      input = "uploads//file.txt"
      {:ok, sanitized} = PathTraversalProtection.sanitize_path(input)
      
      assert sanitized == "uploads/file.txt"
    end
    
    test "verifica se o caminho está dentro do diretório base" do
      # Teste com caminho dentro do diretório base
      base_dir = "/var/www"
      input = "/var/www/html/index.html"
      
      assert {:ok, _} = PathTraversalProtection.sanitize_path(input, base_dir)
      
      # Teste com caminho fora do diretório base
      base_dir = "/var/www"
      input = "/etc/passwd"
      
      assert {:error, _} = PathTraversalProtection.sanitize_path(input, base_dir)
    end
  end
  
  describe "ensure_within_base_dir/2" do
    test "permite caminhos dentro do diretório base" do
      # Teste com caminho dentro do diretório base
      base_dir = "/var/www"
      input = "/var/www/html/index.html"
      
      assert {:ok, _} = PathTraversalProtection.ensure_within_base_dir(input, base_dir)
      
      # Teste com caminho exatamente igual ao diretório base
      base_dir = "/var/www"
      input = "/var/www"
      
      assert {:ok, _} = PathTraversalProtection.ensure_within_base_dir(input, base_dir)
    end
    
    test "rejeita caminhos fora do diretório base" do
      # Teste com caminho fora do diretório base
      base_dir = "/var/www"
      input = "/etc/passwd"
      
      assert {:error, _} = PathTraversalProtection.ensure_within_base_dir(input, base_dir)
      
      # Teste com caminho que parece estar dentro, mas não está
      base_dir = "/var/www"
      input = "/var/www2/index.html"
      
      assert {:error, _} = PathTraversalProtection.ensure_within_base_dir(input, base_dir)
    end
    
    test "normaliza caminhos antes de verificar" do
      # Teste com caminho que contém ./ e barras múltiplas
      base_dir = "/var/www"
      input = "/var/www/./html//index.html"
      
      assert {:ok, normalized} = PathTraversalProtection.ensure_within_base_dir(input, base_dir)
      assert normalized == "/var/www/html/index.html"
    end
  end
end
