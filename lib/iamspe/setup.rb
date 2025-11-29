# frozen_string_literal: true

require 'tty-config'
require 'tty-prompt'

module Iamspe
  # Classe de inicialização de configurações, caso não configuradas
  class Setup
    # Iniciar classe
    def initialize
      # Inicializar TTY::Prompt
      @prompt = TTY::Prompt.new
      # Inicializar TTY::Config
      @config = TTY::Config.new
      @config.filename = ".iamspe"
      @config.append_path ENV['HOME']
      # Checar completude da configuração
      check_fullness
      # Compilar configuração
      @config.write
    end

    private

    def check_fullness
      check_name
    end

    def check_name
      if @config.fetch(:nome, default: nil).nil?
        name = @prompt.ask('Qual seu nome completo?') do |q|
          q.required true
          q.modify   :capitalize, :strip
        end
        @config.set(:nome, name)
      end
    end
  end
end
