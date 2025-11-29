# frozen_string_literal: true

require 'tty-prompt'

# TODO: Meio que a porra toda...
module Iamspe
  module Bossy
    # Classe de geração de anúncio de almoços
    class Lunch
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Compilar texto de "output"
        @out = build_lunchs
      end

      # Converter em _String_, no caso sendo o texto de "output"
      def to_s
        @out
      end

      private

      # Construir lista de almoços
      def build_lunchs
        txt = @prompt.multiline('Colar (Ctrl+V) as colunas B-F do controle de salas (incluindo linhas em branco):') do |q|
          q.help 'Use Ctrl+D quando terminar de colar'
        end
        txt.filter! do |_elem|
          elem ~ /(\d+|Rv)\t([A-zÇçáéíóúãõôê ]+)\t(07-19+h)\t([0-9A-z'-]+)\t(\d+h\d+)/
        end
        puts txt.join "\n"
      end
    end
  end
end
