class_name StatEditor extends HBoxContainer


### INITIALIZATION ###
var stat_name : String
@onready var NAME_READOUT := $"Name Readout/Label"

func set_all_values(stat_data : StatData) -> void:
	var new_roll_val : int = stat_data.get_roll_value(stat_name)
	roll_val = new_roll_val
	var new_base_val : int = stat_data.get_base_stat(stat_name)
	base_val = new_base_val
	var new_bg : bool = stat_data.get_background(stat_name)
	var new_adv_val =  stat_data.get_adv_stat(stat_name)
	adv_val = new_adv_val
	ADV_VAL_EDIT.set_value( new_adv_val )
	if stat_data.point_buy_mode:
		BASE_VAL_EDIT.set_value( new_base_val )
	else:
		ROll_VALUE_EDIT.set_value( new_roll_val )
		
	update_background(new_bg)
	ADV_VAL_EDIT.set_value( new_adv_val )
	#update_mode(stat_data.point_buy_mode)

func update_mode(point_buy : bool) -> void:
	var group_names := ["Rolled", "Point Buy"]
	if point_buy:
		BASE_VAL_EDIT.set_value(base_val)
	else:
		BASE_VAL_READOUT.text = str(convert_roll(roll_val))
	for node : Control in get_children():
		if node.is_in_group(group_names[int(point_buy)]):
			node.visible = true
			continue
		if node.is_in_group(group_names[int(not point_buy)]):
			node.visible = false

func  _ready() -> void:
	NAME_READOUT.text = stat_name

### ROLL INPUT ###
signal roll_val_updated

var roll_val : int
@onready var ROll_VALUE_EDIT := $"Roll Value Edit"
@onready var BASE_VAL_READOUT := $"Base Val Readout/Label"

func convert_roll(input : int) -> int:
	var output = float(input)
	output -= 10.0
	output = output / 3.0
	output = roundi(output)
	if input > 3:
		output += 1
	return output

func set_roll_value(value : int) -> void:
	roll_val = value
	var new_base_val = convert_roll(value)
	set_base_value(new_base_val)
	BASE_VAL_READOUT.text = str(convert_roll(value))
	emit_signal("roll_val_updated", value, stat_name)

func _on_roll_value_edit_set(value : int) -> void:
	set_roll_value(value)
	update_adv_max_val()


### BASE VALUE READOUT ###
signal base_val_updated

var base_val : int
@onready var BASE_VAL_EDIT := $"Base Value Edit"

func set_base_value(value: int) -> void:
	base_val = value
	emit_signal("base_val_updated", base_val, stat_name)
	update_total_val()

func _on_base_value_edit_set(value : int):
	set_base_value(value)
	update_adv_max_val()


### BACKGROUND TOGGLE ###
signal background_updated

var background := false
@onready var BG_TOGGLE := $"BG Toggle/CheckButton"

func update_background(toggled : bool) -> void:
	background = toggled
	BG_TOGGLE.button_pressed = toggled
	update_total_val()
	emit_signal("background_updated", toggled, stat_name)

func _on_check_button_toggled(toggled : bool) -> void:
	update_background(toggled)
	update_adv_max_val()


### ADVANCEMENT READOUT ###
signal adv_val_updated
signal adv_cost_updated

var adv_val : int
@onready var ADV_VAL_EDIT := $"Adv Value Edit"

func get_advancement_cost() -> int:
	var sub_total_stat = base_val + int(background)
	var total_stat = get_total_val()
	var cost = total_stat
	if total_stat > 5:
		cost += total_stat - 5
	if total_stat > 8:
		cost += total_stat - 8
	cost -= sub_total_stat
	return cost

func set_adv_value(value : int) -> void:
	adv_val = value
	emit_signal("adv_val_updated", adv_val, stat_name)
	emit_signal("adv_cost_updated", get_advancement_cost(), stat_name)
	update_total_val()

func update_adv_max_val() -> void:
	var new_max_val = 12
	new_max_val -= base_val + int(background)
	if new_max_val > 11:
		new_max_val = 11
	ADV_VAL_EDIT.max_value = new_max_val
	if ADV_VAL_EDIT.value > new_max_val:
		ADV_VAL_EDIT.set_value(new_max_val)
	else:
		ADV_VAL_EDIT.set_plus_minus_buttons()
	emit_signal("adv_val_updated", adv_val, stat_name)
	emit_signal("adv_cost_updated", get_advancement_cost(), stat_name)

func _on_adv_value_edit_set(value : int) -> void:
	set_adv_value(value)


### TOTAL READOUT ###
@onready var TOTAL_VAL_READOUT := $"Total Val Readout/Label"

func get_total_val() -> int:
	return base_val + int(background) + adv_val
func update_total_val() -> void:
	TOTAL_VAL_READOUT.text = str(get_total_val())
