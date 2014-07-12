class Play < GameState
	attr_accessor :background_music
	def initialize
		#Putting the destruction methods in this position was the only way to fix the bug in which objects from a previous game
		# would persist in future games - creating invisible, invulnerable but projectile-collidable players.
		Fireball.destroy_all
		Waterball.destroy_all
		Airball.destroy_all
		Player.destroy_all
		$window.game_objects.destroy_all

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

		@background_music = Gosu::Song.new($window, "media/sounds/wizards_keep.ogg")
		@background_music.play(looping = true)
		@background_music.volume = Settings.music_volume
	end

	def update
		super
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
		if rand(200) == 1
			Smoke.create(x: 730, y: 413)
		end
	end
end

class Instructions < GameState
	def initialize
		super
		MouseFollower.create
		@image = Image["instructions_sheet.png"]
		MenuButton.create(text: "Back to menu", 
						  x: $window.width - 300, 
						  y: $window.height - 150, 
						  action: lambda {switch_game_state(MainMenu)} )
	end

	def draw
		super
		@image.draw(0, 0, 0)
	end
end

class About < GameState
	def initialize
		super
		MouseFollower.create
		@image = Image["about_sheet.png"]
		MenuButton.create(text: "Back to menu", 
						  x: $window.width - 300, 
						  y: $window.height - 150, 
						  action: lambda {switch_game_state(MainMenu)} )
	end

	def draw
		super
		@image.draw(0, 0, 0)
	end
end

class MainMenu < GameState
	def initialize
		super
		MenuButton.destroy_all
		MouseFollower.destroy_all

		MouseFollower.create
		@background_image = Image["images/bridge_and_sky.png"]
		@logo = Image["images/menu/logo.png"]

		def link_to(link)
			lambda {
			if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
			  system "start #{link}"
			elsif RbConfig::CONFIG['host_os'] =~ /darwin/
			  system "open #{link}"
			elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
			  system "xdg-open #{link}"
			end 
			}
		end

		MenuButton.create(text: "Start game", y: 350, action: lambda {switch_game_state(Play)} )
		MenuButton.create(text: "Instructions", y: 460, action: lambda {switch_game_state(Instructions)} )
		MenuButton.create(text: "About", y: 570, action: lambda {switch_game_state(About)} )												
	end

	def update
		super
		spawn_scenery_objects
	end

	def draw
		super
		@background_image.draw 0, 0, ZOrder::BACKGROUND
		@logo.draw 0.5 * ($window.width - @logo.width), 10, ZOrder::UI
	end

	def spawn_scenery_objects
		#Total number of clouds on screen at one time is limited to 5.
		if rand(400) == 1 and Cloud.size <= 5
			Cloud.create
		end

		#Spawns smoke from the house in the background image
		if rand(200) == 1
			Smoke.create(x: 730, y: 413)
		end
	end
end

class MenuButton < GameObject
	traits :collision_detection, :bounding_box
	
	def initialize(options = {})
		super
		@button = Image["images/menu/button.png"]
		#@button.rotation_center = :center_center
		
		self.x = options[:x] || $window.width * 0.5
		self.y = options[:y]
		self.zorder = ZOrder::UI

		text = options[:text]
		font = "media/silkwonder.ttf"
		size = 60

		@image = Gosu::Image.from_text($window, text, font, size)

		#The action should be a block which dictates what will be done when the button is clicked
	    @action = options[:action]
	end

	def update
		self.color = Gosu::Color::WHITE
		#Changes text colour on mouse over
		each_bounding_box_collision(MouseFollower) { self.color = Gosu::Color::GREEN }
	end

	def draw
		@button.draw(self.x - @button.width * 0.5, 
					 self.y - @button.height * 0.5, 
					 self.zorder-1)
		super
	end

	def trigger
		@action.call
	end
end

class MouseFollower < GameObject
	traits :collision_detection, :bounding_box
	def initialize(options={})
		super
		@image = Image["images/blank.bmp"]
		self.input = {mouse_left: :click}
	end

	def update
		super
		self.x = $window.mouse_x
		self.y = $window.mouse_y
	end

	def click;  each_bounding_box_collision(MenuButton) {|me, button| button.trigger } end
end