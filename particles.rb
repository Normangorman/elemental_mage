class Particle < GameObject
	traits :velocity, :effect

	def initialize(options={})
		@player = options[:player] || nil
		#The call to super is here so that Spark#setup is not called before the player is defined.
		super
	end

	def update
		self.velocity_x *= 0.95
	end
end

class Spark < Particle
	def setup
		@image = Image["images/particles/spark.png"]
		@fade_rate = -7

		self.velocity_y = -2
		self.acceleration_y = 0.1
		self.velocity_x = -0.25 * @player.velocity_x + rand * rand(-2..2)
		self.zorder = ZOrder::SPARK
	end
end

class Smoke < Particle
	def setup
		@image = Image["images/particles/smoke_particle.bmp"]
		@fade_rate = -2

		self.velocity_y = -1
		self.acceleration_x = 0.05
		self.zorder = ZOrder::SMOKE
	end
end

class Air_particle < Particle
	def setup
		@image = Image["images/particles/airball_particle.png"]
		@fade_rate = -5
		self.zorder = ZOrder::SPARK
	end
end

class Water_particle < Particle
	def setup
		@image = Image["images/particles/waterball_particle.bmp"]
		@fade_rate = -15
		self.zorder = ZOrder::SPARK
	end
end

class Fire_particle < Particle
	def setup
		@image = Image["images/particles/fireball_particle.bmp"]
		@fade_rate = -10
		self.zorder = ZOrder::SPARK
	end
end