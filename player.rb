class Player < GameObject
	trait :velocity
	trait :timer

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

		#Default to idle animation
		change_anim(:idle)
		
		#Gravity
		self.acceleration_y = 0.4

		#Used to prevent jumping again until landed
		@jumping = false

		@current_direction = :north
	end

	def change_anim(name)
		@animation = @animations[name]
		@image = @animation.next
	end

	def update
		if self.y > $ground_y - 50
			self.y = $ground_y - 50
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
				@projectile.factor_x += 0.03 unless @projectile.factor_x >= 3
				@projectile.factor_y += 0.03 unless @projectile.factor_y >= 3
			else
				@projectile.release(calculate_firing_direction)
				@projectile = nil
				start_cooldown
			end
		end

	end

	#MOVEMENT METHODS
	def move_right
		@current_direction = :east

		change_anim(:walk_right)
		self.x += 5
	end

	def move_left
		@current_direction = :west

		change_anim(:walk_left)
		self.x -= 5
	end

	def jump
		@current_direction = :north
		return if @jumping

		change_anim(:jumping)
		self.velocity_y = -12
		@jumping = true
	end

	def look_down
		p "looking down"
		@current_direction = :south

		@jumping ? change_anim(:falling) : change_anim(:looking_down)

		self.velocity_y += 0.5
	end


	#FIRING METHODS
	def start_cooldown
		@cooling_down = true
    	after(1000) { @cooling_down = false }
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
