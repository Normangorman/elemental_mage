require 'rubygems' rescue nil
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
require 'texplay'

include Gosu
include Chingu

require_relative 'ui'
require_relative 'player'
require_relative 'projectile'
require_relative 'scenery'


module ZOrder
	BACKGROUND = 0
	SMOKE = 1
	CLOUD = 2
	PLATFORM = 3
	PLAYER = 4
	PROJECTILE = 5
	UI = 6
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

module Settings
	@@effect_volume = 0.5
	@@music_volume = 1

	def self.effect_volume; @@effect_volume end
	def self.music_volume; @@music_volume end
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

		#Name parameter must match the file name in which the player's animations are stored.
		Player.create(x: 100, y: $ground_y, controls: Controls.player1, name: "player1" )
		Player.create(x: 1180, y: $ground_y, controls: Controls.player2, name: "player2" )

		Platform.create(x: 200, y: $ground_y - 150)
		Platform.create(x: 640, y: $ground_y - 300)
		Platform.create(x: 1080, y: $ground_y - 150)

		@bridge_and_sky = Image["images/bridge_and_sky.png"]
		@smoke_particle = Image["images/smoke_particle.bmp"]

		@background_music = Gosu::Song.new($window, "media/sounds/wizards_keep.ogg")
		@background_music.play(looping = true)
		@background_music.volume = Settings.music_volume
	end

	def update
		super
		$window.caption = game_objects.size
		spawn_scenery_objects
    	game_objects.destroy_if { |object| object.alpha == 0 }
	end

	def draw
		super
		@bridge_and_sky.draw 0, 0, ZOrder::BACKGROUND
	end

	def spawn_scenery_objects
		#Total number of clouds on screen at one time is limited to 5.
		if rand(400) == 1 and Cloud.size <= 5
			Cloud.create
		end

		#Spawns smoke from the house in the background image
		if rand(100) == 1
			@smoke ||= []
			@smoke << Chingu::Particle.create( :x => 730, 
				                          :y => 413, 
				                          :zorder => ZOrder::SMOKE,
				                          :image => @smoke_particle,
				                          :fade_rate => -1, 
				                          :mode => :default
				                        )
		end

		#Simulates the effect of the wind on the smoke particles.
		if @smoke
			@smoke.each { |particle| particle.y -= 0.5; particle.x += rand }
		end
	end
end

Game.new.show