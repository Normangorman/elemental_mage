class Lifebar < GameObject
	def initialize(options={})
		super
		@owner = options[:owner]
		@hearts = []

		PlayerHead.create(x: self.x + 2, y: self.y + 5, owner: @owner)
		5.times do |n|
			@hearts << Heart.create(x: self.x + 60 + n * 35, y: self.y, owner: @owner)
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

class PlayerHead < GameObject
	def initialize(options={})
		super
		@image = Image["animations/#{options[:owner].name}/head.png"]
		self.zorder = ZOrder::UI
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

class GameOverText < GameObject
	traits :timer
	def initialize(options={})
		super
		name = options[:name]
		#Because the game_over method is called on the player who loses, the name parameter will be the name of the
		# losing player. Hence the name of the winning player needs to be inferred.
		# This is done by swapping the number at the end of the player's name: 1 becomes 2 and vice versa.
		text = "Player " + {"1" => "2", "2" => "1"}[name[-1]] + " wins!"

		self.x = $window.width * 0.5
		self.y = $window.height * 0.5
		self.zorder = ZOrder::UI

		font = "media/silkwonder.ttf"
		size = 100
		
		#Changing the x attribute only moves the text, not the background - allowing the text to be centered in the background -
		# else it would not be centered properly.
		@image = Gosu::Image.from_text($window, text, font, size)
		@button = Image["images/menu/button.png"]

		after(3000) do	
			$window.push_game_state(MainMenu, finalize: true)
		end
	end

	def draw
		super
		scale = 1.5
		@button.draw(self.x - @button.width * scale * 0.5, 
				 	 self.y - @button.height * scale * 0.5, 
				 	 self.zorder-1,
				 	 factor_x = scale,
				 	 factor_y = scale)
	end
end