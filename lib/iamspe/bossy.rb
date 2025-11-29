# frozen_string_literal: true

require 'tty-prompt'

require_relative 'bossy/chairs'
require_relative 'bossy/icu_cath'
require_relative 'bossy/lunch'
require_relative 'common'

module Iamspe
  # Submódulo para funcionalidades relacionadas à Chefia de Plantão
  module Bossy
    # Classe de inicialização de funções da Chefia de Plantão
    class Starter
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Decidir qual módulo acionar e acioná-lo
        @out = case decide_method
               when 'chairs' then Iamspe::Bossy::Chairs.new
               when 'bai' then Iamspe::Common::Bai.new
               when 'gone' then Iamspe::Common::Gone.new
               when 'icu-cath' then Iamspe::Bossy::IcuCath.new
               when 'lunch' then Iamspe::Bossy::Lunch.new
               else # Início de Plantão
                 full = []
                 full << Iamspe::Bossy::Chairs.new
                 full << Iamspe::Bossy::IcuCath.new
                 full << Iamspe::Bossy::Lunch.new
                 full.join("\n---\n")
               end
        # Exibir o resultado
        puts @out
      end

      private

      # Decidir qual método acionar com base na escolha do usuário e retornar símbolo correspondente
      def decide_method
        @prompt.select('O que iremos gerar?') do |q|
          q.choice(name: 'Início de plantão', disabled: '(WIP)', value: :start)
          q.choice(name: 'Repouso no leito', value: :chairs)
          q.choice(name: 'Setores Críticos', value: :icu_cath)
          q.choice(name: 'Alta Retroativa', value: :bai)
          q.choice(name: 'Evasão', value: :gone)
          q.choice(name: 'Almoços', disabled: '(WIP)', value: :lunch)
        end
      end
    end
  end
end
