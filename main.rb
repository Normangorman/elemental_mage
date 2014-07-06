require 'rubygems' rescue nil
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
include Gosu
include Chingu

require_relative 'player'
require_relative 'projectile'

class Game < Chingu::Window 
  def initialize
    super(1120, 800)    
    push_game_state(Play)
  end
end

class Play < GameState
	def initialize
		super
		# - half the image height
		$ground_y = $window.height - 3 * 29
		Player.create(x: 100, y: $ground_y)
		

		@background_image = Image["background/background_image.png"]
	end

	def update
		super
		$window.caption = game_objects.size
    	game_objects.destroy_if { |object| object.outside_window? || object.alpha == 0}
	end

	def draw
		super
		@background_image.draw 0, 0, 0
	end
end




Game.new.show