require 'rubygems' rescue nil
#$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "media")

require 'chingu'
require 'yaml' # required for ocra.
require 'fileutils'
$:.unshift File.dirname($0)
include Gosu
include Chingu

require_relative 'ui'
require_relative 'player'
require_relative 'projectile'
require_relative 'scenery'
require_relative 'particles'
require_relative 'gamestates'

module ZOrder
	BACKGROUND = 0
	SMOKE = 1
	CLOUD = 2
	PLATFORM = 3
	PLAYER = 4
	SPARK = 5
	PROJECTILE = 6
	UI = 7
end

module Controls
	@@player1 = {
		s:	:look_down,
		w:	:start_jump,
		released_w: :jump,
		d: 	:move_right,
		a: 	:move_left,
		
		r: :grow_fire,
		t: :grow_water,
		y: :grow_air,
	}

	@@player2 = {
		down: 	:look_down,
		up: 	:start_jump,
		released_up: :jump,
		right: 	:move_right,
		left:  	:move_left,
		
		b: :grow_fire,
		n: :grow_water,
		m: :grow_air,
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
    switch_game_state(MainMenu)
    transitional_game_state(Chingu::GameStates::FadeTo, {:speed => 5, :debug => true})
    $window.caption = "Elemental Mage"
  end

  def needs_cursor?
  	true
  end

end

Game.new.show