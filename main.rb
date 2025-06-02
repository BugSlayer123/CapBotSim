# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'forwardable'
require 'json'
require 'thor'
require 'ruby2d'
require 'zeitwerk'
require 'singleton'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib")
loader.setup

class CapBotCLI < Thor
  include ::Util

  class_option :width, type: :numeric, aliases: '-w'
  class_option :height, type: :numeric, aliases: '-h'

  desc 'start', 'Start the Capbot simulation'
  method_option :configuration, required: true, type: :string
  method_option :map, required: true, type: :string
  method_option :headless, required: false, type: :boolean, default: false
  method_option :no_log, required: false, type: :boolean, default: false

  def start
    simulation = Simulation::CapBotSimulation.new(
      options[:configuration],
      options[:map],
      headless: options[:headless],
      width: options[:width],
      height: options[:height],
      no_log: options[:no_log],
    )
    simulation.start
  end

  desc 'experiment', 'Run a simulation experiment'
  method_option :configuration, required: true, type: :string
  method_option :map, required: true, type: :string
  method_option :iterations, required: true, type: :numeric
  method_option :stop_conditions, required: false, type: :hash
  method_option :tweak, required: false, type: :hash
  method_option :log, required: false, type: :boolean
  method_option :kill_chance, required: false, type: :numeric, default: 0.0
  method_option :tps, required: false, type: :numeric

  def experiment
    experimenter = Experiment::Experimenter.new(
      options[:configuration],
      options[:map],
      iterations: options[:iterations],
      stop_conditions: (options[:stop_conditions] || {}).transform_keys(&:to_sym).transform_values(&:to_i),
      tweak_constants: (options[:tweak] || {}).transform_keys { |key| key.gsub(';', ':') }.transform_values do |value|
        distribution = value.include?('[')
        split = value.split('~').map { |s| s.gsub('[', '').gsub(']', '') }
        {
          min: split[0].to_f,
          max: split[1].to_f,
          distribution: distribution,
        }
      end,
      log: options[:log],
      kill_chance: options[:kill_chance],
      tps: options[:tps],
    )
    experimenter.start
  end

  desc 'replay', 'Replay a simulation from a CSV file'
  method_option :log_file, required: true, type: :string

  def replay
    replayer = Replay::Replayer.new(options[:log_file], options[:bot_ids]&.map(&:to_i))
    replayer.start
  end

  no_commands do
    def self.exit_on_failure?
      false
    end
  end
end

CapBotCLI.start(ARGV)
