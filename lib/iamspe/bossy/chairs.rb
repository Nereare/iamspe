# frozen_string_literal: true

require 'active_support'
require 'tty-prompt'
require 'tzinfo'

module Iamspe
  module Bossy
    # Classe de aguardo de repouso no leito
    class Chairs
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Coletar pacientes e interpretar dados
        interpret_patients
        # Compilar texto de "output"
        @out = start_out
        @out.gsub!('LIST', parse_patients)
      end

      # Converter em _String_, no caso sendo o texto de "output"
      def to_s
        @out
      end

      private

      # Coletar pacientes e interpretar dados
      def interpret_patients
        @patients = @prompt.multiline('Colar abaixo Ctrl+C do Censo, colunas D-M, sem linhas em branco ou de título:') do |q|
          q.help 'Use Ctrl+D para finalizar.'
        end
        @patients = @patients.map do |patient|
          patient = I18n.transliterate(patient.strip)
          patient = patient.split("\t")
          age, dx, prior = parse_pt_data(patient)
          # - `$2`, *Tit.:* $5, *HD:* $10, *Prior.:* $1;
          "- `#{patient[1].strip}`#{age}, *Tit.:* #{patient[4]}, *HD:* #{dx}, *Prior.:* #{prior}"
        end
      end

      # Processar campos comumente não preenchidos e traduzir prioridade
      def parse_pt_data(patient)
        age = patient[2].empty? ? '' : " #{patient[2]}a"
        dx = patient[9].nil? ? '?' : patient[9].strip
        prior = case patient[0]
                when 'A'
                  'Alta'
                when 'B'
                  'Alta'
                when 'C'
                  'Média'
                when 'D'
                  'Baixa'
                else
                  'Média'
                end
        [age, dx, prior]
      end

      # Pré-compilar texto de "output"
      def start_out
        out = "\x2a⏳ \x60ATUALIZAÇÃO - CHEFIA DE PLANTÃO\x60 🛏\x2a\n"
        out += "\x2aPlantão:\x2a TODAY - Igor Padoim\n"
        out += "\x2aSituação atual:\x2a\nLIST"
        out.gsub('TODAY', parse_time)
      end

      # Finalizar formatação da lista de pacientes
      def parse_patients
        if @patients.length.positive?
          "#{@patients.join(";\n")}."
        else
          '- Sem pacientes aguardando.'
        end
      end

      # Obter tempo em formato configurado para região
      def parse_time
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        now = Time.now
        now = tz.to_local(now)
        now.strftime('%e/%b')
      end
    end
  end
end
