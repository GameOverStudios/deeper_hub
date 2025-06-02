import os
import shutil
import mysql.connector
from datetime import datetime

# Função para conectar ao MySQL
def conectar_mysql(host='localhost', usuario='root', senha='', banco='una'):
    conexao = mysql.connector.connect(
        host=host,
        user=usuario,
        password=senha,
        database=banco
    )
    return conexao

# Função para obter informações das tabelas
def obter_tabelas(conexao):
    cursor = conexao.cursor()
    cursor.execute("SHOW TABLES")
    tabelas = [tabela[0] for tabela in cursor.fetchall()]
    return tabelas

# Função para obter informações dos campos de uma tabela
def obter_campos(conexao, tabela):
    cursor = conexao.cursor()
    cursor.execute(f"DESCRIBE {tabela}")
    campos = cursor.fetchall()
    return campos

# Função para obter informações das relações entre tabelas (chaves estrangeiras)
def obter_relacoes(conexao):
    cursor = conexao.cursor()
    cursor.execute("""
    SELECT 
        TABLE_NAME, 
        COLUMN_NAME, 
        REFERENCED_TABLE_NAME, 
        REFERENCED_COLUMN_NAME 
    FROM 
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE 
        REFERENCED_TABLE_SCHEMA = DATABASE() 
        AND REFERENCED_TABLE_NAME IS NOT NULL
    """)
    relacoes = cursor.fetchall()
    return relacoes

# Função para limpar diretórios de migrations e schemas
def limpar_diretorios():
    # Cria diretórios se não existirem
    migrations_dir = os.path.join("lib", "deeper_hub", "core", "data", "migrations")
    schemas_dir = os.path.join("lib", "deeper_hub", "core", "data", "schemas")
    
    if not os.path.exists(migrations_dir):
        os.makedirs(migrations_dir)
    else:
        # Limpa o diretório de migrations
        for arquivo in os.listdir(migrations_dir):
            caminho_arquivo = os.path.join(migrations_dir, arquivo)
            if os.path.isfile(caminho_arquivo):
                try:
                    os.unlink(caminho_arquivo)
                except PermissionError:
                    print(f"Aviso: Não foi possível excluir {caminho_arquivo} - arquivo em uso")
    
    if not os.path.exists(schemas_dir):
        os.makedirs(schemas_dir)
    else:
        # Limpa o diretório de schemas
        for arquivo in os.listdir(schemas_dir):
            caminho_arquivo = os.path.join(schemas_dir, arquivo)
            if os.path.isfile(caminho_arquivo):
                try:
                    os.unlink(caminho_arquivo)
                except PermissionError:
                    print(f"Aviso: Não foi possível excluir {caminho_arquivo} - arquivo em uso")

# Função para criar schemas
def criar_schema(tabela, campos, relacoes=None):
    # Diretório para salvar os schemas
    base_output_path = os.path.join("lib", "deeper_hub", "core", "data", "schemas")
    if not os.path.exists(base_output_path):
        os.makedirs(base_output_path)
    
    # Converter nome da tabela para formato de módulo Elixir (CamelCase)
    modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
    
    # Converter para singular (regra simples, pode precisar de ajustes)
    nome_singular = tabela
    if nome_singular.endswith('s'):
        nome_singular = nome_singular[:-1]
    
    # Caminho do arquivo de schema
    arquivo_path = os.path.join(base_output_path, f"{tabela}.ex")
    
    try:
        with open(arquivo_path, 'w', encoding='utf-8') as arquivo:
            # Cabeçalho do módulo
        arquivo.write(f'defmodule DeeperHub.Core.Data.Schemas.{modulo_nome} do\n')
        arquivo.write('  @moduledoc """\n')
        arquivo.write(f'  Este schema armazena as informações de um {nome_singular}.\n')
        arquivo.write('  """\n\n')
        arquivo.write('  alias DeeperHub.Core.Data.Repo\n')
        arquivo.write('  alias DeeperHub.Core.Logger\n')
        arquivo.write('  require DeeperHub.Core.Logger\n\n')
        
        # Definir estrutura para o schema
        arquivo.write('  @doc """\n')
        arquivo.write(f'  Busca todos os registros de {nome_singular}s na tabela {tabela}.\n\n')
        arquivo.write('  ## Retorno\n')
        arquivo.write('    - Lista de mapas representando os registros\n')
        arquivo.write('  """\n')
        arquivo.write('  @spec all() :: {:ok, [map()]} | {:error, any()}\n')
        arquivo.write('  def all do\n')
        arquivo.write(f'    Logger.info("Buscando todos os registros de {tabela}...", module: __MODULE__)\n\n')
        
        arquivo.write('    sql = """\n')
        arquivo.write(f'    SELECT * FROM {tabela}\n')
        arquivo.write('    """\n\n')
        
        arquivo.write('    case Repo.execute(sql) do\n')
        arquivo.write('      {:ok, %{rows: rows, columns: columns}} ->\n')
        arquivo.write('        result = Enum.map(rows, fn row ->\n')
        arquivo.write('          Enum.zip(columns, row) |> Enum.into(%{})\n')
        arquivo.write('        end)\n')
        arquivo.write(f'        Logger.info("Registros de {tabela} recuperados com sucesso.", module: __MODULE__)\n')
        arquivo.write('        {:ok, result}\n\n')
        
        arquivo.write('      {:error, reason} ->\n')
        arquivo.write(f'        Logger.error("Falha ao buscar registros de {tabela}: ' + '#{inspect(reason)}", module: __MODULE__)\n')
        arquivo.write('        {:error, reason}\n')
        arquivo.write('    end\n')
        arquivo.write('  end\n\n')
        
        # Função para buscar por ID
        arquivo.write('  @doc """\n')
        arquivo.write(f'  Busca um {nome_singular} pelo ID.\n\n')
        arquivo.write('  ## Parâmetros\n')
        arquivo.write('    - `id`: ID do registro a ser buscado\n\n')
        arquivo.write('  ## Retorno\n')
        arquivo.write('    - Mapa representando o registro encontrado ou nil se não encontrado\n')
        arquivo.write('  """\n')
        arquivo.write('  @spec get(String.t()) :: {:ok, map() | nil} | {:error, any()}\n')
        arquivo.write('  def get(id) do\n')
        arquivo.write(f'    Logger.info("Buscando {nome_singular} com ID: ' + '#{inspect(id)}", module: __MODULE__)\n\n')
        
        arquivo.write('    sql = """\n')
        arquivo.write(f'    SELECT * FROM {tabela} WHERE id = ?\n')
        arquivo.write('    """\n\n')
        
        arquivo.write('    case Repo.execute(sql, [id]) do\n')
        arquivo.write('      {:ok, %{rows: [row], columns: columns}} ->\n')
        arquivo.write('        result = Enum.zip(columns, row) |> Enum.into(%{})\n')
        arquivo.write(f'        Logger.info("Registro de {nome_singular} recuperado com sucesso.", module: __MODULE__)\n')
        arquivo.write('        {:ok, result}\n\n')
        
        arquivo.write('      {:ok, %{rows: []}} ->\n')
        arquivo.write(f'        Logger.info("Nenhum registro de {nome_singular} encontrado com ID: ' + '#{inspect(id)}", module: __MODULE__)\n')
        arquivo.write('        {:ok, nil}\n\n')
        
        arquivo.write('      {:error, reason} ->\n')
        arquivo.write(f'        Logger.error("Falha ao buscar {nome_singular} com ID: ' + '#{inspect(id)}, erro: #{inspect(reason)}", module: __MODULE__)\n')
        arquivo.write('        {:error, reason}\n')
        arquivo.write('    end\n')
        arquivo.write('  end\n\n')
        
        # Função para criar um novo registro
        arquivo.write('  @doc """\n')
        arquivo.write(f'  Cria um novo registro de {nome_singular}.\n\n')
        arquivo.write('  ## Parâmetros\n')
        arquivo.write('    - `attrs`: Mapa com os atributos para criação\n\n')
        arquivo.write('  ## Retorno\n')
        arquivo.write('    - ID do registro criado ou erro\n')
        arquivo.write('  """\n')
        arquivo.write('  @spec create(map()) :: {:ok, integer()} | {:error, any()}\n')
        arquivo.write('  def create(attrs) do\n')
        arquivo.write(f'    Logger.info("Criando novo registro de {nome_singular}: ' + '#{inspect(attrs)}", module: __MODULE__)\n\n')
        
        arquivo.write('    # Preparar campos e valores\n')
        arquivo.write('    fields = Map.keys(attrs) |> Enum.filter(&(&1 not in [:id]))\n')
        arquivo.write('    values = Enum.map(fields, &Map.get(attrs, &1))\n\n')
        
        arquivo.write('    # Adicionar inserted_at e updated_at\n')
        arquivo.write('    fields = fields ++ [:inserted_at, :updated_at]\n')
        arquivo.write('    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)\n')
        arquivo.write('    values = values ++ [now, now]\n\n')
        
        arquivo.write('    # Gerar SQL\n')
        arquivo.write('    columns = Enum.map(fields, &Atom.to_string/1) |> Enum.join(", ")\n')
        arquivo.write('    placeholders = Enum.map(fields, fn _ -> "?" end) |> Enum.join(", ")\n\n')
        
        arquivo.write('    sql = """\n')
        arquivo.write(f'    INSERT INTO {tabela} (' + '#{columns})\n')
        arquivo.write('    VALUES (' + '#{placeholders})\n')
        arquivo.write('    """\n\n')
        
        arquivo.write('    case Repo.execute(sql, values) do\n')
        arquivo.write('      {:ok, %{last_insert_id: id}} ->\n')
        arquivo.write(f'        Logger.info("Registro de {nome_singular} criado com sucesso. ID: ' + '#{inspect(id)}", module: __MODULE__)\n')
        arquivo.write('        {:ok, id}\n\n')
        
        arquivo.write('      {:error, reason} ->\n')
        arquivo.write(f'        Logger.error("Falha ao criar registro de {nome_singular}: ' + '#{inspect(reason)}", module: __MODULE__)\n')
        arquivo.write('        {:error, reason}\n')
        arquivo.write('    end\n')
        arquivo.write('  end\n\n')
        
        # Função para atualizar um registro
        arquivo.write('  @doc """\n')
        arquivo.write(f'  Atualiza um registro de {nome_singular} existente.\n\n')
        arquivo.write('  ## Parâmetros\n')
        arquivo.write('    - `id`: ID do registro a ser atualizado\n')
        arquivo.write('    - `attrs`: Mapa com os atributos para atualização\n\n')
        arquivo.write('  ## Retorno\n')
        arquivo.write('    - :ok ou erro\n')
        arquivo.write('  """\n')
        arquivo.write('  @spec update(integer(), map()) :: :ok | {:error, any()}\n')
        arquivo.write('  def update(id, attrs) do\n')
        arquivo.write(f'    Logger.info("Atualizando registro de {nome_singular} com ID: ' + '#{inspect(id)}", module: __MODULE__)\n\n')
        
        arquivo.write('    # Preparar campos e valores para atualização\n')
        arquivo.write('    fields = Map.keys(attrs) |> Enum.filter(&(&1 not in [:id, :inserted_at, :updated_at]))\n')
        arquivo.write('    values = Enum.map(fields, &Map.get(attrs, &1))\n\n')
        
        arquivo.write('    # Adicionar updated_at\n')
        arquivo.write('    fields = fields ++ [:updated_at]\n')
        arquivo.write('    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)\n')
        arquivo.write('    values = values ++ [now]\n\n')
        
        arquivo.write('    # Gerar SQL\n')
        arquivo.write('    set_clauses = Enum.map(fields, fn field -> "' + '#{field} = ?" end) |> Enum.join(", ")\n\n')
        
        arquivo.write('    sql = """\n')
        arquivo.write(f'    UPDATE {tabela}\n')
        arquivo.write('    SET ' + '#{set_clauses}\n')
        arquivo.write('    WHERE id = ?\n')
        arquivo.write('    """\n\n')
        
        arquivo.write('    # Adicionar ID como último parâmetro\n')
        arquivo.write('    values = values ++ [id]\n\n')
        
        arquivo.write('    case Repo.execute(sql, values) do\n')
        arquivo.write('      {:ok, %{affected_rows: 1}} ->\n')
        arquivo.write(f'        Logger.info("Registro de {nome_singular} atualizado com sucesso.", module: __MODULE__)\n')
        arquivo.write('        :ok\n\n')
        
        arquivo.write('      {:ok, %{affected_rows: 0}} ->\n')
        arquivo.write(f'        Logger.info("Nenhum registro de {nome_singular} encontrado com ID: ' + '#{inspect(id)}", module: __MODULE__)\n')
        arquivo.write('        {:error, :not_found}\n\n')
        
        arquivo.write('      {:error, reason} ->\n')
        arquivo.write(f'        Logger.error("Falha ao atualizar registro de {nome_singular}: ' + '#{inspect(reason)}", module: __MODULE__)\n')
        arquivo.write('        {:error, reason}\n')
        arquivo.write('    end\n')
        arquivo.write('  end\n\n')
        
        # Função para excluir um registro
        arquivo.write('  @doc """\n')
        arquivo.write(f'  Exclui um registro de {nome_singular}.\n\n')
        arquivo.write('  ## Parâmetros\n')
        arquivo.write('    - `id`: ID do registro a ser excluído\n\n')
        arquivo.write('  ## Retorno\n')
        arquivo.write('    - :ok ou erro\n')
        arquivo.write('  """\n')
        arquivo.write('  @spec delete(integer()) :: :ok | {:error, any()}\n')
        arquivo.write('  def delete(id) do\n')
        arquivo.write(f'    Logger.info("Excluindo registro de {nome_singular} com ID: ' + '#{inspect(id)}", module: __MODULE__)\n\n')
        
        arquivo.write('    sql = """\n')
        arquivo.write(f'    DELETE FROM {tabela}\n')
        arquivo.write('    WHERE id = ?\n')
        arquivo.write('    """\n\n')
        
        arquivo.write('    case Repo.execute(sql, [id]) do\n')
        arquivo.write('      {:ok, %{affected_rows: 1}} ->\n')
        arquivo.write(f'        Logger.info("Registro de {nome_singular} excluído com sucesso.", module: __MODULE__)\n')
        arquivo.write('        :ok\n\n')
        
        arquivo.write('      {:ok, %{affected_rows: 0}} ->\n')
        arquivo.write(f'        Logger.info("Nenhum registro de {nome_singular} encontrado com ID: ' + '#{inspect(id)}", module: __MODULE__)\n')
        arquivo.write('        {:error, :not_found}\n\n')
        
        arquivo.write('      {:error, reason} ->\n')
        arquivo.write(f'        Logger.error("Falha ao excluir registro de {nome_singular}: ' + '#{inspect(reason)}", module: __MODULE__)\n')
        arquivo.write('        {:error, reason}\n')
        arquivo.write('    end\n')
        arquivo.write('  end\n\n')
        
        # Adicionar uma função para buscar por campo específico
        arquivo.write('  @doc """\n')
        arquivo.write(f'  Busca registros de {nome_singular} por um campo específico.\n\n')
        arquivo.write('  ## Parâmetros\n')
        arquivo.write('    - `field`: Nome do campo para filtrar\n')
        arquivo.write('    - `value`: Valor para filtrar\n\n')
        arquivo.write('  ## Retorno\n')
        arquivo.write('    - Lista de mapas representando os registros encontrados\n')
        arquivo.write('  """\n')
        arquivo.write('  @spec get_by(atom(), any()) :: {:ok, [map()]} | {:error, any()}\n')
        arquivo.write('  def get_by(field, value) do\n')
        arquivo.write(f'    Logger.info("Buscando {nome_singular}s por ' + '#{field}: #{inspect(value)}", module: __MODULE__)\n\n')
        
        arquivo.write('    sql = """\n')
        arquivo.write(f'    SELECT * FROM {tabela} WHERE ' + '#{field} = ?\n')
        arquivo.write('    """\n\n')
        
        arquivo.write('    case Repo.execute(sql, [value]) do\n')
        arquivo.write('      {:ok, %{rows: rows, columns: columns}} ->\n')
        arquivo.write('        result = Enum.map(rows, fn row ->\n')
        arquivo.write('          Enum.zip(columns, row) |> Enum.into(%{})\n')
        arquivo.write('        end)\n')
        arquivo.write(f'        Logger.info("Registros de {nome_singular} recuperados com sucesso.", module: __MODULE__)\n')
        arquivo.write('        {:ok, result}\n\n')
        
        arquivo.write('      {:error, reason} ->\n')
        arquivo.write(f'        Logger.error("Falha ao buscar registros de {nome_singular} por ' + '#{field}: #{inspect(reason)}", module: __MODULE__)\n')
        arquivo.write('        {:error, reason}\n')
        arquivo.write('    end\n')
        arquivo.write('  end\n')
        arquivo.write('end\n')
    
        print(f"Schema para tabela {tabela} criado com sucesso.")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o schema para {tabela} - arquivo em uso ou sem permissão")

# Função para criar migrations
def criar_migrations(tabelas, relacoes=None):
    base_output_path = os.path.join("lib", "deeper_hub", "core", "data", "migrations")
    if not os.path.exists(base_output_path):
        os.makedirs(base_output_path)
    
    for tabela in tabelas:
        # Obter informações dos campos da tabela
        cursor = conexao.cursor()
        cursor.execute(f"SHOW CREATE TABLE {tabela}")
        create_table_sql = cursor.fetchone()[1]
        
        # Caminho do arquivo de migração
        arquivo_path = os.path.join(base_output_path, f"create_{tabela}_table.ex")
        
        try:
            with open(arquivo_path, 'w', encoding='utf-8') as arquivo:
                # Cabeçalho do módulo
            arquivo.write(f'defmodule DeeperHub.Core.Data.Migrations.Create{tabela.capitalize()}Table do\n')
            arquivo.write('  @moduledoc """\n')
            arquivo.write(f'  Migration para criar a tabela de {tabela}.\n')
            arquivo.write('  """\n\n')
            arquivo.write('  alias DeeperHub.Core.Data.Repo\n')
            arquivo.write('  alias DeeperHub.Core.Logger\n')
            arquivo.write('  require DeeperHub.Core.Logger\n\n')
            
            arquivo.write('  @doc """\n')
            arquivo.write(f'  Cria a tabela de {tabela}.\n')
            arquivo.write('  """\n')
            arquivo.write('  def up do\n')
            arquivo.write(f'    Logger.info("Criando tabela de {tabela}...", module: __MODULE__)\n\n')
            
            arquivo.write('    sql = """\n')
            arquivo.write(f'{create_table_sql.replace("`", "")}\n')
            arquivo.write('    """\n\n')
            
            arquivo.write('    case Repo.execute(sql) do\n')
            arquivo.write('      {:ok, _} ->\n')
            arquivo.write(f'        Logger.info("Tabela de {tabela} criada com sucesso.", module: __MODULE__)\n')
            arquivo.write('        :ok\n\n')
            
            arquivo.write('      {:error, reason} ->\n')
            arquivo.write(f'        Logger.error("Falha ao criar tabela de {tabela}: ' + '#{inspect(reason)}", module: __MODULE__)\n')
            arquivo.write('        {:error, reason}\n')
            arquivo.write('    end\n')
            arquivo.write('  end\n\n')
            
            arquivo.write('  @doc """\n')
            arquivo.write(f'  Remove a tabela de {tabela}.\n')
            arquivo.write('  """\n')
            arquivo.write('  def down do\n')
            arquivo.write(f'    Logger.info("Removendo tabela de {tabela}...", module: __MODULE__)\n\n')
            
            arquivo.write('    sql = """\n')
            arquivo.write(f'    DROP TABLE IF EXISTS {tabela}\n')
            arquivo.write('    """\n\n')
            
            arquivo.write('    case Repo.execute(sql) do\n')
            arquivo.write('      {:ok, _} ->\n')
            arquivo.write(f'        Logger.info("Tabela de {tabela} removida com sucesso.", module: __MODULE__)\n')
            arquivo.write('        :ok\n\n')
            
            arquivo.write('      {:error, reason} ->\n')
            arquivo.write(f'        Logger.error("Falha ao remover tabela de {tabela}: ' + '#{inspect(reason)}", module: __MODULE__)\n')
            arquivo.write('        {:error, reason}\n')
            arquivo.write('    end\n')
            arquivo.write('  end\n')
            arquivo.write('end\n')
        
            print(f"Migration para tabela {tabela} criada com sucesso.")
        except PermissionError:
            print(f"Aviso: Não foi possível criar a migration para {tabela} - arquivo em uso ou sem permissão")

# Função principal
if __name__ == "__main__":
    # Conectar ao MySQL
    try:
        conexao = conectar_mysql()
        print("Conexão com MySQL estabelecida com sucesso.")
        
        # Limpar diretórios
        limpar_diretorios()
        print("Diretórios limpos com sucesso.")
        
        # Obter tabelas
        tabelas = obter_tabelas(conexao)
        print(f"Tabelas encontradas: {', '.join(tabelas)}")
        
        # Obter relações
        relacoes = obter_relacoes(conexao)
        
        # Criar migrations
        criar_migrations(tabelas, relacoes)
        
        # Criar schemas
        for tabela in tabelas:
            campos = obter_campos(conexao, tabela)
            criar_schema(tabela, campos, relacoes)
        
        print("Processo concluído com sucesso!")
        
    except mysql.connector.Error as err:
        print(f"Erro ao conectar ao MySQL: {err}")
    finally:
        if 'conexao' in locals() and conexao.is_connected():
            conexao.close()
            print("Conexão com MySQL encerrada.")
