class_name ValueEdit extends HBoxContainer

signal value_set

const text_color_normal := Color(0.875, 0.875, 0.875, 1.0)
const text_color_rejected := Color(1.0, 0.2, 0.2, 0.875)

var value := 0
@export var min_value : int = 0
@export var max_value : int = 20

func set_value(new_value : int, update_text := true) -> void:
	value = new_value
	set_plus_minus_buttons()
	emit_signal("value_set", value)
	if update_text:
		VALUE_INPUT.text = str(value)

#turns buttons on and off at cap values. Called by Set Value.
func set_plus_minus_buttons() -> void:
	if value <= min_value:
		MINUS_BUTTON.disabled = true
		PLUS_BUTTON.disabled = false
		return
	if value < max_value:
		MINUS_BUTTON.disabled = false
		PLUS_BUTTON.disabled = false
		return
	MINUS_BUTTON.disabled = false
	PLUS_BUTTON.disabled = true

#just GUI hooks
@onready var VALUE_INPUT := $"Value Input"
func _on_value_input_text_changed():
	var input_str : String = VALUE_INPUT.text
	#gate for ignoring blank input.
	if not input_str:
		VALUE_INPUT.modulate = text_color_normal
		return
	var input_int := int(VALUE_INPUT.text)
	#gate for ignoring inputs of lower value.
	#lets us type 10s when min_value > 1.
	if input_int < min_value:
		VALUE_INPUT.modulate = text_color_rejected
		return
	VALUE_INPUT.modulate = text_color_normal
	if input_int > max_value:
		set_value(max_value)
		return
	#prevents non-number characters.
	#also prevents negative numbers.
	if input_str != str(input_int):
		set_value(value)
		return
	#sets number based on user input. Our goal all along.
	#Seems insignificant after all the edge cases.
	set_value(input_int, false)

@onready var MINUS_BUTTON := $"Minus Button"
func _on_minus_button_pressed() -> void:
	if value > max_value:
		set_value(max_value)
		return
	set_value(value - 1)

@onready var PLUS_BUTTON := $"Plus Button"
func _on_plus_button_pressed() -> void:
	if value < min_value:
		set_value(min_value)
		return
	set_value(value + 1)
