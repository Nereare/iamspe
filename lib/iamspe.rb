# frozen_string_literal: true

require 'pastel'
require 'tty-exit'
require 'tty-option'

require_relative 'iamspe/bossy'
require_relative 'iamspe/meta'

# Módulo principal da gema
module Iamspe
  # Módulo para iniciar a interface de linha de comando
  class Starter
    include TTY::Exit
    include TTY::Option

    argument :command do
      name    'command(string)'
      arity   1
      default :bossy
      permit  %i[bossy front]
      convert ->(val) { val.to_s == 'chefia' ? :bossy : :front }
      desc    'O tipo de funções a serem executadas'
    end

    # Define command line version flag
    flag :version do
      short '-v'
      long '--version'
      desc 'Show the version of the current installation'
    end

    # Define command line license flag
    flag :license do
      short '-l'
      long '--license'
      desc 'Show license information'
    end

    # Define command line help flag
    flag :help do
      short '-h'
      long '--help'
      desc 'Print help text'
    end

    # Set help text headers and footer
    usage do
      pastel = Pastel.new
      program pastel.blue(RepoTemplater::SLUG).to_s
      no_command
      header pastel.cyan(RepoTemplater::NAME).to_s
      header RepoTemplater::DESCRIPTION.to_s
      footer "Available under the #{pastel.green(RepoTemplater::LICENSE)} by #{pastel.blue(RepoTemplater::AUTHOR)}."
    end

    # Compile TTY::Option parameters into a single value
    def compiled_params
      p = false
      p = 'info' if params[:info]
      p = 'version' if params[:version]
      p = 'license' if params[:license]
      p = 'help' if params[:help]
      p
    end

    # Compile actions based on compiled parameters
    def run_actions
      case compiled_params
      when 'info' then RepoTemplater::Actions.info
      when 'version' then puts RepoTemplater::VERSION
      when 'license' then puts RepoTemplater::LICENSE
      when 'help' then puts help
      else
        act = RepoTemplater::Actions.new
        act.run
      end
    end

    # Run the command line interface
    def run
      if params.errors.any?
        exit_with(:usage_error, params.errors.summary)
      else
        run_actions
      end
    end
  end
end
