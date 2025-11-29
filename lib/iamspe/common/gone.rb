# frozen_string_literal: true

require 'tty-prompt'
require 'tzinfo'

module Iamspe
  module Common
    # Classe de textos de Evasão
    class Gone
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Compilar texto de "output"
        @out = "# Em tempo #\nPaciente acima, #{stuff}.\nEvasão?"
      end

      # Converter em _String_, no caso sendo o texto de "output"
      def to_s
        @out
      end

      private

      # Agregar dados relevantes de evasão e sobre último atendimento
      def stuff
        back = []
        # Último atendimento
        back << last_eval
        # Exames
        back << missing_labs
        # Busca ativa
        back << active_search
        # Compilar tudo
        back.compact.join(', ')
      end

      # Questionar se a evasão é retroativa
      def last_eval
        foo = @prompt.no?('Evasão retroativa?') do |q|
          q.positive 's'
          q.negative 'N'
        end
        '' unless foo

        date = @prompt.ask('Que dia foi a última avaliação?') do |q|
          q.required true
        end
        time = @prompt.ask('Que horas?') do |q|
          q.required true
        end
        "com último atendimento em #{parse_time(date,
                                                :date)} às #{parse_time(time,
                                                                        :time)} e sem novas reavaliações desde então"
      end

      # Questionar se exames laboratoriais pendentes
      def missing_labs
        foo = @prompt.no?('Houve solicitação de exames?') do |q|
          q.positive 's'
          q.negative 'N'
        end
        '' unless foo

        done = @prompt.no?('Tais exames foram colhidos?') do |q|
          q.positive 's'
          q.negative 'N'
        end
        if done
          'para o qual houve solicitação de exames no último atendimento, sendo que paciente não colheu nenhum destes'
        else
          'para o qual houve solicitação de exames no último atendimento, com coleta já realizada'
        end
      end

      # Questionar se houve busca ativa
      def active_search
        foo = @prompt.yes?('Foi feita Busca Ativa do paciente?') do |q|
          q.positive 'S'
          q.negative 'n'
        end
        "não é localizado na unidade" unless foo

        "e para o qual solicito auxílio da equipe de Apoio Médico para Busca Ativa de paciente nas dependências do PS, não é encontrado na unidade"
      end

      # Obter tempo em formato configurado para região
      def parse_time(time, format)
        time = Time.parse time
        format = format == :date ? '%d/%m/%Y' : '%kh%M'
        time.strftime(format)
      end
    end
  end
end
