-- =============================================================
-- Biblioteca — Consultas comentadas (SQLite)
-- No terminal do sqlite3, use:  .headers on  e  .mode column
-- =============================================================
PRAGMA foreign_keys = ON;

-- 1. Livros com seus autores em uma única coluna (GROUP_CONCAT)
SELECT l.titulo, GROUP_CONCAT(a.nome, ', ') AS autores
FROM livro l
JOIN livro_autor la ON la.id_livro = l.id_livro
JOIN autor a        ON a.id_autor  = la.id_autor
GROUP BY l.id_livro
ORDER BY l.titulo;

-- 2. Disponibilidade: exemplares disponíveis de cada livro
SELECT l.titulo,
       COUNT(e.id_exemplar)                                   AS exemplares,
       SUM(CASE WHEN e.situacao = 'DISPONIVEL' THEN 1 ELSE 0 END) AS disponiveis
FROM livro l
LEFT JOIN exemplar e ON e.id_livro = l.id_livro
GROUP BY l.id_livro
ORDER BY l.titulo;

-- 3. Empréstimos em atraso em uma data de referência
--    (troque '2026-03-15' por date('now') para usar a data atual)
SELECT le.nome, l.titulo, e.tombo, em.data_prevista,
       CAST(julianday('2026-03-15') - julianday(em.data_prevista) AS INTEGER) AS dias_atraso
FROM emprestimo em
JOIN exemplar e ON e.id_exemplar = em.id_exemplar
JOIN livro l    ON l.id_livro    = e.id_livro
JOIN leitor le  ON le.id_leitor  = em.id_leitor
WHERE em.data_devolucao IS NULL
  AND em.data_prevista < '2026-03-15';

-- 4. Multa por atraso nas devoluções já feitas (R$ 2,00 por dia)
SELECT le.nome, l.titulo,
       CAST(julianday(em.data_devolucao) - julianday(em.data_prevista) AS INTEGER) AS dias,
       printf('R$ %.2f', 2.0 * (julianday(em.data_devolucao) - julianday(em.data_prevista))) AS multa
FROM emprestimo em
JOIN exemplar e ON e.id_exemplar = em.id_exemplar
JOIN livro l    ON l.id_livro    = e.id_livro
JOIN leitor le  ON le.id_leitor  = em.id_leitor
WHERE em.data_devolucao > em.data_prevista;

-- 5. Leitores mais ativos (função de janela — SQLite 3.25+)
SELECT le.nome, COUNT(*) AS emprestimos,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS posicao
FROM emprestimo em
JOIN leitor le ON le.id_leitor = em.id_leitor
GROUP BY le.id_leitor;

-- 6. Busca textual completa (FTS5): livros sobre "banco"
SELECT l.titulo, l.assunto
FROM livro_fts f
JOIN livro l ON l.id_livro = f.rowid
WHERE livro_fts MATCH 'banco'
ORDER BY rank;

-- 7. UPSERT: cadastra ou atualiza um leitor pelo e-mail (SQLite 3.24+)
INSERT INTO leitor (nome, email, tipo) VALUES ('Ana Souza Lima', 'ana@aluno.edu', 'ALUNO')
ON CONFLICT (email) DO UPDATE SET nome = excluded.nome;
SELECT id_leitor, nome, email FROM leitor WHERE email = 'ana@aluno.edu';

-- 8. Devolução: a trigger libera o exemplar automaticamente
UPDATE emprestimo SET data_devolucao = '2026-03-10'
WHERE id_exemplar = 2 AND data_devolucao IS NULL;
SELECT tombo, situacao FROM exemplar WHERE id_exemplar = 2;

-- 9. Regra de negócio: emprestar exemplar já emprestado deve falhar
--    com "Exemplar indisponível"
-- INSERT INTO emprestimo (id_exemplar, id_leitor, data_prevista) VALUES (7, 1, '2026-12-31');
