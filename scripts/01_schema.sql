-- =============================================================
-- Biblioteca — Modelo físico (SQLite 3.35+)
-- Autor: Prof. Eduardo Furlanetti
-- O SQLite guarda todo o banco em um único arquivo e não precisa
-- de servidor: ideal para aplicações embarcadas, mobile e protótipos.
-- =============================================================

PRAGMA foreign_keys = ON;   -- no SQLite, chaves estrangeiras vêm desligadas

DROP TABLE IF EXISTS emprestimo;
DROP TABLE IF EXISTS exemplar;
DROP TABLE IF EXISTS livro_autor;
DROP TABLE IF EXISTS autor;
DROP TABLE IF EXISTS livro;
DROP TABLE IF EXISTS leitor;

CREATE TABLE livro (
    id_livro  INTEGER PRIMARY KEY,               -- alias do ROWID: autoincremento
    isbn      TEXT    NOT NULL UNIQUE CHECK (length(isbn) = 13),
    titulo    TEXT    NOT NULL,
    editora   TEXT,
    ano       INTEGER CHECK (ano BETWEEN 1450 AND 2100),
    assunto   TEXT    NOT NULL
);

CREATE TABLE autor (
    id_autor INTEGER PRIMARY KEY,
    nome     TEXT NOT NULL
);

CREATE TABLE livro_autor (
    id_livro INTEGER NOT NULL REFERENCES livro (id_livro) ON DELETE CASCADE,
    id_autor INTEGER NOT NULL REFERENCES autor (id_autor),
    PRIMARY KEY (id_livro, id_autor)
);

-- Cada livro pode ter vários exemplares físicos
CREATE TABLE exemplar (
    id_exemplar INTEGER PRIMARY KEY,
    id_livro    INTEGER NOT NULL REFERENCES livro (id_livro) ON DELETE CASCADE,
    tombo       TEXT    NOT NULL UNIQUE,
    situacao    TEXT    NOT NULL DEFAULT 'DISPONIVEL'
                CHECK (situacao IN ('DISPONIVEL', 'EMPRESTADO', 'EXTRAVIADO'))
);

CREATE TABLE leitor (
    id_leitor INTEGER PRIMARY KEY,
    nome      TEXT NOT NULL,
    email     TEXT NOT NULL UNIQUE,
    tipo      TEXT NOT NULL CHECK (tipo IN ('ALUNO', 'PROFESSOR'))
);

-- Datas no SQLite: texto ISO-8601 (AAAA-MM-DD), manipuladas com date()/julianday()
CREATE TABLE emprestimo (
    id_emprestimo   INTEGER PRIMARY KEY,
    id_exemplar     INTEGER NOT NULL REFERENCES exemplar (id_exemplar),
    id_leitor       INTEGER NOT NULL REFERENCES leitor (id_leitor),
    data_emprestimo TEXT    NOT NULL DEFAULT (date('now')),
    data_prevista   TEXT    NOT NULL,
    data_devolucao  TEXT,
    CHECK (data_prevista >= data_emprestimo)
);

CREATE INDEX ix_emprestimo_aberto ON emprestimo (id_exemplar) WHERE data_devolucao IS NULL;

-- Triggers mantêm a situação do exemplar coerente com os empréstimos
CREATE TRIGGER trg_emprestar
BEFORE INSERT ON emprestimo
BEGIN
    SELECT RAISE(ABORT, 'Exemplar indisponível')
    WHERE (SELECT situacao FROM exemplar WHERE id_exemplar = NEW.id_exemplar) <> 'DISPONIVEL';
END;

CREATE TRIGGER trg_marca_emprestado
AFTER INSERT ON emprestimo
WHEN NEW.data_devolucao IS NULL
BEGIN
    UPDATE exemplar SET situacao = 'EMPRESTADO' WHERE id_exemplar = NEW.id_exemplar;
END;

CREATE TRIGGER trg_devolver
AFTER UPDATE OF data_devolucao ON emprestimo
WHEN OLD.data_devolucao IS NULL AND NEW.data_devolucao IS NOT NULL
BEGIN
    UPDATE exemplar SET situacao = 'DISPONIVEL' WHERE id_exemplar = NEW.id_exemplar;
END;

-- Busca textual completa com FTS5 (extensão nativa do SQLite)
CREATE VIRTUAL TABLE IF NOT EXISTS livro_fts USING fts5(titulo, assunto, content='livro', content_rowid='id_livro');
