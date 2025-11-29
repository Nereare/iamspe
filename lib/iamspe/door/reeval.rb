# frozen_string_literal: true

require 'sqlite3'
require 'tty-font'
require 'tty-pie'
require 'tty-prompt'
require 'tty-table'
require 'tzinfo'

# TODO: Refatorar para melhorar exportação de estatísticas
module Iamspe
  module Door
    # Classe de compilação de dados sobre reavaliações
    class Reeval
      # Cores para gráficos de pizza
      COLOUR = %i[
        red
        green
        yellow
        blue
        magenta
        cyan
        white
        bright_black
        bright_red
        bright_green
        bright_yellow
        bright_blue
        bright_magenta
        bright_cyan
        bright_white
      ].freeze
      # Problemas e seus títulos
      PROBLEM_TITLE = {
        'SUM(problem1)' => '1ª anamnese pouco útil',
        'SUM(problem2)' => '1ª anamnese incompatível com quadro',
        'SUM(problem3)' => 'Ausência de AP',
        'SUM(problem4)' => 'Ausência de MU',
        'SUM(problem5)' => 'Ausência de Alergias',
        'SUM(problem6)' => 'Ausência de EF',
        'SUM(problem7)' => 'EF incompatível com quadro',
        'SUM(problem8)' => 'Ausência de HD',
        'SUM(problem9)' => 'CD incompatível com quadro',
        'SUM(problem10)' => 'Exames desnecessários',
        'SUM(problem11)' => 'Exames errados (Labs/ECG)',
        'SUM(problem12)' => 'Exames errados (Imagens)',
        'SUM(problem13)' => 'Exames insuficientes',
        'SUM(problem14)' => 'Necessidade de re-reaval',
        'SUM(problem15)' => 'Outros'
      }.freeze
      # Tempo, em horas, para levantamento de dados prévios
      DELTA = 12

      # Inicializador
      def initialize
        # Incializar módulos TTY
        @font = TTY::Font.new(:standard)
        @prompt = TTY::Prompt.new
        @config = TTY::Config.new
        @config.filename = '.iamspe'
        @config.append_path Dir.home
        raise new Error, 'Arquivo de configuração não encontrado' unless @config.exist?

        @config.read
        # Inicializar variáveis de classe
        @prev = Time.now.strftime('%s').to_i - (DELTA * 60 * 60)
        @db_name = @config.fetch(:db)
        @out = []
        @db = open_db
        @session = []
        # Começar sessão de coleta de dados
        start_session
      end

      # Compilar texto de "output" com estatísticas
      def to_s
        @out.push @font.write("Total = #{parse_totals}")
        @out.push parse_sexes
        @out.push parse_meds
        @out.push @font.write("Nota #{parse_avg_score}")
        @out.push parse_scores
        @out.push problems_table
        @out.join "\n"
      end

      private

      # Abrir conexão com o banco de dados
      def open_db
        SQLite3::Database.new(@db_name, { results_as_hash: true })
      end

      # Iniciar sessão de coleta de dados de reavaliação
      def start_session
        loop do
          foo = pt_id
          break if foo[:atend].nil?

          foo = foo.merge pt_score
          foo = foo.merge pt_problems
          foo = foo.merge pt_other_problems if foo[:problem15]
          foo = foo.merge now
          @session.push foo
          insert foo
        end
      end

      # Compilar número total de reavaliações no período
      def parse_totals
        count = @db.execute('SELECT COUNT(datetime) AS count FROM reeval WHERE datetime >= ?', [@prev])
        count[0]['count']
      end

      # Compilar proporção de gêneros
      def parse_sexes
        table = @db.execute('SELECT sex, COUNT(sex) AS total FROM reeval WHERE datetime >= ? GROUP BY sex', [@prev])
        table = table.map do |x|
          { name: x['sex'], value: x['total'], color: COLOUR[rand(0..(COLOUR.length - 1))] }
        end
        TTY::Pie.new(data: table, radius: 8)
      end

      # Compilar proporção de médicos responsáveis pelo 1ª atendimento
      def parse_meds
        table = @db.execute('SELECT medic, COUNT(medic) AS total FROM reeval WHERE datetime >= ? GROUP BY medic',
                            [@prev])
        table = table.map do |x|
          { name: x['medic'], value: x['total'], color: COLOUR[rand(0..(COLOUR.length - 1))] }
        end
        TTY::Pie.new(data: table, radius: 8)
      end

      # Obter média das notas de qualidade de 1º atendimento
      def parse_avg_score
        avg = @db.execute('SELECT 1.0*sum(score)/count(score) AS avg FROM reeval WHERE datetime >= ?', [@prev])
        avg[0]['avg'].to_f.round 2
      end

      # Compilar proporção das notas de qualidade de 1º atendimento
      def parse_scores
        table = @db.execute(
          'SELECT score, COUNT(score) AS total FROM reeval WHERE datetime >= ? GROUP BY score ORDER BY score', [@prev]
        )
        table = table.map do |x|
          { name: x['score'], value: x['total'], color: COLOUR[rand(0..(COLOUR.length - 1))] }
        end
        TTY::Pie.new(data: table, radius: 8)
      end

      # Compilar tabela de problemas identificados
      def problems_table
        table = @db.execute(
          'SELECT SUM(problem1), SUM(problem2), SUM(problem3), SUM(problem4), SUM(problem5), SUM(problem6), SUM(problem7), SUM(problem8), SUM(problem9), SUM(problem10), SUM(problem11), SUM(problem12), SUM(problem13), SUM(problem14), SUM(problem15) FROM reeval WHERE datetime >= ?', [@prev]
        )[0]
        table = table.map do |key, value|
          [PROBLEM_TITLE[key], value]
        end
        table = TTY::Table.new(['Problema', '#'], table)
        table.render :unicode, alignments: %i[right left]
      end

      # Obter dados de identificação do paciente
      def pt_id
        @prompt.collect do
          key(:atend).ask('# Atendimento:') do |q|
            q.convert :int
          end
          next if @answers[:atend].nil?

          key(:age).ask('Idade do Paciente: (anos)') do |q|
            q.required true
            q.convert  :int
          end
          key(:sex).select('Expr. Gênero do Paciente:') do |q|
            q.choice name: 'MeninA', value: 'F'
            q.choice name: 'MeninO', value: 'M'
            q.choice name: 'Outro', value: '?'
          end
          key(:medic).ask('Médico Responsável:') do |q|
            q.required true
            q.modify   :trim, :up
          end
        end
      end

      # Obter nota de qualidade do 1º atendimento
      def pt_score
        s = @prompt.select('Qualidade Geral do 1º Atendimento:') do |q|
          q.choice name: "\u1f604 Péssimo", value: 1
          q.choice name: "\u2639 Ruim", value: 2
          q.choice name: "\u1f610 Regular", value: 3
          q.choice name: "\u1f642 Bom", value: 4
          q.choice name: "\u1f601 Ótimo", value: 5
        end
        { score: s }
      end

      # Obter problemas identificados no 1º atendimento
      def pt_problems
        foo = @prompt.multi_select('Quais problemas você encontrou?') do |q|
          q.choice   '1ª anamnese pouco útil', :problem1
          q.choice   '1ª anamnese incompatível com quadro', :problem2
          q.choice   'Ausência de AP', :problem3
          q.choice   'Ausência de MU', :problem4
          q.choice   'Ausência de Alergias', :problem5
          q.choice   'Ausência de EF', :problem6
          q.choice   'EF incompatível com quadro', :problem7
          q.choice   'Ausência de HD', :problem8
          q.choice   'CD incompatível com quadro', :problem9
          q.choice   'Exames desnecessários', :problem10
          q.choice   'Exames errados (Labs/ECG)', :problem11
          q.choice   'Exames errados (Imagens)', :problem12
          q.choice   'Exames insuficientes', :problem13
          q.choice   'Necessidade de re-reaval', :problem14
          q.choice   'Outros', :problem15
          q.help     '\u2191/\u2193 para mover | ESPAÇO para selecionar um | Ctrl+A para selecionar TODOS | ENTER para finalizar'
          q.per_page 15
        end
        bar = { problem1: false, problem2: false, problem3: false, problem4: false, problem5: false, problem6: false,
                problem7: false, problem8: false, problem9: false, problem10: false, problem11: false, problem12: false, problem13: false, problem14: false, problem15: false }
        bar.each do |key, _value|
          bar[key] = foo.include?(key) ? 1 : 0
        end
        bar
      end

      # Obter descrição de outros problemas identificados
      def pt_other_problems
        foo = @prompt.multiline('Quais são os outros problemas identificados?') do |q|
          q.required true
          q.help     'Use Ctrl+D para submeter.'
          q.modify   :trim
        end
        { outros_problem: foo }
      end

      # Inserir reavaliação no banco de dados
      def insert(obj)
        p obj
        @db.execute 'INSERT INTO reeval (datetime, atend, age, sex, medic, score, problem1, problem2, problem3, problem4, problem5, problem6, problem7, problem8, problem9, problem10, problem11, problem12, problem13, problem14, problem15, outros_problem) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    [obj[:datetime], obj[:atend], obj[:age], obj[:sex], obj[:medic], obj[:score], obj[:problem1], obj[:problem2], obj[:problem3],
                     obj[:problem4], obj[:problem5], obj[:problem6], obj[:problem7], obj[:problem8], obj[:problem9], obj[:problem10], obj[:problem11], obj[:problem12], obj[:problem13], obj[:problem14], obj[:problem15], obj[:outros_problem]]
      end

      # Obter timestamp atual
      def now
        time = Time.now
        { datetime: time.strftime('%s') }
      end
    end
  end
end
