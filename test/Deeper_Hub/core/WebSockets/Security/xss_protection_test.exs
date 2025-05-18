defmodule Deeper_Hub.Core.WebSockets.Security.XssProtectionTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.XssProtection
  
  describe "sanitize_message/1" do
    test "sanitiza strings com potencial XSS" do
      # Teste com string contendo script
      input = "<script>alert('XSS')</script>"
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      refute String.contains?(sanitized, "<script>")
      assert String.contains?(sanitized, "&lt;script&gt;")
      
      # Teste com string contendo evento onclick
      input = "<div onclick=\"alert('XSS')\">Click me</div>"
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      refute String.contains?(sanitized, "onclick")
      assert String.contains?(sanitized, "&lt;div")
      
      # Teste com string contendo iframe
      input = "<iframe src=\"javascript:alert('XSS')\"></iframe>"
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      refute String.contains?(sanitized, "<iframe")
      assert String.contains?(sanitized, "&lt;iframe")
    end
    
    test "sanitiza mapas com valores contendo XSS" do
      # Teste com mapa contendo valores com potencial XSS
      input = %{
        "content" => "<script>alert('XSS')</script>",
        "title" => "<img src=\"x\" onerror=\"alert('XSS')\">"
      }
      
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      refute String.contains?(sanitized["content"], "<script>")
      assert String.contains?(sanitized["content"], "&lt;script&gt;")
      
      refute String.contains?(sanitized["title"], "onerror")
      assert String.contains?(sanitized["title"], "&lt;img")
    end
    
    test "sanitiza mapas aninhados com valores contendo XSS" do
      # Cria um mapa com valores potencialmente perigosos
      message = %{
        "user" => %{
          "name" => "John",
          "website" => "javascript:alert('XSS')"
        },
        "message" => "Hello"
      }
      
      # Sanitiza o mapa
      {:ok, sanitized} = XssProtection.sanitize_message(message)
      
      # Verifica que o conteúdo foi sanitizado
      assert sanitized["user"]["name"] == "John"
      # Verifica que o javascript: foi substituído, mas não necessariamente por "removed:"
      # já que a sanitização pode usar diferentes métodos
      refute String.contains?(sanitized["user"]["website"], "javascript:")
      assert sanitized["message"] == "Hello"
    end
    
    test "sanitiza listas com valores contendo XSS" do
      # Cria uma lista com valores potencialmente perigosos
      message = [
        "<script>alert('XSS')</script>",
        "Hello",
        "<img src=x onerror=alert('XSS')>"
      ]
      
      # Sanitiza a lista
      {:ok, sanitized} = XssProtection.sanitize_message(message)
      
      # Verifica que o conteúdo foi sanitizado
      [item0, item1, item2] = sanitized
      
      # Verificamos que o script foi sanitizado de alguma forma
      refute String.contains?(item0, "<script>") # Não deve conter a tag script original
      assert item1 == "Hello" # O item sem XSS não deve ser alterado
      # Verificamos que o atributo onerror foi removido ou substituído
      refute String.contains?(item2, "onerror=")
    end
    
    test "não modifica valores que não contêm XSS" do
      # Teste com string segura
      input = "Hello, world!"
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      assert sanitized == input
      
      # Teste com mapa contendo valores seguros
      input = %{
        "content" => "Hello, world!",
        "title" => "Welcome"
      }
      
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      assert sanitized["content"] == input["content"]
      assert sanitized["title"] == input["title"]
    end
  end
  
  describe "check_for_xss/1" do
    test "detecta strings com potencial XSS" do
      # Teste com script
      assert {:error, _} = XssProtection.check_for_xss("<script>alert('XSS')</script>")
      
      # Teste com javascript:
      assert {:error, _} = XssProtection.check_for_xss("javascript:alert('XSS')")
      
      # Teste com evento onclick
      assert {:error, _} = XssProtection.check_for_xss("<div onclick=\"alert('XSS')\">Click me</div>")
      
      # Teste com iframe
      assert {:error, _} = XssProtection.check_for_xss("<iframe src=\"javascript:alert('XSS')\"></iframe>")
      
      # Teste com eval
      assert {:error, _} = XssProtection.check_for_xss("eval('alert(\"XSS\")')")
    end
    
    test "permite strings sem XSS" do
      # Teste com texto normal
      assert {:ok, _} = XssProtection.check_for_xss("Hello, world!")
      
      # Teste com HTML seguro
      assert {:ok, _} = XssProtection.check_for_xss("<p>Hello, <b>world</b>!</p>")
      
      # Teste com URL segura
      assert {:ok, _} = XssProtection.check_for_xss("https://example.com")
    end
    
    test "detecta XSS em mapas" do
      # Teste com mapa contendo XSS
      input = %{
        "content" => "Hello, world!",
        "title" => "<script>alert('XSS')</script>"
      }
      
      assert {:error, _} = XssProtection.check_for_xss(input)
    end
    
    test "detecta XSS em listas" do
      # Teste com lista contendo XSS
      input = [
        "Hello, world!",
        "<script>alert('XSS')</script>"
      ]
      
      assert {:error, _} = XssProtection.check_for_xss(input)
    end
    
    test "permite mapas sem XSS" do
      # Teste com mapa sem XSS
      input = %{
        "content" => "Hello, world!",
        "title" => "Welcome"
      }
      
      assert {:ok, _} = XssProtection.check_for_xss(input)
    end
    
    test "permite listas sem XSS" do
      # Teste com lista sem XSS
      input = [
        "Hello, world!",
        "Welcome"
      ]
      
      assert {:ok, _} = XssProtection.check_for_xss(input)
    end
  end
end
