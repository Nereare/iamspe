# frozen_string_literal: true

require 'clipboard'
require 'pastel'
require 'sqlite3'
require 'tty-config'
require 'tty-prompt'

module Iamspe
  module Bossy
    # Classe de lista de solicitações de CATEs e UTIs
    class IcuCath
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt & Pastel
        @prompt = TTY::Prompt.new
        @pastel = Pastel.new
        # Inicializar TTY::Config
        @config = fetch_config
        # Inicializar banco de dados
        @db = SQLite3::Database.open(@config.fetch(:db), { results_as_hash: true })

        # Inicializar variáveis
        @patients = {}
        @eme_beds = @config.fetch(:eme, :leitos)
        @eme_ext = @config.fetch(:eme, :contingencia)
        @semi_beds = @config.fetch(:semi, :leitos)
        @ucp_beds = @config.fetch(:ucp, :leitos)
        @you = @config.fetch(:nome)
        # Compilar dados
        build_patients
      end

      # Compilar texto de "output" e retorná-lo como _String_
      def to_s
        # Texto de UTIs
        Clipboard.copy(parse_icu)
        puts "<< Texto de UTI copiado! >>\n\n"
        @prompt.keypress('Pressione qualquer tecla para continuar, ou aguarde mais :countdown s...', timeout: 60)

        # Texto de CATEs
        Clipboard.copy(parse_cath)
        '<< Texto de CATE copiado! >>'
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

      # Invocar formulários cabíveis e salvar nova entrada no BD
      def build_order
        build_dt
        build_semi
        build_ucp
        build_eme
        save_patients
      end

      # Invocar formulários de ocupações de cada setor
      def build_patients
        if unmade?
          build_order
        else
          puts @pastel.green 'Já inicializado!'
          reload = @prompt.yes?('Carregar último?') do |q|
            q.positive 's'
            q.negative 'n'
          end
          if reload
            fetch_patients
          else
            build_order
          end
        end
      end

      # Checa se já foi levantada ocupação para hoje neste turno
      def unmade?
        date = parse_time(full: true)
        turn = parse_turn(db: true)
        shift = @db.execute('SELECT * FROM critical WHERE date = ? AND turn = ?', date, turn)
        shift.empty?
      end

      # Reaver ocupação prévia
      def fetch_patients
        res = @db.execute(
          'SELECT * FROM critical WHERE date = ? AND turn = ? ORDER BY date DESC',
          [parse_time(full: true), parse_turn(db: true)]
        )
        if res.nil?
          build_patients
        else
          patients_from_db res[0]
        end
        to_s
      end

      # Usar dados do BD para popular variáveis de instância
      def patients_from_db(res)
        # DT
        @patients[:dt] = res['dt']
        # Semi
        @patients[:semi] = {}
        @patients[:semi][:count] = res['semi_count']
        @patients[:semi][:out] = res['semi_out']
        @patients[:semi][:icu] = res['semi_icu']
        @patients[:semi][:cath] = res['semi_cath']
        # UCP
        @patients[:ucp] = {}
        @patients[:ucp][:count] = res['ucp_count']
        @patients[:ucp][:out] = res['ucp_out']
        @patients[:ucp][:icu] = res['ucp_icu']
        @patients[:ucp][:cath] = res['ucp_cath']
        # EME
        @patients[:eme] = {}
        @patients[:eme][:count] = res['eme_count']
        @patients[:eme][:icu] = res['eme_icu']
        @patients[:eme][:cath] = res['eme_cath']
      end

      # Salvar pacientes obtidos para o BD
      def save_patients
        entries = [
          parse_time(full: true),
          parse_turn(db: true),
          @patients[:dt],
          @patients[:semi][:count],
          @patients[:semi][:out],
          @patients[:semi][:icu],
          @patients[:semi][:cath],
          @patients[:ucp][:count],
          @patients[:ucp][:out],
          @patients[:ucp][:icu],
          @patients[:ucp][:cath],
          @patients[:eme][:count],
          @patients[:eme][:icu],
          @patients[:eme][:cath]
        ]
        @db.execute(
          'INSERT INTO critical (date, turn, dt, semi_count, semi_out, semi_icu, semi_cath, ucp_count, ucp_out, ucp_icu, ucp_cath, eme_count, eme_icu, eme_cath) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          entries
        )
      end

      # Formulário de pacientes na DT
      def build_dt
        @patients[:dt] = @prompt.ask("#{@pastel.red('(DT)')} Pacientes em protocolo:") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
      end

      # Formulários de pacientes, CATEs, e UTIs na Semi
      def build_semi
        @patients[:semi] = {}
        @patients[:semi][:count] = @prompt.ask("#{@pastel.red('(Semi)')} Pacientes totais:") do |q|
          q.required true
          q.convert  :int
        end
        @patients[:semi][:out] = @prompt.ask("#{@pastel.red('(Semi)')} Altas?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
        @patients[:semi][:icu] = @prompt.ask("#{@pastel.red('(Semi)')} UTIs?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
        @patients[:semi][:cath] = @prompt.ask("#{@pastel.red('(Semi)')} CATEs?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
      end

      # Formulários de pacientes, CATEs, e UTIs na UCP
      def build_ucp
        @patients[:ucp] = {}
        @patients[:ucp][:count] = @prompt.ask("#{@pastel.red('(UCP)')} Pacientes totais:") do |q|
          q.required true
          q.convert  :int
        end
        @patients[:ucp][:out] = @prompt.ask("#{@pastel.red('(UCP)')} Altas?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
        @patients[:ucp][:icu] = @prompt.ask("#{@pastel.red('(UCP)')} UTIs?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
        @patients[:ucp][:cath] = @prompt.ask("#{@pastel.red('(UCP)')} CATEs?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
      end

      # Formulários de pacientes, CATEs, e UTIs na Emergência
      def build_eme
        @patients[:eme] = {}
        @patients[:eme][:count] = @prompt.ask("#{@pastel.red('(EME)')} Pacientes totais:") do |q|
          q.required true
          q.convert  :int
        end
        @patients[:eme][:icu] = @prompt.ask("#{@pastel.red('(EME)')} UTIs?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
        @patients[:eme][:cath] = @prompt.ask("#{@pastel.red('(EME)')} CATEs?") do |q|
          q.required true
          q.convert  :int
          q.default  0
        end
      end

      # Retorna o Array do cabeçalho comum aos dois textos
      def parse_header
        [
          "\x2a🔴 \x60ATUALIZAÇÃO\x60 🩸\x2a",
          "- *Chefe:* #{@you}",
          "- *Plantão:* #{parse_time} / #{parse_turn}"
        ]
      end

      # Retorna texto formatado de solicitações de UTI
      def parse_icu
        out = parse_header
        # DT
        out.push "\x2aDT:\x2a"
        out.push "- \x60#{@patients[:dt]}\x60 paciente#{'s' if @patients[:dt] > 1} em protocolo"
        # Semi
        out.push "\x2aSemi:\x2a"
        out.push "- \x60#{@patients[:semi][:count]}\x60 paciente#{'s' if @patients[:semi][:count] > 1}"
        free = @semi_beds - @patients[:semi][:count]
        out.push "- \x60#{free}\x60 leito#{'s' unless free == 1} vago#{'s' unless free == 1}"
        out.push "- \x60#{@patients[:semi][:out]} possíve#{@patients[:semi][:out] > 1 ? 'is' : 'l'} alta#{'s' if @patients[:semi][:out] > 1}"
        out.push "- \x60#{@patients[:semi][:icu]} UTI#{'s' unless @patients[:semi][:out] == 1}"
        # UCP
        out.push "\x2aUCP:\x2a"
        out.push "- \x60#{@patients[:ucp][:count]}\x60 paciente#{'s' if @patients[:ucp][:count] > 1}"
        free = @ucp_beds - @patients[:ucp][:count]
        out.push "- \x60#{free}\x60 leito#{'s' unless free == 1} vago#{'s' unless free == 1}"
        out.push "- \x60#{@patients[:ucp][:out]} possíve#{@patients[:ucp][:out] > 1 ? 'is' : 'l'} alta#{'s' if @patients[:ucp][:out] > 1}"
        out.push "- \x60#{@patients[:ucp][:icu]} UTI#{'s' unless @patients[:ucp][:out] == 1}"
        # EME
        out.push "\x2aEME:\x2a"
        out.push "- \x60#{@patients[:eme][:count]}\x60 paciente#{'s' if @patients[:eme][:count] > 1}"
        free = @eme_beds.to_i - @patients[:eme][:count].to_i
        if free.negative?
          out.push "- \x60#{free + @eme_ext}\x60 leito#{'s' unless (free + @eme_ext) == 1} \x2ada Contingência\x2a não utilizado#{'s' unless (free + @eme_ext) == 1}"
        else
          out.push "- \x60#{free}\x60 leito#{'s' unless free == 1} vago#{'s' unless free == 1}"
          out.push '- Contingência vazia'
        end
        out.push "- \x60#{@patients[:eme][:icu]} UTI#{'s' unless @patients[:eme][:icu] == 1}"

        # Retornar valor concatenado
        out.join "\n"
      end

      def parse_cath
        out = parse_header
        # EME
        out.push "- \x60EME:\x60 #{@patients[:eme][:cath]} solicitaç#{@patients[:eme][:cath] == 1 ? 'ão' : 'ões'}"
        # Semi
        out.push "- \x60Semi:\x60 #{@patients[:semi][:cath]} solicitaç#{@patients[:semi][:cath] == 1 ? 'ão' : 'ões'}"
        # UCP
        out.push "- \x60UCP:\x60 #{@patients[:ucp][:cath]} solicitaç#{@patients[:ucp][:cath] == 1 ? 'ão' : 'ões'}"

        # Retornar valor concatenado
        out.join "\n"
      end

      # Obter tempo em formato configurado para região
      def parse_time(full: false)
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        now = Time.now
        now = tz.to_local(now)
        now.strftime('%e/%b') unless full
        now.strftime('%Y-%m-%d')
      end

      # Obter se plantão diurno ou noturno
      def parse_turn(db: false)
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        now = Time.now
        now = tz.to_local(now)
        hour = now.hour
        if hour >= 7 && hour < 19
          db ? 'day' : 'Diurno'
        else
          db ? 'night' : 'Noturno'
        end
      end
    end
  end
end
