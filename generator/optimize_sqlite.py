import sqlite3
import os
import time

def otimizar_sqlite(caminho_db):
    """
    Otimiza um banco de dados SQLite para máximo desempenho.
    
    Args:
        caminho_db (str): Caminho para o arquivo de banco de dados SQLite
    """
    print(f"Otimizando banco de dados SQLite: {caminho_db}")
    
    # Verificar se o arquivo existe
    if not os.path.exists(caminho_db):
        print(f"Erro: O arquivo {caminho_db} não existe.")
        return False
    
    try:
        # Conectar ao banco de dados
        inicio = time.time()
        conn = sqlite3.connect(caminho_db)
        cursor = conn.cursor()
        
        # Configurações de otimização
        pragmas = [
            # Ativa o Write-Ahead Logging para melhor concorrência e desempenho
            "PRAGMA journal_mode = WAL",
            
            # Desativa sincronização com disco (CUIDADO: pode causar corrupção em caso de falha de energia)
            # Use 'FULL' para máxima segurança, 'NORMAL' para equilíbrio, 'OFF' para máximo desempenho
            "PRAGMA synchronous = NORMAL",
            
            # Ativa cache de banco de dados em memória (em KB)
            # Aumentar este valor pode melhorar significativamente o desempenho
            "PRAGMA cache_size = -10000",  # Negativo significa KB (10MB)
            
            # Tamanho da página (padrão é 4096)
            "PRAGMA page_size = 4096",
            
            # Ativa chaves estrangeiras
            "PRAGMA foreign_keys = ON",
            
            # Otimiza o banco de dados para leitura
            "PRAGMA temp_store = MEMORY",
            
            # Desativa verificações de restrições (cuidado, pode permitir dados inválidos)
            # "PRAGMA ignore_check_constraints = ON",
            
            # Define o tamanho do mmap (memory-mapped I/O)
            "PRAGMA mmap_size = 30000000000",  # 30GB (ajuste conforme RAM disponível)
            
            # Ativa auto_vacuum para manter o arquivo compacto
            "PRAGMA auto_vacuum = INCREMENTAL",
            
            # Ativa leitura antecipada para melhorar desempenho sequencial
            "PRAGMA read_uncommitted = 1",
            
            # Aumenta o timeout para operações bloqueadas (em ms)
            "PRAGMA busy_timeout = 5000"
        ]
        
        # Aplicar pragmas
        for pragma in pragmas:
            try:
                cursor.execute(pragma)
                resultado = cursor.fetchone()
                print(f"  + {pragma} => {resultado}")
            except sqlite3.Error as e:
                print(f"  - Erro ao aplicar {pragma}: {e}")
        
        # Analisar banco de dados
        print("\nAnalisando banco de dados...")
        cursor.execute("ANALYZE")
        
        # Compactar banco de dados
        print("Compactando banco de dados...")
        cursor.execute("VACUUM")
        
        # Otimizar índices
        print("Otimizando índices...")
        cursor.execute("PRAGMA optimize")
        
        # Fechar conexão
        conn.commit()
        conn.close()
        
        fim = time.time()
        print(f"\nOtimização concluída em {fim - inicio:.2f} segundos.")
        return True
        
    except sqlite3.Error as e:
        print(f"Erro ao otimizar banco de dados: {e}")
        return False

def criar_banco_otimizado(caminho_db):
    """
    Cria um novo banco de dados SQLite com configurações otimizadas.
    
    Args:
        caminho_db (str): Caminho para o arquivo de banco de dados SQLite a ser criado
    """
    print(f"Criando banco de dados SQLite otimizado: {caminho_db}")
    
    # Verificar se o diretório existe
    diretorio = os.path.dirname(caminho_db)
    if not os.path.exists(diretorio):
        os.makedirs(diretorio)
        print(f"Diretório criado: {diretorio}")
    
    # Se o arquivo já existe, fazer backup
    if os.path.exists(caminho_db):
        backup_path = f"{caminho_db}.bak"
        os.rename(caminho_db, backup_path)
        print(f"Backup criado: {backup_path}")
    
    try:
        # Conectar ao banco de dados (cria se não existir)
        conn = sqlite3.connect(caminho_db)
        cursor = conn.cursor()
        
        # Configurar otimizações antes de criar qualquer tabela
        pragmas = [
            "PRAGMA journal_mode = WAL",
            "PRAGMA synchronous = NORMAL",
            "PRAGMA cache_size = -10000",
            "PRAGMA page_size = 4096",
            "PRAGMA foreign_keys = ON",
            "PRAGMA temp_store = MEMORY",
            "PRAGMA mmap_size = 30000000000",
            "PRAGMA auto_vacuum = INCREMENTAL",
            "PRAGMA read_uncommitted = 1",
            "PRAGMA busy_timeout = 5000"
        ]
        
        # Aplicar pragmas
        for pragma in pragmas:
            cursor.execute(pragma)
            resultado = cursor.fetchone()
            print(f"  + {pragma} => {resultado}")
        
        # Fechar conexão
        conn.commit()
        conn.close()
        
        print(f"Banco de dados criado e otimizado: {caminho_db}")
        return True
        
    except sqlite3.Error as e:
        print(f"Erro ao criar banco de dados: {e}")
        return False

def modificar_config_elixir():
    """
    Gera um exemplo de configuração otimizada para o Elixir.
    """
    config = """
# Configuração otimizada para SQLite no Elixir
config :deeper_hub, DeeperHub.Core.Data.Repo,
  database: System.get_env("DEEPER_HUB_DB_PATH", "priv/data/deeper_hub.db"),
  pool_name: DeeperHub.DBConnectionPool,
  pool_size: String.to_integer(System.get_env("DEEPER_HUB_DB_POOL_SIZE", "20")),
  # Write-Ahead Logging para melhor concorrência
  journal_mode: :wal,
  # Timeout para operações bloqueadas (em ms)
  busy_timeout: 5000,
  # Timeout para operações de banco de dados
  timeout: 30_000,
  # Intervalo para ping em conexões ociosas
  idle_interval: 15_000,
  # Pragmas otimizados para desempenho
  pragmas: [
    foreign_keys: "ON",
    synchronous: "NORMAL",
    cache_size: "-10000",
    temp_store: "MEMORY",
    mmap_size: "30000000000",
    auto_vacuum: "INCREMENTAL",
    read_uncommitted: "1"
  ]
"""
    
    print("\nExemplo de configuração otimizada para Elixir:")
    print(config)
    
    # Salvar em um arquivo
    with open("sqlite_config_example.exs", "w") as f:
        f.write(config)
    
    print("Exemplo de configuração salvo em: sqlite_config_example.exs")

def main():
    print("=" * 60)
    print("OTIMIZADOR DE SQLITE PARA DEEPER HUB")
    print("=" * 60)
    print("\nEste script oferece opções para otimizar o banco de dados SQLite.")
    
    while True:
        print("\nOpções:")
        print("1. Otimizar banco de dados existente")
        print("2. Criar novo banco de dados otimizado")
        print("3. Gerar exemplo de configuração para Elixir")
        print("4. Sair")
        
        opcao = input("\nEscolha uma opção (1-4): ")
        
        if opcao == "1":
            caminho = input("Digite o caminho completo do banco de dados: ")
            otimizar_sqlite(caminho)
        elif opcao == "2":
            caminho = input("Digite o caminho completo para o novo banco de dados: ")
            criar_banco_otimizado(caminho)
        elif opcao == "3":
            modificar_config_elixir()
        elif opcao == "4":
            print("\nSaindo...")
            break
        else:
            print("\nOpção inválida. Tente novamente.")
    
    print("\nPrograma finalizado.")

if __name__ == "__main__":
    main()
