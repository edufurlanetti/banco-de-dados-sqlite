-- Soluções — Biblioteca (SQLite)
PRAGMA foreign_keys = ON;

-- 1
SELECT titulo, ano FROM livro WHERE ano >= 2015 ORDER BY ano DESC;

-- 2
SELECT assunto, COUNT(*) AS livros FROM livro GROUP BY assunto ORDER BY livros DESC;

-- 3
SELECT nome FROM leitor
WHERE id_leitor NOT IN (SELECT id_leitor FROM emprestimo);

-- 4
SELECT ROUND(AVG(julianday(data_devolucao) - julianday(data_emprestimo)), 1) AS media_dias
FROM emprestimo
WHERE data_devolucao IS NOT NULL;

-- 5
DROP VIEW IF EXISTS vw_emprestimos_abertos;
CREATE VIEW vw_emprestimos_abertos AS
SELECT le.nome AS leitor, l.titulo, e.tombo, em.data_prevista
FROM emprestimo em
JOIN exemplar e ON e.id_exemplar = em.id_exemplar
JOIN livro l    ON l.id_livro    = e.id_livro
JOIN leitor le  ON le.id_leitor  = em.id_leitor
WHERE em.data_devolucao IS NULL;

SELECT * FROM vw_emprestimos_abertos;

-- 6
DROP TRIGGER IF EXISTS trg_limite_emprestimos;
CREATE TRIGGER trg_limite_emprestimos
BEFORE INSERT ON emprestimo
BEGIN
    SELECT RAISE(ABORT, 'Limite de empréstimos simultâneos atingido')
    WHERE (SELECT COUNT(*) FROM emprestimo
           WHERE id_leitor = NEW.id_leitor AND data_devolucao IS NULL)
          >= (SELECT CASE tipo WHEN 'PROFESSOR' THEN 5 ELSE 2 END
              FROM leitor WHERE id_leitor = NEW.id_leitor);
END;

-- 7 (Python) — acrescente em app/biblioteca.py:
--
-- def historico(id_leitor: int) -> None:
--     sql = """
--         SELECT l.titulo, em.data_emprestimo, em.data_devolucao
--         FROM emprestimo em
--         JOIN exemplar e ON e.id_exemplar = em.id_exemplar
--         JOIN livro l    ON l.id_livro    = e.id_livro
--         WHERE em.id_leitor = ?
--         ORDER BY em.data_emprestimo
--     """
--     with conectar() as conexao:
--         for linha in conexao.execute(sql, (id_leitor,)):
--             situacao = linha["data_devolucao"] or "em aberto"
--             print(f"- {linha['titulo']}: {linha['data_emprestimo']} → {situacao}")
--
-- e registre no dicionário de comandos:
--     "historico": lambda: historico(int(argumentos[1])),
