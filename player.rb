class Player < GameObject
	trait :velocity
	trait :timer
	trait :collision_detection
	trait :bounding_box, debug: true

	attr_reader :on_platform

	def initialize(options={})
		super
		self.input = {
			[:down_arrow, :holding_down_arrow] 	=> :look_down,
			[:up, :holding_up] 					=> :jump,
			[:right, :holding_right] 			=> :move_right,
			[:left, :holding_left] 				=> :move_left,
			
			holding_q: :grow_fire,
			holding_w: :grow_water,
			holding_e: :grow_air,
		}

		add_anim = Proc.new {|name| Animation.new(file: "animations/player1/" + name, :delay => 100) }
		@animations = {
			idle: 			add_anim.call("idle_80x80.png"),
			walk_left: 		add_anim.call("walk_left_80x80.png"),
			walk_right: 	add_anim.call("walk_right_80x80.png"),
			falling: 		add_anim.call("falling_80x80.png"),
			looking_down: 	add_anim.call("looking_down_80x80.png"),
			jumping: 		add_anim.call("jumping_80x80.png"),
		}
		self.zorder = ZOrder::PLAYER

		#Default to idle animation
		change_anim(:idle)

		#Used to prevent jumping again until landed
		@jumping = false

		@current_direction = :north
	end

	def change_anim(name)
		@animation = @animations[name]
		@image = @animation.next
	end

	def update
		
		#Physics
		self.velocity_x *= 0.8

		if self.y > $ground_y
			self.y = $ground_y
			@jumping = false
		end

		if self.x < self.image.width/2
			self.x = self.image.width/2
		elsif self.x > $window.width - self.image.width/2
			self.x = $window.width - self.image.width/2
		end

		#Animation control
		#THIS LINE MIGHT CAUSE BUGS!!!
		@animation = @animations[:idle] unless self.holding_any?(:right, :left, :up, :down)
		@image = @animation.next

		#Ball control ;)
		if @projectile
			if holding?(@grow_button)
				@projectile.x = self.x
				@projectile.y = self.y
				@projectile.factor_x *= 1.05 unless @projectile.factor_x >= 3
				@projectile.factor_y *= 1.05 unless @projectile.factor_y >= 3
			else
				@projectile.release(calculate_firing_direction)
				@projectile = nil
				start_cooldown
			end
		end

		handle_collisions
	end

	def handle_collisions
		#platform collisions
		self.acceleration_y = 0.4

		if @on_platform
			#Checks to see whether we walked off the platform
			x = @platform.x
			width = 0.5 * @platform.image.width
			@on_platform = false unless self.x.between?(x - width, x + width)

			#Gravity is disabled when on a platform
			self.acceleration_y = 0
			@jumping = false

		else
			self.each_collision(Platform) do |player, platform|
				#The resting height is the point at which the player appears to be standing on the platform
			    resting_height = platform.y - 0.5 * platform.image.height - 0.5 * self.image.height

			    if self.previous_y < resting_height
				    @on_platform = true
				    @platform = platform

				    self.velocity_y = 0
				    self.acceleration_y = 0
				    self.y = resting_height
			    end
			end
			
		end

	end

	#MOVEMENT METHODS
	def move_right
		@current_direction = :east

		change_anim(:walk_right)
		self.velocity_x += 2 unless self.velocity_x >= 10
	end

	def move_left
		@current_direction = :west

		change_anim(:walk_left)
		self.velocity_x -= 2 unless self.velocity_x <= -10
	end

	def jump
		@current_direction = :north
		return if @jumping

		change_anim(:jumping)
		self.velocity_y = -15

		@jumping = true
		@on_platform = false
	end

	def look_down

		p "looking down"
		@current_direction = :south

		@jumping ? change_anim(:falling) : change_anim(:looking_down)

		self.velocity_y += 0.5
		@on_platform = false
	end


	#FIRING METHODS
	def start_cooldown
		@cooling_down = true
    	after(600) { @cooling_down = false }
	end

	def calculate_firing_direction
		case @current_direction
		when :east
			if holding?(:up)
				:north_east
			elsif holding?(:down)
				:south_east
			else 
				:east
			end
		when :west
			if holding?(:up)
				:north_west
			elsif holding?(:down)
				:south_west
			else
				:west
			end
		when :north
			if holding?(:right)
				:north_east
			elsif holding?(:left)
				:north_west
			else
				:north
			end
		when :south
			if holding?(:right)
				:south_east
			elsif holding?(:left)
				:south_west
			else
				:south
			end
		end
	end

	def release_projectile

	end

	def grow_fire
		#remember to handle cooldowns
		return if @projectile || @cooling_down
		@grow_button = :q
		@projectile = Fireball.create(x: self.x, y: self.y)
	end

	def grow_water
		return if @projectile || @cooling_down
		@grow_button = :w
		@projectile = Waterball.create(x: self.x, y: self.y)
	end

	def grow_air
		return if @projectile || @cooling_down
		@grow_button = :e
		@projectile = Airball.create(x: self.x, y: self.y)
	end
end
