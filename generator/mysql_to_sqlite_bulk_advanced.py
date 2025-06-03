import os
import sqlite3
import mysql.connector
import time
from datetime import datetime
import re

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

def obter_estrutura_tabela_detalhada(conexao_mysql, tabela):
    """Obtém a estrutura detalhada de uma tabela MySQL."""
    cursor = conexao_mysql.cursor()
    
    # Obter informações detalhadas das colunas
    cursor.execute(f"SHOW COLUMNS FROM {tabela}")
    colunas_info = []
    
    for coluna in cursor.fetchall():
        nome = coluna[0]
        tipo = coluna[1]
        nulo = coluna[2]
        chave = coluna[3]
        padrao = coluna[4]
        extra = coluna[5]
        
        colunas_info.append({
            'nome': nome,
            'tipo': tipo,
            'nulo': nulo,
            'chave': chave,
            'padrao': padrao,
            'extra': extra
        })
    
    # Obter informações sobre chaves primárias e estrangeiras
    cursor.execute(f"SHOW CREATE TABLE {tabela}")
    create_table = cursor.fetchone()[1]
    
    # Extrair chave primária
    primary_key_match = re.search(r'PRIMARY KEY \(([^)]+)\)', create_table)
    primary_key = primary_key_match.group(1).replace('`', '') if primary_key_match else None
    
    # Extrair chaves estrangeiras
    foreign_keys = []
    for match in re.finditer(r'CONSTRAINT [^\s]+ FOREIGN KEY \(([^)]+)\) REFERENCES ([^\s]+)\s*\(([^)]+)\)', create_table):
        coluna_origem = match.group(1).replace('`', '')
        tabela_referencia = match.group(2).replace('`', '')
        coluna_referencia = match.group(3).replace('`', '')
        
        foreign_keys.append({
            'coluna_origem': coluna_origem,
            'tabela_referencia': tabela_referencia,
            'coluna_referencia': coluna_referencia
        })
    
    cursor.close()
    
    return {
        'colunas': colunas_info,
        'primary_key': primary_key,
        'foreign_keys': foreign_keys
    }

def mapear_tipo_mysql_para_sqlite(tipo_mysql):
    """Mapeia um tipo de dados MySQL para o equivalente no SQLite."""
    tipo_mysql = tipo_mysql.lower()
    
    if 'int' in tipo_mysql:
        return 'INTEGER'
    elif 'varchar' in tipo_mysql or 'text' in tipo_mysql or 'char' in tipo_mysql:
        return 'TEXT'
    elif 'float' in tipo_mysql or 'double' in tipo_mysql or 'decimal' in tipo_mysql:
        return 'REAL'
    elif 'date' in tipo_mysql or 'time' in tipo_mysql:
        return 'TEXT'
    elif 'blob' in tipo_mysql:
        return 'BLOB'
    elif 'bool' in tipo_mysql:
        return 'INTEGER'
    else:
        return 'TEXT'

def escapar_nome_coluna(nome):
    """Escapa nomes de colunas que são palavras reservadas no SQLite."""
    palavras_reservadas = [
        'abort', 'action', 'add', 'after', 'all', 'alter', 'analyze', 'and', 'as', 'asc',
        'attach', 'autoincrement', 'before', 'begin', 'between', 'by', 'cascade', 'case',
        'cast', 'check', 'collate', 'column', 'commit', 'conflict', 'constraint', 'create',
        'cross', 'current_date', 'current_time', 'current_timestamp', 'database', 'default',
        'deferrable', 'deferred', 'delete', 'desc', 'detach', 'distinct', 'drop', 'each',
        'else', 'end', 'escape', 'except', 'exclusive', 'exists', 'explain', 'fail', 'for',
        'foreign', 'from', 'full', 'glob', 'group', 'having', 'if', 'ignore', 'immediate',
        'in', 'index', 'indexed', 'initially', 'inner', 'insert', 'instead', 'intersect',
        'into', 'is', 'isnull', 'join', 'key', 'left', 'like', 'limit', 'match', 'natural',
        'no', 'not', 'notnull', 'null', 'of', 'offset', 'on', 'or', 'order', 'outer', 'plan',
        'pragma', 'primary', 'query', 'raise', 'recursive', 'references', 'regexp', 'reindex',
        'release', 'rename', 'replace', 'restrict', 'right', 'rollback', 'row', 'savepoint',
        'select', 'set', 'table', 'temp', 'temporary', 'then', 'to', 'transaction', 'trigger',
        'union', 'unique', 'update', 'using', 'vacuum', 'values', 'view', 'virtual', 'when',
        'where', 'with', 'without'
    ]
    
    if nome.lower() in palavras_reservadas:
        return f'"{nome}"'
    return nome

def criar_tabela_sqlite(conexao_sqlite, tabela, estrutura):
    """Cria uma tabela no SQLite com base na estrutura do MySQL."""
    cursor = conexao_sqlite.cursor()
    
    # Verificar se a tabela já existe
    cursor.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{tabela}'")
    if cursor.fetchone() is not None:
        print(f"  - Tabela {tabela} já existe no SQLite, pulando criação...")
        cursor.close()
        return
    
    # Construir a definição das colunas
    colunas_sql = []
    for coluna in estrutura['colunas']:
        nome = escapar_nome_coluna(coluna['nome'])
        tipo = mapear_tipo_mysql_para_sqlite(coluna['tipo'])
        nulo = "NULL" if coluna['nulo'] == "YES" else "NOT NULL"
        
        # Tratar valor padrão
        padrao = ""
        if coluna['padrao'] is not None:
            if coluna['padrao'].isdigit() or (coluna['padrao'].startswith('-') and coluna['padrao'][1:].isdigit()):
                padrao = f"DEFAULT {coluna['padrao']}"
            else:
                padrao = f"DEFAULT '{coluna['padrao']}'"
        
        # Tratar AUTO_INCREMENT para SQLite
        extra = ""
        if coluna['extra'] and 'auto_increment' in coluna['extra'].lower() and coluna['chave'] == 'PRI':
            tipo = "INTEGER"
            extra = "PRIMARY KEY AUTOINCREMENT"
            nulo = ""  # PRIMARY KEY já implica NOT NULL
        
        coluna_sql = f"{nome} {tipo} {nulo} {padrao} {extra}".strip()
        colunas_sql.append(coluna_sql)
    
    # Adicionar chave primária se não for AUTO_INCREMENT
    if estrutura['primary_key'] and not any("PRIMARY KEY AUTOINCREMENT" in col for col in colunas_sql):
        # Verificar se a chave primária já foi definida em alguma coluna
        if not any("PRIMARY KEY" in col for col in colunas_sql):
            colunas_sql.append(f"PRIMARY KEY ({estrutura['primary_key']})")
    
    # Adicionar chaves estrangeiras
    for fk in estrutura['foreign_keys']:
        coluna_origem = escapar_nome_coluna(fk['coluna_origem'])
        tabela_referencia = fk['tabela_referencia']
        coluna_referencia = fk['coluna_referencia']
        
        fk_sql = f"FOREIGN KEY ({coluna_origem}) REFERENCES {tabela_referencia}({coluna_referencia})"
        colunas_sql.append(fk_sql)
    
    # Criar a tabela
    sql_create = f"CREATE TABLE {tabela} (\n  " + ",\n  ".join(colunas_sql) + "\n)"
    
    try:
        cursor.execute(sql_create)
        print(f"  - Tabela {tabela} criada com sucesso no SQLite")
    except sqlite3.Error as e:
        print(f"  - Erro ao criar tabela {tabela}: {str(e)}")
        print(f"  - SQL: {sql_create}")
    
    cursor.close()

def migrar_dados_em_lote(conexao_mysql, conexao_sqlite, tabela, estrutura, tamanho_lote=1000):
    """Migra dados do MySQL para o SQLite em lotes."""
    cursor_mysql = conexao_mysql.cursor()
    cursor_sqlite = conexao_sqlite.cursor()
    
    # Obter o total de registros
    cursor_mysql.execute(f"SELECT COUNT(*) FROM {tabela}")
    total_registros = cursor_mysql.fetchone()[0]
    
    if total_registros == 0:
        print(f"  - Tabela {tabela} está vazia, pulando migração de dados...")
        return 0
    
    print(f"  - Migrando {total_registros} registros da tabela {tabela}...")
    
    # Preparar a consulta para buscar os dados em lotes
    colunas = [coluna['nome'] for coluna in estrutura['colunas']]
    colunas_str = ", ".join([f"`{coluna}`" for coluna in colunas])
    
    # Preparar os nomes das colunas escapados para o SQLite
    colunas_sqlite = [escapar_nome_coluna(coluna) for coluna in colunas]
    colunas_sqlite_str = ", ".join(colunas_sqlite)
    
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
                # Converter valores para o formato adequado
                registro_formatado = []
                for i, valor in enumerate(registro):
                    if valor is None:
                        registro_formatado.append(None)
                    else:
                        # Converter para o tipo adequado com base no tipo da coluna
                        tipo_sqlite = mapear_tipo_mysql_para_sqlite(estrutura['colunas'][i]['tipo'])
                        
                        if tipo_sqlite == 'INTEGER':
                            try:
                                registro_formatado.append(int(valor) if valor != '' else None)
                            except (ValueError, TypeError):
                                registro_formatado.append(0)
                        elif tipo_sqlite == 'REAL':
                            try:
                                registro_formatado.append(float(valor) if valor != '' else None)
                            except (ValueError, TypeError):
                                registro_formatado.append(0.0)
                        else:
                            registro_formatado.append(str(valor))
                
                # Inserir no SQLite
                sql_insert = f"INSERT INTO {tabela} ({colunas_sqlite_str}) VALUES ({placeholders})"
                cursor_sqlite.execute(sql_insert, registro_formatado)
            
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
            print(f"\n    Erro ao migrar lote para {tabela}: {str(e)}")
            
            # Tentar migrar registro por registro para identificar o problema
            print("    Tentando migrar registros individualmente para identificar o problema...")
            
            cursor_sqlite.execute("BEGIN TRANSACTION")
            for i, registro in enumerate(lote):
                try:
                    # Converter valores para o formato adequado
                    registro_formatado = []
                    for j, valor in enumerate(registro):
                        if valor is None:
                            registro_formatado.append(None)
                        else:
                            # Converter para o tipo adequado
                            tipo_sqlite = mapear_tipo_mysql_para_sqlite(estrutura['colunas'][j]['tipo'])
                            
                            if tipo_sqlite == 'INTEGER':
                                try:
                                    registro_formatado.append(int(valor) if valor != '' else None)
                                except (ValueError, TypeError):
                                    registro_formatado.append(0)
                            elif tipo_sqlite == 'REAL':
                                try:
                                    registro_formatado.append(float(valor) if valor != '' else None)
                                except (ValueError, TypeError):
                                    registro_formatado.append(0.0)
                            else:
                                registro_formatado.append(str(valor))
                    
                    # Inserir no SQLite
                    sql_insert = f"INSERT INTO {tabela} ({colunas_sqlite_str}) VALUES ({placeholders})"
                    cursor_sqlite.execute(sql_insert, registro_formatado)
                    
                    registros_migrados += 1
                    
                except Exception as e_individual:
                    print(f"    Erro no registro {i}: {str(e_individual)}")
                    print(f"    Dados: {registro}")
            
            cursor_sqlite.execute("COMMIT")
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
            
            # Obter a estrutura detalhada da tabela
            estrutura = obter_estrutura_tabela_detalhada(conexao_mysql, tabela)
            
            # Criar a tabela no SQLite
            criar_tabela_sqlite(conexao_sqlite, tabela, estrutura)
            
            # Migrar os dados em lotes
            registros_migrados = migrar_dados_em_lote(conexao_mysql, conexao_sqlite, tabela, estrutura)
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
