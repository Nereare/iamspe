# frozen_string_literal: true

require 'tty-prompt'

module Iamspe
  module Bossy
    # Classe de geração de anúncio de almoços
    class Lunch
      # Texto base do anúncio de almoços
      BASE_TXT = [
          "\x2a🍝 \x60Almoços\x60 🍨\x2a",
          '',
          "\x2a🩺 Porta\x2a",
          '{{ DOOR }}',
          "\x2a👀 Observação Térreo\x2a",
          '{{ OBS }}',
          '',
          "\x2aPlantonistas 12h:\x2a \x601h\x60 de almoço",
          "\x2aPlantonistas 6h:\x2a \x6015min\x60 de pausa"
      ].join("\n").freeze

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
        txt = BASE_TXT.dup
        txt.gsub!('{{ DOOR }}', door_list)
        txt.gsub!('{{ OBS }}', obs_list)
        txt
      end

      # Construir lista de almoços na porta
      def door_list
        txt = @prompt.multiline('Colar (Ctrl+V) as colunas B-F do controle de salas (incluindo linhas em branco):') do |q|
          q.help 'Use Ctrl+D quando terminar de colar'
        end
        txt.filter! do |elem|
          /(\d+|Rv)\t([A-Za-zÇçáéíóúãõôê ]+)\t(07-19+h)\t([0-9A-Za-z'-]+)\t(\d+h\d+)/.match?(elem)
        end
        txt.map! do |elem|
          person = elem.split("\t")
          "#{person[1].strip} (_sala #{person[0].strip}_), *#{person[4].strip}*"
        end
        txt.join("\n")
      end

      # Construir lista de almoços na observação
      def obs_list
        physicians = []
        loop do
          name = @prompt.ask('Nome do plantonista da Obs (deixe em branco para terminar):') do |q|
            q.modify :strip
          end
          break if name.nil?

          scheme = @prompt.select("Duração do plantão:") do |q|
            q.choice '12h', 12
            q.choice '6h', 6
          end
          physicians << { name: name, scheme: scheme }
        end
        names = physicians.map do |p|
          p[:name]
        end
        if physicians.length == 4
          # Se todo mundo de 6h
          last = names.pop
          "#{names.join(', ')}, e #{last} podem dividir os horários de lanche entre si conforme fluxo da Observação, sempre ficando pelo menos um plantonista presente."
        elsif physicians.length == 3
          "#{names[0]}, preferencialmente sair para almoçar após #{names[2]} render #{names[1]} às 13h."
        elsif physicians.length == 2
          "#{names[0]} e #{names[1]} podem dividir entre si conforme fluxo da Observação, sempre ficando pelo menos um plantonista presente."
        else
          'Se organizem conforme fluxo da Obs para seus horários de lanche, sempre ficando pelo menos um plantonista presente.'
        end
      end
    end
  end
end
