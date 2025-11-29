# frozen_string_literal: true

require 'active_support'
require 'tty-config'
require 'tty-prompt'

module Iamspe
  # Classe de inicialização de configurações, caso não configuradas
  class Setup
    # Lista de Unidades Federativas do Brasil e suas siglas
    ESTADOS = [
      { name: 'Acre', value: 'AC' },
      { name: 'Alagoas', value: 'AL' },
      { name: 'Amapá', value: 'AP' },
      { name: 'Amazonas', value: 'AM' },
      { name: 'Bahia', value: 'BA' },
      { name: 'Ceará', value: 'CE' },
      { name: 'Distrito Federal', value: 'DF' },
      { name: 'Espírito Santo', value: 'ES' },
      { name: 'Goiás', value: 'GO' },
      { name: 'Maranhão', value: 'MA' },
      { name: 'Mato Grosso', value: 'MT' },
      { name: 'Mato Grosso do Sul', value: 'MS' },
      { name: 'Minas Gerais', value: 'MG' },
      { name: 'Pará', value: 'PA' },
      { name: 'Paraíba', value: 'PB' },
      { name: 'Paraná', value: 'PR' },
      { name: 'Pernambuco', value: 'PE' },
      { name: 'Piauí', value: 'PI' },
      { name: 'Rio de Janeiro', value: 'RJ' },
      { name: 'Rio Grande do Norte', value: 'RN' },
      { name: 'Rio Grande do Sul', value: 'RS' },
      { name: 'Rondônia', value: 'RO' },
      { name: 'Roraima', value: 'RR' },
      { name: 'Santa Catarina', value: 'SC' },
      { name: 'São Paulo', value: 'SP' },
      { name: 'Sergipe', value: 'SE' },
      { name: 'Tocantins', value: 'TO' }
    ].freeze

    # Iniciar classe
    def initialize
      # Inicializar TTY::Prompt
      @prompt = TTY::Prompt.new
      # Inicializar TTY::Config
      @config = TTY::Config.new
      @config.filename = '.iamspe'
      @config.append_path Dir.home
      @config.read if @config.exist?
      # Checar completude da configuração
      check_fullness
      # Compilar configuração
      @config.write(force: true)
    end

    private

    # Métodos de checagem de completude de dados
    def check_fullness
      check_name
      check_register_number
      check_register_state
      intensive_sectors
      db_name
    end

    # Submétodo de checagem de setores críticos
    def intensive_sectors
      check_eme_beds
      check_eme_beds_ext
      check_dt_beds
    end

    # Checar nome completo
    def check_name
      return unless @config.fetch(:nome, default: nil).nil?

      name = @prompt.ask('Qual seu nome completo?') do |q|
        q.required true
        q.modify   :capitalize, :strip
      end
      @config.set(:nome, value: name)
    end

    # Checar número de registro profissional
    def check_register_number
      return unless @config.fetch(:crm, :numero, default: nil).nil?

      crm = @prompt.ask('Qual o número do seu CRM?') do |q|
        q.required true
        q.convert  :int
      end
      crm = ActiveSupport::NumberHelper.number_to_delimited(crm, delimiter: '.')
      @config.set(:crm, :numero, value: crm)
    end

    # Checar UF de registro profissional
    def check_register_state
      return unless @config.fetch(:crm, :uf, default: nil).nil?

      crm = @prompt.select('Qual a Unidade Federativa do seu CRM?') do |q|
        q.choices ESTADOS
        q.default 'São Paulo'
      end
      @config.set(:crm, :uf, value: crm)
    end

    # Checar número de leitos na EME
    def check_eme_beds
      return unless @config.fetch(:eme, :leitos, default: nil).nil?

      eme = @prompt.ask('Qual o número do leitos HABITUAL na EME?') do |q|
        q.required true
        q.convert  :int
      end
      @config.set(:eme, :leitos, value: eme)
    end

    # Checar número de leitos na EME em CONTINGÊNCIA
    def check_eme_beds_ext
      return unless @config.fetch(:eme, :contingencia, default: nil).nil?

      eme = @prompt.ask('Qual o número do leitos COM CONTINGÊNCIA na EME?') do |q|
        q.required true
        q.convert  :int
      end
      @config.set(:eme, :contingencia, value: eme)
    end

    # Checar número de leitos na DT
    def check_dt_beds
      return unless @config.fetch(:dt, :leitos, default: nil).nil?

      dt = @prompt.ask('Qual o número do leitos na DT?') do |q|
        q.required true
        q.convert  :int
      end
      @config.set(:dt, :leitos, value: dt)
    end

    # Checar nome e local do arquivo de banco de dados
    def db_name
      return unless @config.fetch(:db, default: nil).nil?

      @config.set(:db, value: "#{Dir.home}/.iamspe.db")
    end
  end
end
