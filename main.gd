extends Panel


### STAT DATA ###
var selected_stat_data : StatData 
var STAT_EDITOR := preload("res://stat_editor.tscn")
@onready var STAT_EDITOR_BOX := $"Stat Editor Box"

func create_new_stat_data() -> StatData:
	var new_stat_data = StatData.new()
	new_stat_data.propagate_new()
	return new_stat_data

func create_stat_data_from_pack(character_name : String, pack : PackedByteArray) -> StatData:
	var new_stat_data := create_new_stat_data()
	new_stat_data.set_pack(character_name, pack)
	return new_stat_data

func set_selected_stat_data(stat_data : StatData) -> void:
	#variable is set first
	selected_stat_data = stat_data
	#clear the old stat editors
	for child : Control in STAT_EDITOR_BOX.get_children():
		child.queue_free()
	#spacer for vibes
	var spacer = HSeparator.new()
	STAT_EDITOR_BOX.add_child(spacer)
	#character name and level field set
	CHARACTER_NAME_EDIT.text = selected_stat_data.character_name
	LEVEL_VALUE_EDIT.set_value(selected_stat_data.get_character_level())
	
	for stat_name : String in selected_stat_data.StatNames:
		#adv_costs.append(0)
		var new_stat_editor : StatEditor = STAT_EDITOR.instantiate()
		new_stat_editor.stat_name = stat_name
		new_stat_editor.roll_val_updated.connect(_on_stat_editor_roll_val_updated)
		new_stat_editor.base_val_updated.connect(_on_stat_editor_base_val_updated)
		new_stat_editor.background_updated.connect(_on_stat_editor_background_updated)
		new_stat_editor.adv_val_updated.connect(_on_stat_editor_adv_val_updated)
		new_stat_editor.adv_cost_updated.connect(_on_stat_editor_adv_cost_updated)
		STAT_EDITOR_BOX.add_child(new_stat_editor)
		new_stat_editor.set_all_values(selected_stat_data)
		var new_spacer = HSeparator.new()
		STAT_EDITOR_BOX.add_child(new_spacer)
	toggle_mode(selected_stat_data.get_point_buy_mode())


### INITIALIZATION ###
var adv_costs : PackedByteArray = []

func initialize_adv_costs() -> void:
	for _stat_name in StatData.StatNames:
		adv_costs.append(0)

func inititialize_popups() -> void:
	LOAD_OPTION_POPUP_MENU = LOAD_OPTION_BUTTON.get_popup()
	LOAD_OPTION_POPUP_MENU.id_pressed.connect(_load_popup_item_selected)
	update_load_option_items()
	CONFIRM_DELETE_BUTTON.id_pressed.connect(_on_confirm_delete_button_pressed)

func _ready() -> void:
	initialize_adv_costs()
	loaded_packs = load_stat_data()
	if not loaded_packs:
		var new_stat_data = StatData.new()
		new_stat_data.propagate_new()
		set_selected_stat_data(new_stat_data)
	else:
		for char_name : String in loaded_packs.keys():
			set_selected_stat_data(create_stat_data_from_pack(char_name, loaded_packs[char_name]))
			break
	inititialize_popups()


### LOAD  ###
const folder_name := "/DragonAgeTTRPGData"
const file_name := "/DAData"
const file_extenstion := ".bin"

var loaded_packs := {}
@onready var LOAD_OPTION_BUTTON := $"Character Area/Panel/Load Option Button"
@onready var LOAD_OPTION_POPUP_MENU : PopupMenu = LOAD_OPTION_BUTTON.get_popup()

func get_file_path() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + folder_name

func load_stat_data() -> Dictionary:
	var file_path : String = get_file_path()
	var full_file_path : String = file_path + file_name + file_extenstion
	var new_loaded_data := {}
	var dir_exists := DirAccess.dir_exists_absolute(file_path)
	if not dir_exists:
		var error := DirAccess.make_dir_absolute(file_path)
		if error:
			CHARACTER_NAME_EDIT.text = "Error, Directory Not Made"
			return new_loaded_data
	if not FileAccess.file_exists(file_path + file_name + file_extenstion):
		CHARACTER_NAME_EDIT.text = "BIN FILE NOT FOUND!"
		return new_loaded_data
	var file := FileAccess.open(full_file_path, FileAccess.READ)
	new_loaded_data = file.get_var()
	return new_loaded_data

func add_load_option_item(item_name : String) -> void:
	LOAD_OPTION_POPUP_MENU.add_item(item_name)

func update_load_option_items() -> void:
	LOAD_OPTION_POPUP_MENU.clear()
	add_load_option_item("New Character")
	for character_name in loaded_packs.keys():
		add_load_option_item(character_name)

func _load_popup_item_selected(item_id : int) -> void:
	if not item_id:
		set_selected_stat_data(create_new_stat_data())
		return
	var item_name : String = LOAD_OPTION_POPUP_MENU.get_item_text(item_id)
	var pack : PackedByteArray = loaded_packs[item_name]
	set_selected_stat_data( create_stat_data_from_pack(item_name, pack) )


### SAVE ###
func _on_save_button_pressed():
	if not selected_stat_data.character_name or selected_stat_data.character_name == "New Character":
		return
	var new_char_name = selected_stat_data.character_name
	loaded_packs[new_char_name] = selected_stat_data.get_pack()
	selected_stat_data.character_name_master = new_char_name
	save_dict_as_bin(loaded_packs)

func save_dict_as_bin(dict : Dictionary) -> void:
	var new_file_path = get_file_path() + "/" + file_name + file_extenstion
	var save_file = FileAccess.open(new_file_path, FileAccess.WRITE)
	save_file.store_var(dict)
	update_load_option_items()


### DELETE ###
@onready var DELETE_BUTTON := $"Character Area/Delete Button"
@onready var CONFIRM_DELETE_BUTTON : PopupMenu = DELETE_BUTTON.get_popup()

func _on_confirm_delete_button_pressed(_id : int) -> void:
	loaded_packs.erase(selected_stat_data.character_name_master)
	save_dict_as_bin(loaded_packs)
	var new_stat_data := create_new_stat_data()
	for char_name in loaded_packs.keys():
		new_stat_data.set_pack(char_name, loaded_packs[char_name])
		break
	set_selected_stat_data(new_stat_data)
	update_load_option_items()


### NAME INPUT ###
@onready var CHARACTER_NAME_EDIT := $"Character Area/Character Name Edit"

func _on_character_name_edit_text_changed():
	selected_stat_data.character_name = CHARACTER_NAME_EDIT.text


### LEVEL INPUT ###
@onready var LEVEL_VALUE_EDIT := $"Level Area/Level Value Edit"

func set_character_level(value : int) -> void:
	selected_stat_data.set_character_level(value)
	ADV_TOTAL_READOUT.text = str(value -1)
	if get_total_adv_cost() > selected_stat_data.character_level - 1:
		ADV_SPENT_READOUT.modulate = Color.RED
		return
	ADV_SPENT_READOUT.modulate = Color.WHITE

func _on_level_value_edit_set(value : int) -> void:
	set_character_level(value)


### TOGGLE INPUT ###
@onready var MODE_TOGGLE := $"Level Area/Toggle Area/CheckButton"
@onready var MODE_READOUT := $"Level Area/Mode Readout"
@onready var PB_AREA := $"Point Tracker Area/VBoxContainer/PB Area"
@onready var PB_READOUT := $"Point Tracker Area/VBoxContainer/PB Area/PB Readout"

func toggle_mode(toggled_on : bool) -> void:
	selected_stat_data.set_point_buy_mode(toggled_on)
	MODE_TOGGLE.button_pressed = toggled_on
	for child : Control in STAT_EDITOR_BOX.get_children():
		if not child is StatEditor:
			continue
		child.update_mode(toggled_on)
	if toggled_on:
		MODE_READOUT.text = "Point Buy"
		PB_AREA.visible = true
		return
	MODE_READOUT.text = "Rolled"
	PB_AREA.visible = false

func _on_check_button_toggled(toggled_on : bool) -> void:
	toggle_mode(toggled_on)


### STAT EDITOR ###
@onready var ADV_SPENT_READOUT := $"Point Tracker Area/VBoxContainer/Adv Area/Spent Readout"
@onready var ADV_TOTAL_READOUT := $"Point Tracker Area/VBoxContainer/Adv Area/Total Readout"

func get_total_adv_cost() -> int:
	var total_cost := 0
	for cost : int in adv_costs:
		total_cost += cost
	return total_cost

func _on_stat_editor_roll_val_updated(value : int, stat_name : String ) -> void:
	selected_stat_data.set_roll_value(value, stat_name)

func _on_stat_editor_base_val_updated(value : int, stat_name : String) -> void:
	selected_stat_data.set_base_stat(value, stat_name)
	var pb_val := 0
	for base_stat : int in selected_stat_data.base_stats:
		pb_val += base_stat - 2
	PB_READOUT.text = str(pb_val)
	if pb_val > 10:
		PB_READOUT.modulate = Color.YELLOW
		return
	PB_READOUT.modulate = Color.WHITE

func _on_stat_editor_background_updated(value : bool, stat_name : String) -> void:
	selected_stat_data.set_background(value, stat_name)

func _on_stat_editor_adv_val_updated(value : int, stat_name : String) -> void:
	selected_stat_data.set_adv_stat(value, stat_name)

func _on_stat_editor_adv_cost_updated(value : int, stat_name : String) -> void:
	adv_costs[selected_stat_data.StatNames.get(stat_name)] = value
	var total_cost := get_total_adv_cost()
	ADV_SPENT_READOUT.text = str(total_cost)
	if total_cost > selected_stat_data.character_level - 1:
		ADV_SPENT_READOUT.modulate = Color.RED
		return
	ADV_SPENT_READOUT.modulate = Color.WHITE
