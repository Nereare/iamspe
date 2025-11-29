# frozen_string_literal: true

require 'tty-prompt'

require_relative 'door/reeval'
require_relative 'door/rest'
require_relative 'common'

module Iamspe
  # Submódulo para funcionalidades relacionadas à Porta
  module Door
    # Classe de inicialização de funções da Porta
    class Starter
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Decidir qual módulo acionar e acioná-lo
        @out = case decide_method
               when 'rest' then Iamspe::Door::Rest.new
               when 'bai' then Iamspe::Common::Bai.new
               when 'gone' then Iamspe::Common::Gone.new
               else # Reavaliação
                 full << Iamspe::Door::Reeval.new
               end
        # Exibir o resultado
        puts @out
      end

      private

      # Decidir qual método acionar com base na escolha do usuário e retornar símbolo correspondente
      def decide_method
        @prompt.select('O que iremos gerar?') do |q|
          q.choice(name: 'Repouso no leito', value: 'rest')
          q.choice(name: 'Alta Retroativa', value: 'bai')
          q.choice(name: 'Evasão', value: 'gone')
          q.choice(name: 'Reavaliação', value: 'reeval')
        end
      end
    end
  end
end
