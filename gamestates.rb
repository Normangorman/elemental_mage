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
		if rand(200) == 1
			Smoke.create(x: 730, y: 413)
		end
	end
end

class Instructions < GameState
end

class About < GameState
end

class MainMenu < GameState
	def initialize
		super
		MouseFollower.create
		@background_image = Image["images/bridge_and_sky.png"]
		@logo = Image["images/menu/logo.png"]

		MenuButton.create("Start game", 	y: 330, action: Play )
		Fireball.create(x: $window.width * 0.5 - 175, y: 350, power: 100, owner: self)

		MenuButton.create("Instructions", 	y: 440, action: Instructions )
		Waterball.create(x: $window.width * 0.5 - 175, y: 460, power: 100, owner: self)

		MenuButton.create("About" , 		y: 550, action: About )
		Airball.create(x: $window.width * 0.5 - 175, y: 570, power: 100, owner: self)
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

class MenuButton < Chingu::Text
	traits :collision_detection, :bounding_box
	def initialize(text, options = {})
		@button = Image["images/menu/button.png"]
		options = {
			x: $window.width * 0.5 - 100,
			zorder: ZOrder::UI,
			font: "media/SILKWONDER.ttf",

			size: 60,
			padding: 15,
			background: @button,
		}.merge(options) 

		super(text, options)
		#Changing the x attribute only moves the text, not the background - allowing the text to be centered in the background -
		# else it would not be centered properly.
		self.x += 25
	    @action = options[:action]
	end

	def update
		self.color = Gosu::Color::WHITE 
		each_bounding_box_collision(MouseFollower) { self.color = Gosu::Color::GREEN }
	end

	def trigger; $window.push_game_state(@action) end	
end

class MouseFollower < GameObject
	traits :collision_detection, :bounding_box
	def initialize(options={})
		super
		@image = Image["images/blank.bmp"]
	end

	def update
		super
		self.x = $window.mouse_x
		self.y = $window.mouse_y
		click if holding?(:mouse_left)
	end

	def click;  each_bounding_box_collision(MenuButton) {|me, button| button.trigger } end
end