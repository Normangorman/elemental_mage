class Cloud < GameObject
	trait :velocity
	def initialize(options = {})
		super

		cloud_images = [Image["images/cloud1.png"], 
						Image["images/cloud2.png"], 
						Image["images/cloud3.png"], ]

		self.image = cloud_images.sample
		self.velocity_x = rand
		self.zorder = ZOrder::CLOUD
	end

	def update
		self.destroy if self.x > $window.width + self.image.width
	end
end

class Platform < GameObject
	trait :collision_detection
	trait :bounding_box, debug: true

	def initialize(options = {})
		super
		self.image = Image["images/platform.png"]
		self.zorder = ZOrder::PLATFORM
	end
end