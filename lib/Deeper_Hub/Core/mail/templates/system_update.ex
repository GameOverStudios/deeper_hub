defmodule DeeperHub.Core.Mail.Templates.SystemUpdate do
  @moduledoc """
  Template de email para notificações de atualizações do sistema.
  
  Este módulo fornece funções para renderizar templates de email
  para informar usuários sobre atualizações, novos recursos, 
  manutenções programadas e outras alterações no sistema.
  """
  
  @doc """
  Renderiza o template HTML para um email de notificação de atualização do sistema.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:user_name` - Nome do usuário
    - `:update_type` - Tipo de atualização (nova versão, manutenção, etc)
    - `:update_title` - Título da atualização
    - `:update_details` - Detalhes da atualização (texto ou HTML)
    - `:update_date` - Data da atualização
    - `:new_features` - Lista de novos recursos (opcional)
    - `:fixed_issues` - Lista de problemas corrigidos (opcional)
    - `:maintenance_window` - Janela de manutenção (opcional)
    - `:action_link` - Link para ação relacionada (opcional)
    - `:action_text` - Texto para o botão de ação (opcional)
    - `:app_name` - Nome da aplicação
    - `:support_email` - Email de suporte
    - `:current_year` - Ano atual
  
  ## Retorno
  
  - String HTML do template renderizado
  """
  def render_html(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      user_name: "Usuário",
      update_type: "atualização",
      update_title: "Atualização do Sistema",
      update_details: "Detalhes da atualização do sistema.",
      update_date: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y"),
      new_features: [],
      fixed_issues: [],
      maintenance_window: nil,
      action_link: nil,
      action_text: "Saiba Mais",
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Gera os itens da lista de novos recursos
    new_features_html = if length(assigns.new_features) > 0 do
      features = assigns.new_features
      |> Enum.map(fn feature -> "<li>#{feature}</li>" end)
      |> Enum.join("\n            ")
      
      """
      <div class="section">
        <h3>Novos Recursos</h3>
        <ul>
            #{features}
        </ul>
      </div>
      """
    else
      ""
    end
    
    # Gera os itens da lista de problemas corrigidos
    fixed_issues_html = if length(assigns.fixed_issues) > 0 do
      issues = assigns.fixed_issues
      |> Enum.map(fn issue -> "<li>#{issue}</li>" end)
      |> Enum.join("\n            ")
      
      """
      <div class="section">
        <h3>Problemas Corrigidos</h3>
        <ul>
            #{issues}
        </ul>
      </div>
      """
    else
      ""
    end
    
    # Gera a seção de janela de manutenção
    maintenance_html = if assigns.maintenance_window do
      """
      <div class="maintenance-info">
        <h3>Janela de Manutenção</h3>
        <p>#{assigns.maintenance_window}</p>
        <p>Durante este período, o sistema pode ficar temporariamente indisponível.</p>
      </div>
      """
    else
      ""
    end
    
    # Gera o botão de ação
    action_button_html = if assigns.action_link do
      """
      <div style="text-align: center; margin: 25px 0;">
        <a href="#{assigns.action_link}" class="button">#{assigns.action_text}</a>
      </div>
      """
    else
      ""
    end
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>#{assigns.update_title} - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4285F4; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .button { display: inline-block; background-color: #4285F4; color: white; padding: 10px 20px; 
                 text-decoration: none; border-radius: 4px; margin: 20px 0; font-weight: bold; }
        .section { margin: 20px 0; }
        .maintenance-info { background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 15px 0; }
        .update-badge { display: inline-block; padding: 5px 10px; border-radius: 3px; color: white; 
                       background-color: #4285F4; font-weight: bold; font-size: 14px; }
        h1 { margin: 0; font-size: 22px; }
        h3 { color: #4285F4; margin-bottom: 10px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>#{assigns.update_title}</h1>
        </div>
        <div class="content">
          <p>Olá, <strong>#{assigns.user_name}</strong>!</p>
          
          <p>
            <span class="update-badge">#{String.capitalize(assigns.update_type)}</span>
            <span style="margin-left: 10px;">#{assigns.update_date}</span>
          </p>
          
          <div class="section">
            <p>#{assigns.update_details}</p>
          </div>
          
          #{new_features_html}
          
          #{fixed_issues_html}
          
          #{maintenance_html}
          
          #{action_button_html}
          
          <p>Agradecemos por usar o #{assigns.app_name}!</p>
          
          <p>Atenciosamente,<br>Equipe #{assigns.app_name}</p>
        </div>
        <div class="footer">
          <p>&copy; #{assigns.current_year} #{assigns.app_name}. Todos os direitos reservados.</p>
          <p>Para suporte, contate <a href="mailto:#{assigns.support_email}">#{assigns.support_email}</a></p>
        </div>
      </div>
    </body>
    </html>
    """
  end
  
  @doc """
  Renderiza o template de texto plano para um email de notificação de atualização do sistema.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:user_name` - Nome do usuário
    - `:update_type` - Tipo de atualização (nova versão, manutenção, etc)
    - `:update_title` - Título da atualização
    - `:update_details` - Detalhes da atualização
    - `:update_date` - Data da atualização
    - `:new_features` - Lista de novos recursos (opcional)
    - `:fixed_issues` - Lista de problemas corrigidos (opcional)
    - `:maintenance_window` - Janela de manutenção (opcional)
    - `:action_link` - Link para ação relacionada (opcional)
    - `:action_text` - Texto para o link de ação (opcional)
    - `:app_name` - Nome da aplicação
    - `:support_email` - Email de suporte
    - `:current_year` - Ano atual
  
  ## Retorno
  
  - String de texto plano do template renderizado
  """
  def render_text(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      user_name: "Usuário",
      update_type: "atualização",
      update_title: "Atualização do Sistema",
      update_details: "Detalhes da atualização do sistema.",
      update_date: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y"),
      new_features: [],
      fixed_issues: [],
      maintenance_window: nil,
      action_link: nil,
      action_text: "Saiba Mais",
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Gera os itens da lista de novos recursos
    new_features_text = if length(assigns.new_features) > 0 do
      features = assigns.new_features
      |> Enum.map(fn feature -> "- #{feature}" end)
      |> Enum.join("\n")
      
      """
      
      NOVOS RECURSOS:
      #{features}
      """
    else
      ""
    end
    
    # Gera os itens da lista de problemas corrigidos
    fixed_issues_text = if length(assigns.fixed_issues) > 0 do
      issues = assigns.fixed_issues
      |> Enum.map(fn issue -> "- #{issue}" end)
      |> Enum.join("\n")
      
      """
      
      PROBLEMAS CORRIGIDOS:
      #{issues}
      """
    else
      ""
    end
    
    # Gera a seção de janela de manutenção
    maintenance_text = if assigns.maintenance_window do
      """
      
      JANELA DE MANUTENÇÃO:
      #{assigns.maintenance_window}
      Durante este período, o sistema pode ficar temporariamente indisponível.
      """
    else
      ""
    end
    
    # Gera o link de ação
    action_text = if assigns.action_link do
      """
      
      #{assigns.action_text}: #{assigns.action_link}
      """
    else
      ""
    end
    
    """
    #{assigns.update_title} - #{assigns.app_name}
    
    Olá, #{assigns.user_name}!
    
    #{String.upcase(assigns.update_type)} - #{assigns.update_date}
    
    #{assigns.update_details}
    #{new_features_text}
    #{fixed_issues_text}
    #{maintenance_text}
    #{action_text}
    
    Agradecemos por usar o #{assigns.app_name}!
    
    Atenciosamente,
    Equipe #{assigns.app_name}
    
    --
    © #{assigns.current_year} #{assigns.app_name}. Todos os direitos reservados.
    Para suporte, contate #{assigns.support_email}
    """
  end
  
  # Obtém o email de suporte das configurações
  defp get_support_email do
    Application.get_env(:deeper_hub, :mail, [])
    |> Keyword.get(:support_email, "suporte@deeperhub.com")
  end
end
