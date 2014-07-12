class Cloud < GameObject
	trait :velocity
	def initialize(options = {})
		super

		cloud_images = [Image["images/cloud1.png"], 
						Image["images/cloud2.png"], 
						Image["images/cloud3.png"], ]

		@image = cloud_images.sample

		self.x = - @image.width
		self.y = 250 * rand
		self.velocity_x = rand + 0.15
		self.zorder = ZOrder::CLOUD
	end

	def update
		self.destroy if self.x > $window.width + self.image.width
	end
end

class Platform < GameObject
	trait :collision_detection
	trait :bounding_box

	def initialize(options = {})
		super
		self.image = Image["images/platform.png"]
		self.zorder = ZOrder::PLATFORM
	end
end