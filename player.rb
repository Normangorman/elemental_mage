class Player < GameObject
	trait :velocity
	trait :timer
	trait :collision_detection
	trait :bounding_box, debug: true

	attr_accessor :life, :power_shot

	def initialize(options={})
		super
		self.input = options[:controls]
		#This is set so that methods can refer to specific keys via the method that those keys carry out.
		@controls = options[:controls].invert

		#Used to distinguish player1 from player2
		@name = options[:name]
		
		add_anim = Proc.new {|file| Animation.new(file: "animations/#{@name}/" + file, :delay => 100) }
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
		self.zorder = ZOrder::PLAYER
		#Used to prevent jumping again until landed
		@current_direction = :north

		#Make relevant UI
		@life = 20
		case @name
		when "player1"
			@lifebar = Lifebar.create(x: 30, y:30, owner: self)
		when "player2"
			@lifebar = Lifebar.create(x: $window.width - 5*35, y:30, owner: self)
		end

		p self.center_x
		p self.center_y
	end

	def change_anim(name)
		@animation = @animations[name]
		@image = @animation.next #This is called by firing and movement methods in order to change the animation.
	end

	#UPDATION METHODS
	def update
		#Physics
		self.velocity_x *= 0.8

		if self.y > $ground_y
			self.y = $ground_y
			@jumping = false
		end

		#Level borders
		if self.x < self.image.width/2
			self.x = self.image.width/2
		elsif self.x > $window.width - self.image.width/2
			self.x = $window.width - self.image.width/2
		end
		
		@projectile.charge if @projectile

		handle_held_keys
		handle_animations
		handle_collisions
	end

	def handle_held_keys
		look_down  if holding?(@controls[:look_down])
		jump       if holding?(@controls[:jump])
		move_right if holding?(@controls[:move_right])
		move_left  if holding?(@controls[:move_left])
	end

	def handle_animations
		@animation = @animations[:idle] unless holding_any?(*@controls.values)
		
		if @jumping and self.velocity_y > 0
			@animation = @animations[:falling]
		end

		@image = @animation.next
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

		#projectile collisions
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
			if holding?(@controls[:jump])
				:north_east
			elsif holding?(@controls[:look_down])
				:south_east
			else 
				:east
			end
		when :west
			if holding?(@controls[:jump])
				:north_west
			elsif holding?(@controls[:look_down])
				:south_west
			else
				:west
			end
		when :north
			if holding?(@controls[:move_right])
				:north_east
			elsif holding?(@controls[:move_left])
				:north_west
			else
				:north
			end
		when :south
			if holding?(@controls[:move_right])
				:south_east
			elsif holding?(@controls[:move_left])
				:south_west
			else
				:south
			end
		end
	end

	def handle_projectile(klass)
		if @power_shot
			p "shot a power shot"
			klass.create(owner: self, power: 100).release(calculate_firing_direction)
			@power_shot = false
			start_cooldown
		elsif @cooling_down
			p "cooling down so didnt create a projectile"
			return
		elsif @projectile
			p "fired the current projectile"
			@projectile.release(calculate_firing_direction)
			@projectile = nil
			start_cooldown
		else
			p "made a projectile"
			@projectile = klass.create(owner: self)
			p "size: #{@projectile.size}"
		end

	end

	def grow_fire
		p "handling fireball"
		handle_projectile(Fireball)
	end

	def grow_water
		p "handling waterball"
		handle_projectile(Waterball)
	end

	def grow_air
		p "handling airball"
		handle_projectile(Airball)
	end
end
