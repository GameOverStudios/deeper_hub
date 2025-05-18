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
      # Teste com mapa aninhado contendo valores com potencial XSS
      input = %{
        "user" => %{
          "bio" => "<script>alert('XSS')</script>",
          "website" => "javascript:alert('XSS')"
        }
      }
      
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      refute String.contains?(sanitized["user"]["bio"], "<script>")
      assert String.contains?(sanitized["user"]["bio"], "&lt;script&gt;")
      
      # O texto "javascript:" é substituído por "removed:" na implementação atual
      refute String.contains?(sanitized["user"]["website"], "javascript:")
      assert String.contains?(sanitized["user"]["website"], "removed:")
    end
    
    test "sanitiza listas com valores contendo XSS" do
      # Teste com lista contendo valores com potencial XSS
      input = [
        "<script>alert('XSS')</script>",
        "<img src=\"x\" onerror=\"alert('XSS')\">"
      ]
      
      {:ok, sanitized} = XssProtection.sanitize_message(input)
      
      # Verificamos que o script foi sanitizado
      # Na implementação atual, <script> é substituído por &lt;script
      item0 = Enum.at(sanitized, 0)
      refute String.contains?(item0, "<script>")
      assert String.contains?(item0, "&lt;script")
      
      # Verificamos que o atributo onerror foi removido
      item1 = Enum.at(sanitized, 1)
      refute String.contains?(item1, "onerror")
      assert String.contains?(item1, "data-removed=")
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
