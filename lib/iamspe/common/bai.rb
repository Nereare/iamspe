# frozen_string_literal: true

require 'active_support'
require 'tty-prompt'
require 'tzinfo'

module Iamspe
  module Common
    # Classe de Altas Retroativas
    class Bai
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Obter quem abandonou a porra do prontuário
        physician, register = fucker
        # Enfatizar que não foi você que escreveu esse lixo?
        shat = shit? ? ', tampouco de redação de documentos correspondentes' : ''
        # Obter "agora"
        now = parse_time
        # Compilar texto de "output"
        @out = "# Em tempo #\nAssumo agora, às #{now}, ficha de atendimento aberta nas data e hora de registro deste documento por #{physician} (CRM #{register}), e abandonado sem liberação desde então.\nAssumo ficha de modo a não manter prontuário impedido de uso futuro por pendência puramente informática.\nEnfatizo que não participei de tal atendimento#{shat}, e que assumo prontuário apenas resolver pendência administrativa deste.\nSem mais."
      end

      # Converter em _String_, no caso sendo o texto de "output"
      def to_s
        @out
      end

      private

      # Obter tempo em formato configurado para região
      def parse_time
        tz = TZInfo::Timezone.get('America/Sao_Paulo')
        now = Time.now
        now = tz.to_local(now)
        now.strftime('%kh%M de %d/%m/%Y')
      end

      # Obter filho da égua que abandonou prontuário aberto
      def fucker
        name = @prompt.ask('Nome de quem abandonou prontuário:') do |q|
          q.required true
          q.modify   :up, :trim
        end
        crm = @prompt.ask('CRM da pessoa:') do |q|
          q.required true
          q.convert  :int
        end
        crm = ActiveSupport::NumberHelper.number_to_delimited(crm, delimiter: '.')
        [name, crm]
      end

      # Perguntar se você quer enfatizar não ter escrito o lixo de redação do prontuário abandonado
      def shit?
        @prompt.yes?('O prontuário está mal-escrito e você quer enfatizar que não é você que cagou no pau?') do |q|
          q.positive 'S'
          q.negative 'n'
        end
      end
    end
  end
end
