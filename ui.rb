class Lifebar < GameObject
	def initialize(options={})
		super
		@owner = options[:owner]
		@hearts = []
		5.times do |n|
			@hearts << Heart.create(x: self.x + n * 35, y: self.y)
		end

		@previous_life_value = @owner.life
	end

	def update
		if @previous_life_value != @owner.life
			life = @owner.life
			
			@hearts.each do |heart|
				if life > 4
					heart.set_value(4)
					life -= 4
				elsif life <= 0
					heart.set_value(0)
				else
					heart.set_value(life)
					life = 0
				end
			end

			@previous_life_value = @owner.life
		end
	end
end

class Heart < GameObject
	def initialize(options={})
		super
		@owner = options[:owner]
		@images = {
			4 => 	Image["images/ui/heart_full.png"],
			3 => 	Image["images/ui/heart_three_quarters.png"],
			2 => 	Image["images/ui/heart_half.png"],
			1 => 	Image["images/ui/heart_one_quarter.png"],
			0 => 	Image["images/ui/heart_empty.png"],
		}

		#By default hearts are filled.
		@value = 4
		@image = @images[4]
		self.zorder = ZOrder::UI
	end

	def set_value(amount)
		@value = amount
		@image = @images[amount]
	end
end

class Power_icon < GameObject
	trait :effect
	def initialize(options={})
		super
		@owner = options[:owner]
		self.x = @owner.x
		self.y = @owner.y - 80
		self.zorder = ZOrder::PLAYER

		@animation = Animation.new(file: "animations/elemental_orbit.png", :delay => 50)
		@rotation_rate = 2
	end

	def update
		#follows the player
		unless @dying
			self.x = @owner.x
			self.y = @owner.y - 80
		end

		@image = @animation.next
		super
	end

	def remove
		@dying = true
		@fade_rate = -8
	end
end

class GameOverText < Chingu::Text
	traits :effect, :timer
	def initialize(name)
		@button = Image["images/menu/button.png"]
		#Because the game_over method is called on the player who loses, the name parameter will be the name of the
		# losing player. Hence the name of the winning player needs to be inferred.
		# This is done by swapping the number at the end of the player's name: 1 becomes 2 and vice versa.
		text = "Player " + {"1" => "2", "2" => "1"}[name.split("").last] + " wins!"

		options = {
			x: $window.width * 0.5 - 300,
			y: $window.height * 0.5 - 100,
			zorder: ZOrder::UI,
			font: "media/SILKWONDER.ttf",

			size: 100,
			padding: 15,
			background: @button,
		}

		super(text, options)
		#Changing the x attribute only moves the text, not the background - allowing the text to be centered in the background -
		# else it would not be centered properly.
		self.x += 50
		self.alpha = 0
		self.background.alpha = 0

		after(3000) do	
			$window.switch_game_state(MainMenu)
		end
	end

	def update
		self.alpha += 5
		self.background.alpha += 5
	end
end