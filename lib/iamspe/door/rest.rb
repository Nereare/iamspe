# frozen_string_literal: true

require 'tty-prompt'
require 'tzinfo'

module Iamspe
  module Door
    # Classe de solicitação de repouso no leito
    class Rest
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Inicializar TTY::Config
        @config = TTY::Config.new
        @config.filename = '.iamspe'
        @config.append_path Dir.home
        raise new Error, 'Arquivo de configuração não encontrado' unless @config.exist?

        @config.read

        # Coletar dados
        req = { physician: @config.fetch(:nome).upcase }
        req.merge! patient
        req.merge! rest_type
        req.merge! hd
        req.merge! notes
        patient = parse_patient(req)
        obs = parse_notes(req)
        now = parse_time
        # Compilar texto de "output"
        @out = parse_output(req, patient, obs, now)
      end

      # Converter em _String_, no caso sendo o texto de "output"
      def to_s
        @out
      end

      private

      # Obter dados do paciente
      def patient
        patient = patient_name
        patient.merge! patient_age
        patient.merge! patient_same
        patient
      end

      # Obter nome do paciente
      def patient_name
        @prompt.collect do
          key(:patient).ask('Paciente:') do |q|
            q.required true
            q.validate(/^[A-Za-z ]+$/)
            q.modify   :up, :trim
          end
        end
      end

      # Obter idade do paciente, se aplicável
      def patient_age
        @prompt.collect do
          key(:age).ask('Idade:') do |q|
            q.required false
            q.validate do |input|
              !input.to_f.nan? || input.nil?
            end
          end
        end
      end

      # Obter prontuário do paciente, se aplicável
      def patient_same
        @prompt.collect do
          key(:pront).ask('Same:') do |q|
            q.required false
            q.validate do |input|
              !input.to_f.nan? || input.nil?
            end
          end
        end
      end

      # Selecionar tipo de solicitação
      def rest_type
        @prompt.collect do
          key(:type).select('Tipo de solicitação:', %w[repouso ih])
          key(:external).select('Elegível para regulação?') do |menu|
            menu.choice(name: 'Sim', value: 'baixa complexidade')
            menu.choice(name: 'Sim (média complex.)', value: 'média complexidade')
            menu.choice(name: 'Sim (mas HNSF)', value: 'mas HNSF')
            menu.choice(name: 'Não', value: false)
          end
          key(:priority).select('Prioridade:') do |menu|
            menu.choice(name: 'Baixa', value: 0)
            menu.choice(name: 'Média', value: 1)
            menu.choice(name: 'Alta', value: 2)
          end
        end
      end

      # Obter hipótese diagnóstica
      def hd
        @prompt.collect do
          key(:hd).ask('HD:') do |q|
            q.required true
            q.modify   :trim
          end
        end
      end

      # Obter observações adicionais, se aplicável
      def notes
        @prompt.collect do
          key(:obs).multiline('Observações?') do |q|
            q.help     'Use Ctrl+D ou Ctrl+Z para terminar'
            q.modify   :trim
          end
        end
      end

      # Compilar paciente com idade e SAME, se disponíveis
      def parse_patient(req)
        patient = "\x60#{req[:patient]}\x60"
        patient += ", #{req[:age]}a" unless req[:age].nil?
        patient += ", Same #{req[:pront]}" unless req[:pront].nil?
        patient
      end

      # Compilar observações
      def parse_notes(req)
        if req[:obs].empty?
          'ndn'
        else
          obs = req[:obs].map(&:strip)
          obs.join("\n")
        end
      end

      # Obter tempo em formato configurado para região
      def parse_time
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        now = Time.now
        now = tz.to_local(now)
        now.strftime('%e/%b, %Hh%Mmin')
      end

      # Compilar texto de "output"
      def parse_output(req, patient, obs, now)
        out = []
        out.push "\x2a🛏 \x60ATUALIZAÇÃO - MÉDICOS DA PORTA\x60 🩺\x2a"
        out.push "\x2aMédico:\x2a #{req[:physician]}"
        out.push "\x2aPaciente:\x2a #{patient}"
        out.push "\x2aSolicitação:\x2a"
        out.push "- (#{req[:type] == 'repouso' ? 'x' : ' '}) Repouso no leito"
        out.push "- (#{req[:type] == 'ih' ? 'x' : ' '}) Internação"
        out.push "\x2aElegível para Transferência Externa:\x2a"
        out.push "- (#{req[:external] ? 'x' : ' '}) Sim#{req[:external] ? " (#{req[:external]})" : ' '}"
        out.push "- (#{req[:external] ? ' ' : 'x'}) Não"
        out.push "\x2aHipótese diagnóstica:\x2a #{req[:hd]}"
        out.push "\x2aPrioridade:\x2a"
        out.push "- (#{req[:priority] == 2 ? 'x' : ' '}) Urgente"
        out.push "- (#{req[:priority] == 1 ? 'x' : ' '}) Pode aguardar"
        out.push "- (#{req[:priority].zero? ? 'x' : ' '}) Não urgente"
        out.push "\x2aObservações:\x2a #{obs}"
        out.push "\x2aData e hora:\x2a #{now}"

        out.join("\n")
      end
    end
  end
end
