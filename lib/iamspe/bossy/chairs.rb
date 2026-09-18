# frozen_string_literal: true

require 'active_support'
require 'clipboard'
require 'pastel'
require 'sqlite3'
require 'tty-prompt'
require 'tzinfo'

module Iamspe
  module Bossy
    # Classe de aguardo de repouso no leito
    class Chairs
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt & Pastel
        @prompt = TTY::Prompt.new
        @pastel = Pastel.new
        # Inicializar TTY::Config
        @config = fetch_config
        # Inicializar banco de dados
        @db = SQLite3::Database.open(@config.fetch(:db), { results_as_hash: true })
        # Obter chefe de plantão
        @chief = @config.fetch(:nome)

        # Coletar esperas novas ou reobter espera prévia, e interpretar dados
        if unmade?
          interpret_patients
        else
          fetch_patients
        end
        # Gerar relatório de espera para hoje
        build_report
        # Compilar texto de "output"
        @out = build_report
      end

      # Converter em _String_, no caso sendo o texto de "output"
      def to_s
        Clipboard.copy(@out)
        '<< Texto copiado! >>'
      end

      private

      # Inicializar TTY::Config
      def fetch_config
        config = TTY::Config.new
        config.filename = '.iamspe'
        config.append_path Dir.home
        raise 'Arquivo de configuração não encontrado. Reinstale esta gema.' unless config.exist?

        config.read
        config
      end

      # Checa se já foi aberta uma escala para hoje neste turno
      def unmade?
        date, turn = build_turn
        shift = @db.execute('SELECT * FROM chair WHERE date = ? AND turn = ?', date, turn)
        shift.empty?
      end

      # Retorna a data e o turno atuais
      def build_turn
        foo = []
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        hour = tz.now.strftime('%H').to_i
        foo[1] = if hour < 13 && hour >= 7
                   'morning'
                 elsif hour < 19 && hour >= 13
                   'noon'
                 elsif hour < 7 && hour >= 1
                   'late night'
                 else
                   'evening'
                 end
        if hour >= 0 && hour < 7
          day = tz.now.strftime('%d').to_i - 1
          foo[0] = tz.now.strftime("%Y-%m-#{format('%02d', day)}")
        end
        foo[0] = tz.now.strftime('%Y-%m-%d') if foo[0].nil?
        foo
      end

      # Coletar pacientes novos
      def interpret_patients
        @clm = @prompt.ask('Esperas CLM:') do |q|
          q.required true
          q.convert  :int
        end
        @other = @prompt.ask('Esperas Outras:') do |q|
          q.required true
          q.convert  :int
        end
        # Salvar para BD
        save_chairs
      end

      # Reaver pacientes prévios
      def fetch_patients
        @res = @db.execute(
          'SELECT * FROM chair WHERE date = ? AND turn = ?',
          [parse_time(full: true), build_turn[1]]
        )
        if @res.nil?
          interpret_patients
        else
          @clm = @res[0]['general']
          @other = @res[0]['other']
        end
        puts @pastel.blue.bold("Total = #{@clm + @other}")
        puts "- #{@pastel.blue('CLM')} = #{@clm}"
        puts "- #{@pastel.blue('Outros')} = #{@other}"
      end

      # Salvar esperas para BD
      def save_chairs
        @db.execute(
          'INSERT INTO chair (date, turn, general, other) VALUES (?, ?, ?, ?)',
          [parse_time(full: true), build_turn[1], @clm, @other]
        )
      end

      # Construir texto de exibição
      def build_report
        out = "\x2a⏳ \x60ATUALIZAÇÃO - CHEFIA DE PLANTÃO\x60 🛏\x2a\n"
        out += "\x2aPlantão:\x2a TODAY\n"
        out += "\x2aChefe:\x2a #{@chief}\n"
        out += "\n"
        out += "\x2aTotal Aguardando:\x2a #{@clm + @other}\n"
        out += "- \x2aCLM:\x2a #{@clm} paciente#{'s' if @clm.positive?}\n"
        out += "- \x2aOutros:\x2a #{@other} paciente#{'s' if @other.positive?}"
        out.gsub('TODAY', parse_time)
      end

      # Obter tempo em formato configurado para região
      def parse_time(full: false)
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        now = Time.now
        now = tz.to_local(now)
        now.strftime('%e/%b') unless full
        now.strftime('%Y-%m-%d')
      end
    end
  end
end
