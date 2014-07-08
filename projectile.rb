class Projectile < GameObject
	traits :velocity, :collision_detection, :bounding_box
	attr_reader :owner, :power

	def initialize(options = {})
		super
		self.zorder = ZOrder::PROJECTILE
		@power = options[:power] || 25
		@owner = options[:owner]
		self.x = @owner.x
		self.y = @owner.y
		#The size parameter is manually defined here, otherwise self.size would return [nil, nil], resulting in bugs in Chingu's collisions handler.
		setup
		@image = @animation.first
		self.size = [@image.width, @image.height]
		#Release sound is the same for all sublasses.
		@release_sound = Sample["sounds/projectile_release.ogg"]
	end

	def charge
		@power += 1 unless @power == 100
		#Follow the player
		self.x = @owner.x
		self.y = @owner.y

		Spark.create(x: self.x, y: self.y, player: @owner) if rand(10) == 1
	end

	def release(direction)
		case direction
		when :north
			@velocity_y = -15
		when :north_east
			@velocity_x = 15
			@velocity_y = -15
		when :east
			@velocity_x = 15
		when :south_east
			@velocity_x = 15
			@velocity_y = 15
		when :south
			@velocity_y = 15
		when :south_west
			@velocity_x = -15
			@velocity_y = 15
		when :west
			@velocity_x = -15
		when :north_west
			@velocity_x = -15
			@velocity_y = -15
		else raise StandardError, "Invalid firing direction."
		end
		@released = true

		@release_sound.play(volume = @power * 0.01, speed = 1, looping = false)
	end

	def update
		@image = @animation.next
		@angle += 2
		#Enlarges the projectile proportionally to its power.
		self.factor_x = 3 * @power * 0.01
		self.factor_y = 3 * @power * 0.01

	    #Because the player can jump to a height that is just above the screen,
		# an upward-moving projectile is only destroyed if it moves 200 pixels above the screen.
		self.destroy if self.x < 0 || self.x > $window.width || self.y > $window.height || self.y < - 200

		# Only damage the enemy player, not the projectile's owner.
		self.each_bounding_box_collision(Player) do |me, player|
		    unless player == @owner
		    	#The amount of damage is done to the player is proportional the power of the projectile.
		        player.hurt(@power / 25, self)
		        explode 
		        self.destroy
		    end
	    end
	end
end

#Fire beats air, air beats water, water beats fire

class Fireball < Projectile
	def setup
		@animation = Animation.new(file: "animations/projectiles/fireball_16x16.png", :delay => 100)
	end

	def update
		super

		if @released
			#The number of times represents the density of the particle cloud created
			3.times { Fire_particle.create( x: self.x + rand(-5..5), y: self.y + rand(-5..5) ) }

			self.each_bounding_box_collision(Waterball) do |me, other|
		    	other.owner.power_shot = true
		    	self.destroy
		    	other.destroy
			end

			self.each_bounding_box_collision(Airball) do |me, other|
				@owner.power_shot = true
		    	self.destroy
		    	other.destroy
			end
		end
	end

	def explode
        (50 * @power * 0.01).floor.times { 
        	Fire_particle.create( x: self.x + rand(-5..5), 
			y: self.y + rand(-5..5), 
			velocity_x: rand(-5..5),
			velocity_y: rand(-5..5) ) 
        }
	end
end

class Waterball < Projectile
	def setup
		@animation = Animation.new(file: "animations/projectiles/waterball_16x16.png", :delay => 100)
	end

	def update
		super
		if @released
			10.times { Water_particle.create( x: self.x + rand(-5..5), y: self.y + rand(-5..5) ) }

			self.each_bounding_box_collision(Airball) do |me, other|
		    	other.owner.power_shot = true
		    	self.destroy
		    	other.destroy
			end
		end
	end

	def explode
        (50 * @power * 0.01).floor.times { 
        	Water_particle.create( x: self.x + rand(-5..5), 
			y: self.y + rand(-5..5), 
			velocity_x: rand(-5..5),
			velocity_y: rand(-5..5) ) 
        }
	end
end

class Airball < Projectile
	def setup
		@animation = Animation.new(file: "animations/projectiles/airball_16x16.png", :delay => 100)
	end

	def update
		super
		1.times { Air_particle.create( x: self.x + rand(-5..5), y: self.y + rand(-5..5) ) } if @released
	end

	def explode
        (50 * @power * 0.01).floor.times { 
        	Air_particle.create( x: self.x + rand(-5..5), 
			y: self.y + rand(-5..5), 
			velocity_x: rand(-5..5),
			velocity_y: rand(-5..5) ) 
        }
	end
end