extends Label

@export var check_interval: float = 0.5
@export var flip_chance: float = 0.05
@export var flip_duration: float = 0.3
@export var blink_chance: float = 0.01
@export var blink_duration: float = 0.2
@export var garb_chance: float = 0.05
@export var garb_duration: float = 0.3

var title_timer: float = 0.0
var is_flipped: bool = false
var flip_end_time: float = 0.0
var is_blinked: bool = false
var blink_end_time: float = 0.0
var is_garbbed: bool = false
var garb_end_time: float = 0.0
var origial_text: String


func _ready():
	title_timer = check_interval
	origial_text = text

func _process(delta):
	# Check if we should end current flip
	if is_flipped and Time.get_ticks_msec() / 1000.0 >= flip_end_time:
		is_flipped = false
		scale.y = 1.0
		
			# Check if we should end current flip
	if is_blinked and Time.get_ticks_msec() / 1000.0 >= blink_end_time:
		is_blinked = false
		modulate = Color.WHITE
		
	if is_garbbed and Time.get_ticks_msec() / 1000.0 >= garb_end_time:
		is_garbbed = false
		text = origial_text
	
	# Check for new flip
	title_timer -= delta
	if title_timer <= 0.0:
		title_timer = check_interval
		
		if randf() < flip_chance and not is_flipped:
			# Start flip
			is_flipped = true
			scale.y = -1.0  # Vertical flip
			flip_end_time = Time.get_ticks_msec() / 1000.0 + flip_duration
		
		if randf() < blink_chance and not is_blinked:
			is_blinked = true
			modulate = Color.TRANSPARENT
			blink_end_time = Time.get_ticks_msec() / 1000.0 + blink_duration
			
		if randf() < garb_chance and not is_garbbed:
			is_garbbed = true
			text[randi_range(0,text.length())-1] = ''
			garb_end_time = Time.get_ticks_msec() / 1000.0 + garb_duration
