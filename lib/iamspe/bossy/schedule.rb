# frozen_string_literal: true

require 'clipboard'
require 'sqlite3'
require 'tty-config'
require 'tty-prompt'
require 'tzinfo'
require 'yaml'

module Iamspe
  module Bossy
    # Classe de geração de escalas diárias
    class Schedule
      # Regexp de validação de cada linha da tabela de escala
      LINE_PATTERN = /(.+)\t(\d{2}:\d{2} - \d{2}:\d{2})\tDra\/Dr:\t(.+)/.freeze
      # Títulos de setores
      SECTORS = {
        chief: '🐝 Chefe Plantão',
        door: '🩺 Clínica Porta',
        obs: '👀 Observação Térreo',
        semi: '🛌🏻 Semi 1º Andar',
        enf: '🛌🏻 Enfermaria B+C 1º Andar',
        ucp: '🛌🏻 UCP',
        eme: '🚨 Sala de Emergência',
        dt: '❤️‍🩹 Dor Torácica',
        cge: '⚕ Cirurgia',
        cot: '🦴 Ortopedia',
        ped: '🧸 Pediatria'
      }.freeze
      # Texto para divisor de seções
      HR = '```============```'.freeze

      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        @config = fetch_config
        # Abrir conexão com o banco de dados
        @db = SQLite3::Database.open(@config.fetch(:db), { results_as_hash: true })
        # Checar se já foi gerada escala para hoje
        build_schedule if unmade?
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
        if config.exist?
          config.read
          config
        else
          raise 'Arquivo de configuração não encontrado. Reinstale esta gema.'
        end
      end

      # Checa se já foi aberta uma escala para hoje neste turno
      def unmade?
        date, turn = build_turn
        shift = @db.execute('SELECT * FROM schedule WHERE date = ? AND turn = ?', date, turn)
        shift.empty?
      end

      # Retorna a data e o turno atuais
      def build_turn
        foo = []
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        hour = tz.now.strftime('%H').to_i
        foo[1] = if hour < 13 && hour >= 1
                   'day'
                 else
                   if hour >= 0
                     day = tz.now.strftime('%d').to_i - 1
                     foo[0] = tz.now.strftime("%Y-%m-#{format('%02d', day)}")
                   end
                   'night'
                 end
        foo[0] = tz.now.strftime('%Y-%m-%d') if foo[0].nil?
        foo
      end

      # Inicia a interface de atribuições e salva a escala no banco de dados
      def build_schedule
        @staff = process_raw_data(get_raw_data)
        @out = ''
        # TODO: Continuar por aqui (salvar no BD, iniciar interface de atribuições)
      end

      # Pega os dados brutos da escala da área de transferência
      def get_raw_data
        @raw = nil
        # Repete até que o usuário tenha copiado um texto válido
        loop do
          puts 'FOO'
          @raw = Clipboard.paste.gsub(/\t\t\t\n/, '')
          break if LINE_PATTERN.match?(@raw)
          @prompt.keypress('Texto na área de transferência inválido, copie o texto da tabela de Escala, sem incluir cabeçalho, e pressione qualquer tecla para tentar de novo...') unless ok
        end
        # Retornar o texto colado
        @raw.split "\n"
      end

      # Processa os dados brutos e gera uma lista de plantonistas
      def process_raw_data(raw_data)
        raw_data.map do |w|
          w = w.split("\t") # Cada linha vira um _Array_ de colunas
          if /[0-9]+/i.match?(w[3])
            # Se dois plantonistas na mesma linha
            # Processar nomes e horários em um _Hash_
            workers = w[3].gsub(' às ', '-').split(/(?<=[0-9])\s/i).map do |y|
              y = y.split(/\s(?=[0-9])/i)
              y[1] = y[1].split('-').map { |i| i.gsub(/:00/, '').to_i }
              y.flatten!
              {name: y[0], start: y[1], stop: y[2], sector: w[0]}
            end
            # Usar _Hash_ para criar
            r = []
            workers.each do |z|
              r << Worker.new(z[:name], z[:start], z[:stop], z[:sector])
            end
            r
          else
            # Se apenas um plantonista na linha
            name = w[3]
            times = w[1].split(' - ').map do |t|
              t.gsub(/:00/, '').to_i
            end
            start = times[0]
            stop  = times[1]
            sector = w[0]
            Worker.new(name, start, stop, sector)
          end
        end
      end
    end

    # Define cada plantonista na escala
    class Worker
      ATTRIBUTIONNS = {
        chief: '⚪',
        orange: '🟠🟡',
        yellow: '🟡',
        green: '🟡🟢',
        fast: '🏃🏻‍♀️🟢',
        reeval: '🔁',
        obs: '🛏💺',
        cge: '⚪',
        cot: '🟢',
        ped: '⚪',
        eme: '🔴',
        dt: '🟠',
        ucp: '',
        semi: '',
        enf: ''
      }.freeze

      # Atalho para métodos de instância
      attr_accessor :name, :start, :stop, :sector, :attribution, :lunch

      # Inicializador
      def initialize(name, start, stop, sector)
        @name        = name.strip
        @start       = start.to_i
        @stop        = stop.to_i
        @sector      = parse_sector(sector)
        @present     = true
        @attribution = nil
        @lunch       = nil
      end

      # Definir novo horário de início de plantão
      def start=(new_start)
        if new_start.to_i.zero?
          @start = 7
        else
          @start = new_start.to_i
        end
      end

      # Definir novo horário de término de plantão
      def stop=(new_stop)
        if new_stop.to_i.zero?
          @stop = 19
        else
          @stop = new_stop.to_i
        end
      end

      # Definir novo horário de almoço
      def lunch=(new_lunch)
        if new_lunch.to_i.zero?
          @lunch = 7
        else
          @lunch = new_lunch.to_i
        end
      end

      # Definir setor
      def sector=(new_sector)
        @sector = parse_sector(new_sector)
      end

      # Marca o plantonista como ausente
      def missing!
        @present = false
      end

      # Se o plantonista está presente
      def present?
        @present
      end

      private

      # Transforma o texto (_String_) de cada setor no símbolo correspondente
      def parse_sector(sector)
        case sector.to_s
        when /chef/i then :chief
        when /obs/i then :obs
        when /semi/i then :semi
        when /enf/i then :enf
        when /ucp/i then :ucp
        when /eme/i then :eme
        when /dor.*tor/i then :dt
        when /cir/i then :cge
        when /ortop/i then :cot
        when /ped/i then :ped
        else
          :door
        end
      end
    end
  end
end
