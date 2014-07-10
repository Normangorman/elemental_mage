class Player < GameObject
	traits :velocity, :timer, :collision_detection, :bounding_box
	attr_accessor :life, :power_shot, :projectile
	attr_reader :staff_x, :staff_y

	def initialize(options={})
		super
		self.input = options[:controls]
		#This is set so that methods can refer to specific keys via the method that those keys carry out.
		@controls = options[:controls].invert

		#Used to distinguish player1 from player2
		@name = options[:name]
		
		add_anim = Proc.new {|file| Animation.new(file: "animations/#{@name}/" + file, :delay => 200) }
		@animations = {
			idle: 			add_anim.call("idle_96x96.png"),
			walk_left: 		add_anim.call("walk_left_96x96.png"),
			walk_right: 	add_anim.call("walk_right_96x96.png"),
			falling: 		add_anim.call("falling_96x96.png"),
			looking_down: 	add_anim.call("looking_down_96x96.png"),
			jumping: 		add_anim.call("jumping_96x96.png"),
			death:  		Animation.new(file: "animations/#{@name}/death_96x96.png", :delay => 80),
		}
		@staff_positions = {
			idle: [34, -29],
			walk_left: [-32, -31],
			walk_right: [32, -31],
			falling: [34, -29],
			looking_down: [35, -29],
			jumping: [34, -29],
			death: [34, -29],
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
	end

	#called by movement methods in order to change the current animation.
	def change_anim(name)
		@animation = @animations[name]
		@staff_x = self.x + @staff_positions[name].first
		@staff_y = self.y + @staff_positions[name].last

		@image = @animation.next #This is called by firing and movement methods in order to change the animation.
	end

	#called by projectiles when they collide with the player
	def hurt(amount, projectile)
		@life -= amount
		#lose game if life <= 0
		@hurt_sound ||= Sample["sounds/hurt.ogg"]
		@hurt_sound.play(volume = Settings.effect_volume * amount, speed = 1, looping = false)

		#Knockback based on projectile power
		self.velocity_x += projectile.velocity_x * 0.25 * amount
		self.velocity_y += projectile.velocity_y * 0.25 * amount
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

		if @power_shot
			@power_up_sound ||= Sample["sounds/power_up.ogg"]

			unless @power_icon
				@power_icon = Power_icon.create(owner: self) 
				@power_up_sound.play(volume = Settings.effect_volume, speed = 1, looping = false)
			end
		end

		handle_held_keys
		handle_animations
		handle_collisions

		@staff_x += self.x - self.previous_x
		@staff_y += self.y - self.previous_y

		#Handles losing the game
		
		lose_game if @life <= 0 and @game_over != true
		
		if @game_over and @image == @animation.last
			#Explode the staff's crystal.
			100.times { ExplosionSpark.create(x: @staff_x, y: @staff_y, player: self) }
			self.pause!

			$window.current_game_state.background_music.stop
			Sample["sounds/victory.ogg"].play(volume = Settings.music_volume, speed = 1, looping = false)
			GameOverText.create(@name)
		end

	end

	def lose_game
		@projectile.destroy if @projectile
		@power_icon.remove if @power_icon
		change_anim(:death)
		self.input = nil
		@game_over = true
	end

	def handle_held_keys
		look_down  if holding?(@controls[:look_down])
		jump       if holding?(@controls[:jump])
		move_right if holding?(@controls[:move_right])
		move_left  if holding?(@controls[:move_left])
	end

	def handle_animations
		change_anim(:idle) unless holding_any?(*@controls.values) || @game_over
		
		if @jumping and self.velocity_y > 0
			change_anim(:falling)
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
		if @projectile
			@projectile.release(calculate_firing_direction)
			@projectile = nil
			start_cooldown
		elsif @power_shot
			klass.create(owner: self, power: 100).release(calculate_firing_direction)
			@power_shot = false
			@power_icon.remove if @power_icon
			@power_icon = nil
			start_cooldown
		elsif @cooling_down
			return
		else
			@projectile = klass.create(owner: self)
		end

	end

	def grow_fire; 	handle_projectile(Fireball)  end
	def grow_water; handle_projectile(Waterball) end
	def grow_air; 	handle_projectile(Airball) 	 end
end
