import os
import sqlite3
import mysql.connector
import time
from datetime import datetime

def criar_diretorio_se_nao_existir(caminho):
    """Cria um diretório se ele não existir."""
    if not os.path.exists(caminho):
        os.makedirs(caminho)

def obter_tabelas_mysql(conexao_mysql):
    """Obtém a lista de todas as tabelas do banco de dados MySQL."""
    cursor = conexao_mysql.cursor()
    cursor.execute("SHOW TABLES")
    tabelas = [tabela[0] for tabela in cursor.fetchall()]
    cursor.close()
    return tabelas

def obter_estrutura_tabela(conexao_mysql, tabela):
    """Obtém a estrutura de uma tabela MySQL."""
    cursor = conexao_mysql.cursor()
    cursor.execute(f"DESCRIBE {tabela}")
    colunas = [coluna[0] for coluna in cursor.fetchall()]
    cursor.close()
    return colunas

def criar_tabela_sqlite(conexao_sqlite, tabela, colunas):
    """Cria uma tabela no SQLite se ela não existir."""
    cursor = conexao_sqlite.cursor()
    
    # Verificar se a tabela já existe
    cursor.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{tabela}'")
    if cursor.fetchone() is None:
        # Criar a tabela com as mesmas colunas
        colunas_str = ", ".join([f'"{coluna}" TEXT' for coluna in colunas])
        cursor.execute(f"CREATE TABLE IF NOT EXISTS {tabela} ({colunas_str})")
    
    cursor.close()

def migrar_dados_em_lote(conexao_mysql, conexao_sqlite, tabela, colunas, tamanho_lote=1000):
    """Migra dados do MySQL para o SQLite em lotes."""
    cursor_mysql = conexao_mysql.cursor()
    cursor_sqlite = conexao_sqlite.cursor()
    
    # Obter o total de registros
    cursor_mysql.execute(f"SELECT COUNT(*) FROM {tabela}")
    total_registros = cursor_mysql.fetchone()[0]
    
    if total_registros == 0:
        print(f"  - Tabela {tabela} está vazia, pulando...")
        return 0
    
    print(f"  - Migrando {total_registros} registros da tabela {tabela}...")
    
    # Preparar a consulta para buscar os dados em lotes
    colunas_str = ", ".join([f"`{coluna}`" for coluna in colunas])
    placeholders = ", ".join(["?" for _ in colunas])
    
    # Iniciar a migração em lotes
    offset = 0
    registros_migrados = 0
    
    inicio = time.time()
    
    while offset < total_registros:
        # Buscar um lote de dados do MySQL
        cursor_mysql.execute(f"SELECT {colunas_str} FROM {tabela} LIMIT {offset}, {tamanho_lote}")
        lote = cursor_mysql.fetchall()
        
        if not lote:
            break
        
        # Iniciar uma transação no SQLite para inserções em lote
        cursor_sqlite.execute("BEGIN TRANSACTION")
        
        try:
            # Inserir os dados no SQLite
            for registro in lote:
                # Converter None para string vazia e outros tipos para string
                registro_formatado = []
                for valor in registro:
                    if valor is None:
                        registro_formatado.append("")
                    else:
                        registro_formatado.append(str(valor))
                
                cursor_sqlite.execute(f"INSERT INTO {tabela} VALUES ({placeholders})", registro_formatado)
            
            # Confirmar a transação
            cursor_sqlite.execute("COMMIT")
            
            registros_migrados += len(lote)
            offset += tamanho_lote
            
            # Exibir progresso
            progresso = min(100, int((registros_migrados / total_registros) * 100))
            print(f"    Progresso: {progresso}% ({registros_migrados}/{total_registros})", end="\r")
            
        except Exception as e:
            # Em caso de erro, reverter a transação
            cursor_sqlite.execute("ROLLBACK")
            print(f"\nErro ao migrar lote para {tabela}: {str(e)}")
            break
    
    fim = time.time()
    tempo_total = fim - inicio
    
    print(f"\n    Concluído: {registros_migrados} registros migrados em {tempo_total:.2f} segundos")
    
    cursor_mysql.close()
    cursor_sqlite.close()
    
    return registros_migrados

def main():
    # Configurações de conexão MySQL
    config_mysql = {
        'host': 'localhost',
        'user': 'root',
        'password': '',
        'database': 'deeper_hub'
    }
    
    # Caminho do banco SQLite
    sqlite_db_path = os.path.join("..", "priv", "data", "deeper_hub.db")
    
    # Garantir que o diretório existe
    os.makedirs(os.path.dirname(sqlite_db_path), exist_ok=True)
    
    print(f"Iniciando migração de dados MySQL para SQLite em {datetime.now()}")
    print(f"Banco de dados SQLite: {sqlite_db_path}")
    
    try:
        # Conectar ao MySQL
        conexao_mysql = mysql.connector.connect(**config_mysql)
        print("Conectado ao MySQL com sucesso")
        
        # Conectar ao SQLite
        conexao_sqlite = sqlite3.connect(sqlite_db_path)
        print("Conectado ao SQLite com sucesso")
        
        # Obter todas as tabelas do MySQL
        tabelas = obter_tabelas_mysql(conexao_mysql)
        print(f"Encontradas {len(tabelas)} tabelas no MySQL")
        
        # Estatísticas
        total_tabelas = len(tabelas)
        tabelas_processadas = 0
        total_registros_migrados = 0
        
        # Migrar cada tabela
        for tabela in tabelas:
            tabelas_processadas += 1
            print(f"\nProcessando tabela {tabelas_processadas}/{total_tabelas}: {tabela}")
            
            # Obter a estrutura da tabela
            colunas = obter_estrutura_tabela(conexao_mysql, tabela)
            
            # Criar a tabela no SQLite
            criar_tabela_sqlite(conexao_sqlite, tabela, colunas)
            
            # Migrar os dados em lotes
            registros_migrados = migrar_dados_em_lote(conexao_mysql, conexao_sqlite, tabela, colunas)
            total_registros_migrados += registros_migrados
        
        print("\n" + "=" * 50)
        print(f"Migração concluída em {datetime.now()}")
        print(f"Total de tabelas migradas: {tabelas_processadas}")
        print(f"Total de registros migrados: {total_registros_migrados}")
        print("=" * 50)
        
    except Exception as e:
        print(f"Erro durante a migração: {str(e)}")
    
    finally:
        # Fechar conexões
        if 'conexao_mysql' in locals() and conexao_mysql.is_connected():
            conexao_mysql.close()
            print("Conexão MySQL fechada")
        
        if 'conexao_sqlite' in locals():
            conexao_sqlite.close()
            print("Conexão SQLite fechada")

if __name__ == "__main__":
    main()
