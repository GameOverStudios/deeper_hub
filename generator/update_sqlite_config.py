import os
import re
import shutil
from datetime import datetime

def backup_file(file_path):
    """Cria um backup do arquivo antes de modificá-lo"""
    if os.path.exists(file_path):
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        backup_path = f"{file_path}.{timestamp}.bak"
        shutil.copy2(file_path, backup_path)
        print(f"Backup criado: {backup_path}")
        return True
    return False

def update_config_file(config_path):
    """Atualiza o arquivo de configuração com otimizações para SQLite"""
    print(f"Atualizando arquivo de configuração: {config_path}")
    
    if not os.path.exists(config_path):
        print(f"Erro: Arquivo {config_path} não encontrado.")
        return False
    
    # Fazer backup do arquivo original
    backup_file(config_path)
    
    # Ler o conteúdo do arquivo
    with open(config_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Padrão para encontrar a configuração do Repo
    repo_config_pattern = r'config :deeper_hub, DeeperHub\.Core\.Data\.Repo,(.*?)(?=config :|$)'
    
    # Buscar a configuração atual
    match = re.search(repo_config_pattern, content, re.DOTALL)
    if not match:
        print("Configuração do Repo não encontrada no arquivo.")
        return False
    
    # Configuração atual
    current_config = match.group(0)
    print("\nConfiguração atual encontrada:")
    print(current_config)
    
    # Nova configuração otimizada
    new_config = """config :deeper_hub, DeeperHub.Core.Data.Repo,
  # Configuração para db_connection e exqlite
  database: System.get_env("DEEPER_HUB_DB_PATH", "databases/deeper_hub_dev.db"),
  pool_name: DeeperHub.DBConnectionPool,
  pool_size: String.to_integer(System.get_env("DEEPER_HUB_DB_POOL_SIZE", "20")),
  # Write-Ahead Logging para melhor concorrência
  journal_mode: :wal,
  # Quanto tempo esperar se o banco de dados estiver bloqueado
  busy_timeout: 5000,
  # Timeout para operações de banco de dados
  timeout: 30_000,
  # Intervalo para ping em conexões ociosas
  idle_interval: 15_000,
  # Pragmas otimizados para desempenho máximo
  pragmas: [
    foreign_keys: "ON",
    synchronous: "NORMAL", 
    cache_size: "-10000",    # 10MB de cache
    temp_store: "MEMORY",    # Armazena tabelas temporárias na memória
    mmap_size: "30000000000", # 30GB para memory mapping
    auto_vacuum: "INCREMENTAL",
    read_uncommitted: "1"    # Permite leitura de transações não confirmadas
  ]

"""
    
    # Substituir a configuração antiga pela nova
    updated_content = content.replace(current_config, new_config)
    
    # Salvar o arquivo atualizado
    with open(config_path, 'w', encoding='utf-8') as file:
        file.write(updated_content)
    
    print("\nArquivo de configuração atualizado com sucesso!")
    print("\nNovas otimizações aplicadas:")
    print("1. Aumento do pool_size para 20 conexões")
    print("2. Aumento do timeout para 30 segundos")
    print("3. Configuração synchronous=NORMAL para equilíbrio entre desempenho e segurança")
    print("4. Aumento do cache_size para 10MB")
    print("5. Armazenamento de tabelas temporárias na memória (temp_store=MEMORY)")
    print("6. Configuração de mmap_size para 30GB para melhor desempenho com arquivos grandes")
    print("7. Ativação de auto_vacuum=INCREMENTAL para manter o arquivo compacto")
    print("8. Ativação de read_uncommitted para permitir leituras mais rápidas")
    
    return True

def update_repo_module(repo_path):
    """Atualiza o módulo Repo para aplicar pragmas na inicialização"""
    print(f"Verificando arquivo do repositório: {repo_path}")
    
    if not os.path.exists(repo_path):
        print(f"Erro: Arquivo {repo_path} não encontrado.")
        return False
    
    # Fazer backup do arquivo original
    backup_file(repo_path)
    
    # Ler o conteúdo do arquivo
    with open(repo_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Verificar se o módulo já tem um callback after_connect
    if "after_connect" in content:
        print("O módulo já possui um callback after_connect. Verificando se precisa ser atualizado...")
        
        # Padrão para encontrar o callback after_connect
        after_connect_pattern = r'def after_connect\((.*?)\) do(.*?)end'
        
        # Buscar o callback atual
        match = re.search(after_connect_pattern, content, re.DOTALL)
        if match:
            current_callback = match.group(0)
            print("\nCallback after_connect atual encontrado.")
            
            # Verificar se já contém as otimizações
            if "PRAGMA cache_size" in current_callback and "PRAGMA temp_store" in current_callback:
                print("O callback já contém as otimizações necessárias.")
                return True
            
            # Novo callback otimizado
            new_callback = """def after_connect({conn, _}) do
    # Aplicar pragmas para otimização após conectar
    Exqlite.query!(conn, "PRAGMA cache_size = -10000")
    Exqlite.query!(conn, "PRAGMA temp_store = MEMORY")
    Exqlite.query!(conn, "PRAGMA mmap_size = 30000000000")
    Exqlite.query!(conn, "PRAGMA auto_vacuum = INCREMENTAL")
    Exqlite.query!(conn, "PRAGMA read_uncommitted = 1")
    :ok
  end"""
            
            # Substituir o callback antigo pelo novo
            updated_content = content.replace(current_callback, new_callback)
            
            # Salvar o arquivo atualizado
            with open(repo_path, 'w', encoding='utf-8') as file:
                file.write(updated_content)
            
            print("\nCallback after_connect atualizado com sucesso!")
            return True
    else:
        print("O módulo não possui um callback after_connect. Adicionando...")
        
        # Padrão para encontrar o final do módulo
        module_end_pattern = r'end\s*$'
        
        # Novo callback para adicionar
        new_callback = """
  @doc """
  Callback executado após cada conexão com o banco de dados.
  Aplica configurações de PRAGMA para otimização de desempenho.
  """
  def after_connect({conn, _}) do
    # Aplicar pragmas para otimização após conectar
    Exqlite.query!(conn, "PRAGMA cache_size = -10000")
    Exqlite.query!(conn, "PRAGMA temp_store = MEMORY")
    Exqlite.query!(conn, "PRAGMA mmap_size = 30000000000")
    Exqlite.query!(conn, "PRAGMA auto_vacuum = INCREMENTAL")
    Exqlite.query!(conn, "PRAGMA read_uncommitted = 1")
    :ok
  end
end"""
        
        # Substituir o final do módulo
        updated_content = re.sub(module_end_pattern, new_callback, content, flags=re.DOTALL)
        
        # Salvar o arquivo atualizado
        with open(repo_path, 'w', encoding='utf-8') as file:
            file.write(updated_content)
        
        print("\nCallback after_connect adicionado com sucesso!")
        return True
    
    return False

def main():
    print("=" * 60)
    print("ATUALIZADOR DE CONFIGURAÇÃO SQLITE PARA DEEPER HUB")
    print("=" * 60)
    
    # Caminhos dos arquivos
    config_path = "../config/config.exs"
    repo_path = "../lib/deeper_hub/core/data/repo.ex"
    
    # Verificar se os arquivos existem
    if not os.path.exists(config_path):
        config_path = input("Digite o caminho para o arquivo config.exs: ")
    
    if not os.path.exists(repo_path):
        repo_path = input("Digite o caminho para o arquivo repo.ex: ")
    
    # Atualizar arquivo de configuração
    update_config_file(config_path)
    
    # Atualizar módulo Repo
    update_repo_module(repo_path)
    
    print("\nProcesso de otimização concluído!")
    print("\nPara aplicar as alterações, reinicie a aplicação Elixir.")
    print("As otimizações serão aplicadas automaticamente na próxima inicialização.")

if __name__ == "__main__":
    main()
