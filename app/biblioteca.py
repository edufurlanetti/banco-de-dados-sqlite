"""Aplicação de linha de comando da Biblioteca usando SQLite.

Demonstra como uma aplicação Python acessa o banco com o módulo
padrão ``sqlite3``: conexão, consultas parametrizadas (sem SQL
injection), transações e tratamento de erros vindos de triggers.

Uso:
    python app/biblioteca.py criar                  # cria e popula biblioteca.db
    python app/biblioteca.py buscar banco           # busca textual
    python app/biblioteca.py emprestar 3 1 7        # exemplar 3 para o leitor 1 por 7 dias
    python app/biblioteca.py devolver 3             # devolve o exemplar 3
    python app/biblioteca.py atrasos                # empréstimos em atraso hoje
"""

from __future__ import annotations

import sqlite3
import sys
from datetime import date, timedelta
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
BANCO = RAIZ / "biblioteca.db"
SCRIPTS = RAIZ / "scripts"


def conectar() -> sqlite3.Connection:
    conexao = sqlite3.connect(BANCO)
    conexao.row_factory = sqlite3.Row          # acesso às colunas pelo nome
    conexao.execute("PRAGMA foreign_keys = ON")
    return conexao


def criar() -> None:
    with conectar() as conexao:
        for nome in ("01_schema.sql", "02_dados.sql"):
            conexao.executescript((SCRIPTS / nome).read_text(encoding="utf-8"))
    print(f"Banco criado em {BANCO}")


def buscar(termo: str) -> None:
    sql = """
        SELECT l.titulo, l.assunto,
               SUM(e.situacao = 'DISPONIVEL') AS disponiveis
        FROM livro_fts f
        JOIN livro l    ON l.id_livro = f.rowid
        JOIN exemplar e ON e.id_livro = l.id_livro
        WHERE livro_fts MATCH ?
        GROUP BY l.id_livro
        ORDER BY f.rank
    """
    with conectar() as conexao:
        linhas = conexao.execute(sql, (termo,)).fetchall()
    if not linhas:
        print("Nenhum livro encontrado.")
    for linha in linhas:
        print(f"- {linha['titulo']} ({linha['assunto']}) — {linha['disponiveis']} disponível(is)")


def emprestar(id_exemplar: int, id_leitor: int, dias: int) -> None:
    hoje = date.today()
    try:
        with conectar() as conexao:            # commit automático ou rollback em erro
            conexao.execute(
                "INSERT INTO emprestimo (id_exemplar, id_leitor, data_emprestimo, data_prevista) "
                "VALUES (?, ?, ?, ?)",
                (id_exemplar, id_leitor, hoje.isoformat(), (hoje + timedelta(days=dias)).isoformat()),
            )
        print(f"Empréstimo registrado. Devolver até {hoje + timedelta(days=dias):%d/%m/%Y}.")
    except sqlite3.IntegrityError as erro:     # erros de FK, CHECK ou RAISE(ABORT) das triggers
        print(f"Não foi possível emprestar: {erro}")


def devolver(id_exemplar: int) -> None:
    with conectar() as conexao:
        cursor = conexao.execute(
            "UPDATE emprestimo SET data_devolucao = ? "
            "WHERE id_exemplar = ? AND data_devolucao IS NULL",
            (date.today().isoformat(), id_exemplar),
        )
    print("Devolução registrada." if cursor.rowcount else "Não há empréstimo em aberto para esse exemplar.")


def atrasos() -> None:
    sql = """
        SELECT le.nome, l.titulo, em.data_prevista,
               CAST(julianday('now') - julianday(em.data_prevista) AS INTEGER) AS dias
        FROM emprestimo em
        JOIN exemplar e ON e.id_exemplar = em.id_exemplar
        JOIN livro l    ON l.id_livro    = e.id_livro
        JOIN leitor le  ON le.id_leitor  = em.id_leitor
        WHERE em.data_devolucao IS NULL AND em.data_prevista < date('now')
        ORDER BY dias DESC
    """
    with conectar() as conexao:
        for linha in conexao.execute(sql):
            print(f"- {linha['nome']}: '{linha['titulo']}' ({linha['dias']} dia(s) de atraso)")


def main(argumentos: list[str]) -> None:
    comandos = {
        "criar": lambda: criar(),
        "buscar": lambda: buscar(argumentos[1]),
        "emprestar": lambda: emprestar(int(argumentos[1]), int(argumentos[2]), int(argumentos[3])),
        "devolver": lambda: devolver(int(argumentos[1])),
        "atrasos": lambda: atrasos(),
    }
    if not argumentos or argumentos[0] not in comandos:
        print(__doc__)
        return
    comandos[argumentos[0]]()


if __name__ == "__main__":
    main(sys.argv[1:])
