# frozen_string_literal: true

require 'rspec'
require_relative '../lib/constants'
require_relative '../lib/simulation/object/bot/path/path'

# module Simulation
#   module Object
#     module Bot
#       module Path
#         RSpec.describe Path do
#           let(:path1) do
#             Path.new(
#               segments: [
#                 { x: 0, y: 0 },
#                 { x: 1, y: 1 },
#                 { x: 3, y: 3 },
#               ],
#               found_stations: [1],
#               found_target_stations: [2],
#             )
#           end
#
#           let(:path2) do
#             Path.new(
#               segments: [
#                 { x: 0, y: 0 },
#                 { x: 3, y: 3 },
#               ],
#               found_stations: [],
#               found_target_stations: [2],
#             )
#           end
#
#           it 'returns -1 when the first path has fewer found target stations' do
#             weaker_path = Path.new(found_target_stations: [])
#             stronger_path = Path.new(found_target_stations: [1])
#             expect(weaker_path.compare(stronger_path)).to eq(-1)
#           end
#
#           it 'compares paths based on weight when station counts are equal' do
#             expect(path1.compare(path2)).to eq(1)
#             expect(path2.compare(path1)).to eq(-1)
#           end
#         end
#       end
#     end
#   end
# end
