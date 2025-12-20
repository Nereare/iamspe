CREATE TABLE IF NOT EXISTS reeval (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  datetime DATETIME NOT NULL,
  atend INT NOT NULL,
  age INT,
  sex VARCHAR(1) NOT NULL,
  medic VARCHAR(128) NOT NULL,
  score INT NOT NULL,
  problem1 BOOLEAN NOT NULL, -- 1ª anamnese pouco útil
  problem2 BOOLEAN NOT NULL, -- 1ª anamnese incompatível com quadro
  problem3 BOOLEAN NOT NULL, -- Ausência de AP
  problem4 BOOLEAN NOT NULL, -- Ausência de MU
  problem5 BOOLEAN NOT NULL, -- Ausência de Alergias
  problem6 BOOLEAN NOT NULL, -- Ausência de EF
  problem7 BOOLEAN NOT NULL, -- EF incompatível com quadro
  problem8 BOOLEAN NOT NULL, -- Ausência de HD
  problem9 BOOLEAN NOT NULL, -- CD incompatível com quadro
  problem10 BOOLEAN NOT NULL, -- Exames desnecessários
  problem11 BOOLEAN NOT NULL, -- Exames errados (Labs/ECG)
  problem12 BOOLEAN NOT NULL, -- Exames errados (Imagens)
  problem13 BOOLEAN NOT NULL, -- Exames insuficientes
  problem14 BOOLEAN NOT NULL, -- Necessidade de re-reaval
  problem15 BOOLEAN NOT NULL, -- Outros
  outros_problem TEXT
);