# frozen_string_literal: true

require 'pastel'
require 'tty-exit'
require 'tty-option'

require_relative 'iamspe/bossy'
require_relative 'iamspe/meta'
require_relative 'iamspe/setup'

# Módulo principal da gema
module Iamspe
  # Módulo para iniciar a interface de linha de comando
  class Starter
    include TTY::Exit
    include TTY::Option

    # Argumento de comando (chefia ou porta)
    argument :comando do
      name    'comando (chefia ou porta)'
      arity   :*
      permit  %w[chefia porta]
      desc    'Qual o setor cujas funções devem ser iniciadas'
    end

    # Definir bandeira de versão
    flag :versao do
      short '-v'
      long '--versao'
      desc 'Mostrar qual a versão atual (segundo SemVer)'
    end

    # Definir bandeira de licença
    flag :licenca do
      short '-l'
      long '--licenca'
      desc 'Mostrar qual o nome da licença de uso'
    end

    # Definir bandeira de ajuda
    flag :ajuda do
      short '-h'
      long '--ajuda'
      desc 'Mostrar esta tela de ajuda'
    end

    # Definir texto personalizado de ajuda
    usage do
      pastel = Pastel.new
      program pastel.blue('chefia|porta').to_s
      no_command
      header pastel.cyan(Iamspe::NAME).to_s
      header Iamspe::DESCRIPTION.to_s
      footer "Disponível sob a licença #{pastel.green(Iamspe::LICENSE)}, feito com ranço por #{pastel.blue(Iamspe::AUTHOR)}."
    end

    # Compilar parâmetros de TTY::Option em um único termo
    def compiled_params
      p = params[:comando]
      p = 'versao' if params[:versao]
      p = 'licenca' if params[:licenca]
      p = 'ajuda' if params[:ajuda]
      p
    end

    # Compilar ações conforme os parâmetros compilados
    def run_actions
      case compiled_params
      when 'versao' then puts Iamspe::VERSION
      when 'licenca' then puts Iamspe::LICENSE
      when 'ajuda' then puts help
      when 'porta' then Iamspe::Door::Starter.new
      else
        Iamspe::Bossy::Starter.new
      end
    end

    # Executar o aplicativo conforme os parâmetros fornecidos
    def run
      if params.errors.any?
        exit_with(:usage_error, params.errors.summary)
      else
        Iamspe::Setup.new
        run_actions
      end
    end
  end
end
