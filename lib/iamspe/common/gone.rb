# frozen_string_literal: true

require 'tty-prompt'
require 'tzinfo'

module Iamspe
  module Common
    # Classe de textos de Evasão
    class Bai
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Compilar texto de "output"
        @out = "# Em tempo #\nPaciente acima, #{stuff}."
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
        back.puts(last_eval ? last_eval_desc : nil)
        # Exames
        back.puts(missing_labs ? missing_labs_desc : nil)
        # Busca ativa
        back.puts(search ? 'solicito auxílio da equipe de Apoio Médico para Busca Ativa de paciente nas dependências do PS sem sucesso na localização' : nil)
        # Compilar tudo
        back.compact.join(', ')
      end

      # Questionar se a evasão é retroativa
      def last_eval
        @prompt.no?('Evasão retroativa?') do |q|
          q.positive 'sim'
          q.negativa 'NÃO'
        end
      end

      # Obter informações do último atendimento
      def last_eval_desc
        date = @prompt.ask('Que dia foi a última avaliação?') do |q|
          q.required true
          q.convert  :date
        end
        time = @prompt.ask('Que horas?') do |q|
          q.required true
          q.convert  :time
        end
        "com último atendimento em #{parse_time(date, :date)} às #{parse_time(time, :time)} e sem novas reavaliações desde então"
      end

      # Questionar se exames laboratoriais pendentes
      def missing_labs
        @prompt.no?('Houve solicitação de exames?') do |q|
          q.positive 'sim'
          q.negativa 'NÃO'
        end
      end

      # Obter informações sobre exames pendentes
      def missing_labs_desc
        done = @prompt.no?('Tais exames foram colhidos?') do |q|
          q.positive 'sim'
          q.negativa 'NÃO'
        end
        if done
          'houve solicitação de exames no último atendimento, sendo que paciente não colheu nenhum destes'
        else
          ' houve solicitação de exames no último atendimento, com coleta realizada após'
        end
      end

      # Questionar se houve busca ativa
      def search
        @prompt.yes?('Foi feita Busca Ativa do paciente?') do |q|
          q.positive 'SIM'
          q.negativa 'não'
        end
      end

      # Obter tempo em formato configurado para região
      def parse_time(time, format)
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        time = Time.parse time
        time = tz.to_local(time)
        format = format == :date ? "%d\/%m\/%Y" : '%kh%M'
        time.strftime(format)
      end
    end
  end
end
