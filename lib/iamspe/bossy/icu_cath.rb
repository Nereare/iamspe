# frozen_string_literal: true

require 'tty-config'
require 'tty-prompt'

module Iamspe
  module Bossy
    # Classe de lista de solicitações de CATEs e UTIs
    class IcuCath
      # Inicializador
      def initialize
        # Inicializar TTY::Prompt
        @prompt = TTY::Prompt.new
        # Inicializar TTY::Config
        @config = TTY::Config.new
        @config.filename = '.iamspe'
        @config.append_path Dir.home
        raise new Error, 'Arquivo de configuração não encontrado' unless @config.exist?

        @config.read

        # Inicializar variáveis
        @patients = []
        @dt_beds = @config.fetch(:dt, :leitos)
        @eme_beds = @config.fetch(:eme, :leitos)
        @eme_ext = @config.fetch(:eme, :contingencia)
        # Compilar dados
        build_patients
        @icu = build_icu
        @cath = build_cath
        @occupation = count_eme
      end

      # Compilar texto de "output" e retorná-lo como _String_
      def to_s
        [
          '# CATE',
          '',
          @cath,
          '',
          '# UTI',
          '',
          @icu,
          '_Ocupação:_',
          @occupation,
          '',
          '*Obs.:* colegas dos setores já cobrados de solicitar UTI para *todo* paciente que não tiver previsão de alta para enfermaria nas próximas 24h.'
        ].join "\n"
      end

      private

      # Construir lista de pacientes um-a-um
      def build_patients
        loop do
          new_pt = parse_patient
          break if new_pt[:name].nil?

          @patients.push(new_pt)
          puts ''
        end
      end

      # Obter dados de cada paciente, individualmente
      def parse_patient
        @prompt.collect do
          key(:name).ask('Nome completo:') do |q|
            q.modify :trim, :up
          end
          next if @answers[:name].nil?

          key(:sector).select('Setor:') do |q|
            q.choice name: 'UCP', value: 'UCP'
            q.choice name: 'Semi', value: 'Semi'
            q.choice name: 'DT', disabled: 'Sem macas no momento'
            q.choice name: 'EME', value: 'EME'
          end
          key(:icu).yes?('UTI?') do |q|
            q.positive 'SIM'
            q.negative 'não'
          end
          key(:cath).yes?('CATE?') do |q|
            q.positive 'SIM'
            q.negative 'não'
          end
          next unless @answers[:cath]

          key(:cathwhen).select('Data definida de CATE?') do |q|
            q.choice(name: 'Não', value: '')
            q.choice(name: 'Hoje', value: ' (previsão para hoje)')
            q.choice(name: 'Amanhã', value: ' (previsão para amanhã)')
            q.choice(name: 'NA HEMO', value: ' (em procedimento no momento)')
          end
        end
      end

      # Obter número de pacientes fisicamente na EME
      def count_eme
        i = @prompt.ask('# Pacientes na EME:') do |q|
          q.required true
          q.convert  :int
        end

        if i < @eme_beds
          ["- #{i} pacientes", "- #{@eme_beds - i} leitos *vagos*"].join "\n"
        elsif i < @eme_ext
          ["- #{i} pacientes", "- #{@eme_ext - i} leitos extras *vagos*", '- Segundo salão da EME em uso'].join "\n"
        else
          ["- #{i} pacientes", '- *SEM* leitos vagos', '- Segundo salão da EME em uso'].join "\n"
        end
      end

      # Compilar listas de UTI
      def build_icu
        ucp = build_sector_patients('UCP', :icu)
        ucp = if ucp.empty?
                ['*UCP:*', '- Sem indicações']
              else
                ['*UCP:*'].concat(ucp)
              end
        semi = build_sector_patients('Semi', :icu)
        semi = if semi.empty?
                 ['*Semi:*', '- Sem indicações']
               else
                 ['*Semi:*'].concat(semi)
               end
        if @dt_beds
          dt = build_sector_patients('DT', :icu)
          dt = if dt.empty?
                 ['*DT:*', '- Sem indicações']
               else
                 ['*DT:*'].concat(dt)
               end
        else
          dt = []
        end
        eme = build_sector_patients('EME', :icu)
        eme = if eme.empty?
                ['*EME:*', '- Sem indicações']
              else
                ['*EME:*'].concat(eme)
              end

        [
          ucp.join("\n"),
          semi.join("\n"),
          dt.join("\n"),
          eme.join("\n")
        ].reject(&:empty?).join "\n"
      end

      # Compilar listas de CATE
      def build_cath
        ucp = build_sector_patients('UCP', :cath)
        ucp = if ucp.empty?
                ['*UCP:*', '- Sem indicações']
              else
                ['*UCP:*'].concat(ucp)
              end
        semi = build_sector_patients('Semi', :cath)
        semi = if semi.empty?
                 ['*Semi:*', '- Sem indicações']
               else
                 ['*Semi:*'].concat(semi)
               end
        if @dt_beds
          dt = build_sector_patients('DT', :cath)
          dt = if dt.empty?
                 ['*DT:*', '- Sem indicações']
               else
                 ['*DT:*'].concat(dt)
               end
        else
          dt = []
        end
        eme = build_sector_patients('EME', :cath)
        eme = if eme.empty?
                ['*EME:*', '- Sem indicações']
              else
                ['*EME:*'].concat(eme)
              end

        [
          ucp.join("\n"),
          semi.join("\n"),
          dt.join("\n"),
          eme.join("\n")
        ].reject(&:empty?).join "\n"
      end

      # Formatar lista de pacientes por setor e tipo
      def build_sector_patients(sector, type)
        sector = @patients.map do |pt|
          "- #{pt[:name]}" if pt[:sector] == sector && pt[type]
        end
        sector.compact
      end
    end
  end
end
