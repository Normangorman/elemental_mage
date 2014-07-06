class Projectile < GameObject
	trait :velocity
	def initialize(options = {})
		super
	end

	def release(direction)
		case direction
		when :north
			@velocity_y = -10
		when :north_east
			@velocity_x = 10
			@velocity_y = -10
		when :east
			@velocity_x = 10
		when :south_east
			@velocity_x = 10
			@velocity_y = 10
		when :south
			@velocity_y = 10
		when :south_west
			@velocity_x = -10
			@velocity_y = 10
		when :west
			@velocity_x = -10
		when :north_west
			@velocity_x = -10
			@velocity_y = -10
		else raise StandardError, "Invalid firing direction."
		end
		@released = true
	end

	def update
		@image = @animation.next
		@angle += 2
	end
end



class Fireball < Projectile
	def setup
		@animation = Animation.new(file: "animations/projectiles/fireball_16x16.png", :delay => 100)
		@fireball_particle = Image["images/fireball_particle.bmp"]
	end

	def update
		if @released
			3.times do 
				Chingu::Particle.create( :x => self.x + rand(-5..5), 
		                          :y => self.y + rand(-5..5), 
		                          :image => @fireball_particle,
		                          :fade_rate => -10, 
		                          :mode => :default
		                        )
			end
		end
		super
	end
end

class Waterball < Projectile
	def setup
		@animation = Animation.new(file: "animations/projectiles/waterball_16x16.png", :delay => 100)
		@waterball_particle = Image["images/waterball_particle.bmp"]
	end

	def update
		if @released
			10.times do 
				Chingu::Particle.create( :x => self.x + rand(-5..5), 
		                          :y => self.y + rand(-5..5), 
		                          :image => @waterball_particle,
		                          :fade_rate => -15, 
		                          :mode => :default
		                        )
			end
		end
		super
	end
end

class Airball < Projectile
	def setup
		@animation = Animation.new(file: "animations/projectiles/airball_16x16.png", :delay => 100)
		@airball_particle = Image["images/airball_particle.png"]
	end

	def update
		if @released
			1.times do 
				Chingu::Particle.create( :x => self.x + rand(-5..5), 
		                          :y => self.y + rand(-5..5), 
		                          :image => @airball_particle,
		                          :fade_rate => -5,
		                          :mode => :default
		                        )
			end
		end
		super
	end
end