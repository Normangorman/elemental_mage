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
	def initialize(options={})
		super
		@owner = options[:owner]
		self.x = @owner.x
		self.y = @owner.y - 80
		self.zorder = ZOrder::PLAYER

		@animation = Animation.new(file: "animations/elemental_orbit.png", :delay => 50)
	end

	def update
		#follows the player
		unless @dying
			self.x = @owner.x
			self.y = @owner.y - 80
		end

		self.alpha -= 8 if @dying

		@image = @animation.next
		@angle += 3
		super
	end

	def remove
		@dying = true
	end
end