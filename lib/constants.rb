# frozen_string_literal: true

module Constants
  module Simulation
    TICKS_PER_SECOND = 60 * 1
    TICKS_PER_LOG = TICKS_PER_SECOND / 30
    BOT_SELECT_RADIUS = 20

    DISPLAY_ID = true
    SHOW_LOGS = false
    DEBUG = true

    PERSONAL_BEST_PATH_LAYER = -2
    GLOBAL_BEST_PATH_LAYER = -3
    BEST_PATH_LAYER = -1

    PERSONAL_BEST_COLOR = 'blue'
    GLOBAL_BEST_COLOR = 'red'
    BEST_COLOR = 'black'
  end

  module Bot
    PUSH_BACK = 2
    SIZE = 3 # px

    # bot is 3px x 3px -> 1px = 20/3 cm
    # in km/h -> m/s -> px/s
    CM_PER_PX = 20 / 3
    # Speeds in km/h
    MAX_SPEED_KMH = 0.73
    MIN_SPEED_KMH = 0.18
    # Convert to cm/s
    MAX_SPEED_CMS = MAX_SPEED_KMH * 100 / 3.6
    MIN_SPEED_CMS = MIN_SPEED_KMH * 100 / 3.6
    # Convert to px/s, divide by 60 to get px/tick (60 ticks per second)
    MAX_SPEED = MAX_SPEED_CMS / CM_PER_PX / 60 # ≈ 3.04 px/s
    MIN_SPEED = MIN_SPEED_CMS / CM_PER_PX / 60# ≈ 0.75 px/s

    ACCELERATION = MAX_SPEED / (0.5 * Simulation::TICKS_PER_SECOND)

    MAX_POWER_USAGE = (0.542 * MAX_SPEED) + 0.243
    CURRENT_POWER_USAGE = lambda do |velocity, is_accelerating|
      return MAX_POWER_USAGE if is_accelerating

      velocity_magnitude = velocity.magnitude
      ((0.542 * velocity_magnitude) + 0.243)
    end
    ENERGY_STEEPNESS = 20.0
    # in Joules
    MAX_ENERGY_LEVEL = 1080
    MIN_ENERGY_LEVEL = 72

    # 0 if low energy, 1 if high energy
    ENERGY_FACTOR = lambda do |energy|
      x = 1 - (energy / MAX_ENERGY_LEVEL)
      1 / (1 + Math.exp(-ENERGY_STEEPNESS * (x - 0.5)))
    end

    CHARGE_DURATION = 16
    TROPHALLAXIS_DURATION = 16
    DATA_TRANSFER_DURATION = 6
    COLLISION_COOLDOWN = (CHARGE_DURATION * 60) + (TROPHALLAXIS_DURATION * 60) + (DATA_TRANSFER_DURATION * 60) # ticks
  end

  module Kdtree
    MAX_NODE_WIDTH = 12 # 6 is only for robot ids < 99. node width should be 12 when robot ids go higher than 99
  end

  module Capabilities
    VOLTAGE = 3.3

    # https://cdn-shop.adafruit.com/datasheets/HMC5883L_3-Axis_Digital_Compass_IC.pdf
    module Compass
      CURRENT = 100 * 1e-6
      POWER = CURRENT * VOLTAGE
      ENERGY_CONSUMPTION = POWER * (1.0 / Simulation::TICKS_PER_SECOND) # J per tick

      IDLE_CURRENT = 2 * 1e-6
      IDLE_POWER = IDLE_CURRENT * VOLTAGE
    end

    # https://ams-osram.com/products/sensor-solutions/position-sensors/ams-as5048a-high-resolution-position-sensor
    module WheelEncoder
      CURRENT = 15 * 1e-3
      POWER = CURRENT * VOLTAGE
    end
  end

  module Strategy
    module BiasedStroll
      ADJUST_COUNTDOWN = 2
      ADJUST_DELTA_ROTATION = 10
    end

    module Pso
      WAYPOINT_THRESHOLD = 3 # length of bot
      SLOW_DOWN_RANGE = 30
      REFRESH_RATE = 1 # s

      module PotentialFields
        D_STAR = 50
        ATTRACTIVE_FORCE_WEIGHT = [2.5, 3.0].freeze # tune [1, 8?]

        REPULSIVE_FORCE_WEIGHT = [3.5, 4.0].freeze # tune [-8?, -1]
        REPULSIVE_FORCE_EXP = [1.0, 1.7].freeze # tune [0.1, 3]
        REPULSIVE_FORCE_RADIUS = 50 # tune
        OBSTACLE_CLUSTER_RADIUS = 5

        SOCIAL_FORCE_WEIGHT = [1.0, 3.0].freeze # tune [-4, 4?]
        SOCIAL_FORCE_EXP = [1.0, 2.0].freeze # tune [0.1, 3]
        SOCIAL_FORCE_RADIUS = 400 # tune
        SOCIAL_ENERGY_FACTOR = 2

        ADJUST_PROBABILITY = 1 # tune [0.2, 1]

        ADJUST_THRESHOLD = 0 # degrees

        # tuning
        MAX_ATTRACTIVE = lambda do |weight|
          weight.abs * Math.log(1900) # 1900 is max width
        end
        MAX_REPULSIVE = lambda do |weight|
          weight.abs * (1.0 / (Bot::SIZE**2)) # 20 here is minimum obstacle dist (robot radius)
        end
        MAX_SOCIAL = lambda do |weight|
          weight.abs * (1.0 / (Bot::SIZE**2)) # 20 here is minimum obstacle dist (robot radius)
        end

        MAX_FORCE = lambda do |max_attr, max_rep, max_soc|
          [max_attr, max_rep, max_soc].max
        end
        FORCE_NORMALIZATION = lambda do |max_force|
          max_force * 1.2
        end

        REPULSION_BASE = lambda do |max_force, rep_exp|
          max_force * (Bot::SIZE**rep_exp)
        end
        SOCIAL_BASE = lambda do |max_force, soc_exp|
          max_force * (2**soc_exp)
        end
      end

      # [0, 100]
      module Weights
        DISTANCE = 60
        LENGTH = 30
        COLLISIONS = 10
      end

      module Exploration
        RECOLLECTION_PROBABILITY = 1.8 # no tune

        BOT_COLLISION_TIME_TO_LIVE = 200 # s # tune [60, 600]
      end

      module Recollection
        ATTRACTIVE_FORCE_SCALE = PotentialFields::ATTRACTIVE_FORCE_WEIGHT.max * 3
        COLLISION_COOLDOWN = 7 # seconds

        EXPLORATION_PROBABILITY = 0.8
        RECOLLECTION_PROBABILITY = 0.8

        SKIP_PROBABILITY = 0 # tune [0, 1] A <=> B
        MAX_SKIP_PERCENTAGE = 0 # % tune [0, 100] A <=> B
      end
    end
  end
end
