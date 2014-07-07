require 'rubygems' rescue nil
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
require 'texplay'

include Gosu
include Chingu

require_relative 'player'
require_relative 'projectile'
require_relative 'scenery'

module ZOrder
	BACKGROUND = -1
	CLOUD = 0
	PLATFORM = 1
	PLAYER = 2
	PROJECTILE = 3
end

module Controls
	#The controls must be defined in the order: down jump right left fire water air.
	#This is because they are referred to in the Player class using that order.
	@@player1 = {
		s:	:look_down,
		w:	:jump,
		d: 	:move_right,
		a: 	:move_left,
		
		r: :grow_fire,
		t: :grow_water,
		y: :grow_air,
	}

	@@player2 = {
		down: 	:look_down,
		up: 	:jump,
		right: 	:move_right,
		left:  	:move_left,
		
		numpad_1: :grow_fire,
		numpad_2: :grow_water,
		numpad_3: :grow_air,
	}

	def self.player1; @@player1 end
	def self.player2; @@player2 end
end

class Game < Chingu::Window 
  def initialize
    super(1280, 800)    
    push_game_state(Play)
  end
end

class Play < GameState
	def initialize
		super
		# - half the image height
		$ground_y = $window.height - 6 * 32 - 4

		Player.create(x: 100, y: $ground_y, controls: Controls.player1, name: "player1" )
		Player.create(x: 1180, y: $ground_y, controls: Controls.player2, name: "player2" )

		Platform.create(x: 200, y: $ground_y - 150)
		Platform.create(x: 640, y: $ground_y - 300)
		Platform.create(x: 1080, y: $ground_y - 150)

		@bridge_and_sky = Image["images/bridge_and_sky.png"]
	end

	def update
		super
		$window.caption = Player.all.first.velocity_y
		spawn_scenery_objects
    	game_objects.destroy_if { |object| object.alpha == 0 }
	end

	def draw
		super
		@bridge_and_sky.draw 0, 0, ZOrder::BACKGROUND
	end

	def spawn_scenery_objects
		@smoke_particle = Image["images/smoke_particle.bmp"]

		if rand(400) == 1
			#To prevent half a cloud suddenly appearing on the screen clouds are initiated with negative x.
			#Longest cloud is 5 tiles, 5*32 = 160
			cloud = Cloud.create(x: -160, y: 250 * rand)
		end

		#Spawns smoke from the house in the background image
		if rand(5) == 1
			@smoke ||= []
			@smoke << Chingu::Particle.create( :x => 720, 
				                          :y => 413, 
				                          :image => @smoke_particle,
				                          :fade_rate => -2, 
				                          :mode => :default
				                        )
		end

		if @smoke
			@smoke.each { |particle| particle.y -= 3; particle.x += rand }
		end
	end
end

Game.new.show