class_name StatData extends RefCounted

#Perception is a weird stat in any system, hot take.
enum StatNames {
	Communcation,
	Constitution,
	Cunning,
	Dexterity,
	Magic,
	Perception,
	Strength,
	Willpower
}

#master name stored for deletion targets.
var character_name_master : String = ""
var character_name : String = ""
var character_level := 1
var point_buy_mode : bool = false
var roll_values : PackedByteArray = []
var base_stats : PackedByteArray = []
var backgrounds := 0
var adv_stats : PackedByteArray = []

#creates default entries in stat arrays.
func propagate_new() -> void:
	for stat_name in StatNames:
		roll_values.append(5)
		base_stats.append(2)
		adv_stats.append(0)

### COMPRESSION IS FUN! ###
#called on save.
func get_pack() -> PackedByteArray:
	return pack_byte_array()
#called on load
func set_pack(new_name : String, new_pack : PackedByteArray) -> void:
	character_name_master = new_name
	character_name = new_name
	unpack_byte_array(new_pack)

#crunches 8 byte arrays into 4 byte arrays
func crunch_stat_array(input_array : PackedByteArray) -> PackedByteArray:
	#just this once, I built the array manually. A joke, surely.
	var output_array : PackedByteArray = [0, 0, 0, 0]
	#a lot is happening here.
	for input_pos in range(0, StatNames.size()):
		#mod 2 is always the solution.
		var state : bool = input_pos % 2
		#carelessly shoving bits willy nilly
		var new_val : int = input_array[input_pos] << int(state) * 4
		#here's the punchline. didja get it?
		output_array[input_pos >> 1] += new_val
	return output_array
#uncrunches 4 byte arrays into 8 byte arrays
func uncrunch_stat_array(input_array : PackedByteArray) -> PackedByteArray:
	#ahhh... a blank array built right.
	var output_array : PackedByteArray = []
	#stuff happens here too. bit stuff.
	for output_pos in range(0, StatNames.size()):
		#oh hey! is that mod 2?
		var state : bool = output_pos % 2
		#this one isn't a joke.
		var crunch_val := input_array[output_pos >> 1]
		if state:
			output_array.append(crunch_val >> 4)
			continue 				#help me,
		output_array.append(crunch_val & 0b1111) #kenobi.
	return output_array 					#you're my only hope!

#packs necessary variables into 10 byte array for saving.
func pack_byte_array() -> PackedByteArray:
	#creates a packed byte array. We use these a lot in this app.
	#packed byte arrays store 8 bit bytes in in linear order. Very efficient for storage.
	#since each byte is 8 bits, that means values of 0 to 255.
	var packed_array : PackedByteArray = []
	#sets point buy mode as first bit of first byte.
	var char_data : int = int( point_buy_mode )
	#appends level value bitshifted to the second bit.
	#level values range from 1 to 20, or in bit-shift-binary, 2 to 40 with no odd numbers.
	#after all is said and done, a binary flag and an integer are fused. (range 2 - 41)
	char_data += int( character_level ) << 1
	#char_data added as byte 1
	packed_array.append(char_data)
	#backgrounds added as byte 2
	packed_array.append(backgrounds)
	#no need to save both rolled stats and point buys. We're adding 4 bytes.
	#if this is not appreciated, I can make it save both, just seems silly.
	if point_buy_mode:
		#this is optimized even more by crunching the bytes down.
		#cut from 8 bytes to 4 by storing 2 values in each byte.
		#8 total stats, cap values of 0 to 15 (good of it to be 4 bits)
		packed_array += crunch_stat_array(base_stats)
	else:
		packed_array += crunch_stat_array(roll_values)
	#4 more bytes means 10 total. This file will be pretty smol.
	packed_array += crunch_stat_array(adv_stats)
	return packed_array
#unpacks that 10 byte array and sets all local variables.
#generally just does the reverse of the pack function.
func unpack_byte_array(packed_byte_array : PackedByteArray) -> void:
	var packed_char_dat = packed_byte_array[0]
	point_buy_mode = bool(packed_char_dat & 1)
	character_level = packed_char_dat >> 1
	backgrounds = packed_byte_array[1]
	var roll_or_base_crunch : PackedByteArray = [] #2, 3, 4, 5
	var adv_crunch : PackedByteArray = [] #6, 7, 8 ,9
	for n in range(2, 6):
		roll_or_base_crunch.append(packed_byte_array[n])
		adv_crunch.append(packed_byte_array[n + 4])
	
	var roll_or_base_vals : PackedByteArray = uncrunch_stat_array(roll_or_base_crunch)
	
	for stat_name in StatNames:
		var stat_index : int = StatNames.get(stat_name)
		var packed_val : int = roll_or_base_vals[stat_index]
		if point_buy_mode:
			roll_values[stat_index] = 8
			base_stats[stat_index] = packed_val
			continue
		roll_values[stat_index] = packed_val
		set_base_stat( convert_roll_to_base(packed_val), stat_name )
	
	adv_stats = uncrunch_stat_array(adv_crunch)

#Does what it says on the box. 
func convert_roll_to_base(input : int) -> int:
	#math happens
	var output = float(input)
	output -= 10.0
	output = output / 3.0
	output = roundi(output)
	if input > 3: #I hate this part
		output += 1
	return output #good job.

#nothing of note from here. just getters and setters.
func get_point_buy_mode() -> bool:
	return point_buy_mode
func set_point_buy_mode(value : bool) -> void:
	point_buy_mode = value

#value range: 1 to 20
func get_character_level() -> int:
	return character_level
func set_character_level(value : int) -> void:
	character_level = value

#offset value range: 0 to 15
const roll_offset := 3
func get_roll_value(stat_name : String) -> int:
	var roll_value : int = roll_values[StatNames.get(stat_name)] + roll_offset
	return roll_value
func set_roll_value(value : int, stat_name : String) -> void:
	roll_values[StatNames.get(stat_name)] = value - roll_offset

#offset value range: 0 to 7
const base_offset := 2
func get_base_stat(stat_name : String) -> int:
	return base_stats[StatNames.get(stat_name)] - base_offset
func set_base_stat(value : int, stat_name : String) -> void:
	base_stats[StatNames.get(stat_name)] = value + base_offset

#Boolean returned from bit shift and bitwise &. Let me see your bits.
func get_background(stat_name : String) -> bool:
	return 1 << StatNames.get(stat_name)  & backgrounds
#Sets a single bit of the storage integer. Compare -> shift -> XOR.
func set_background(value : bool, stat_name : String) -> void:
	backgrounds = backgrounds ^ int(value != get_background(stat_name)) << StatNames.get(stat_name)

#value range: 0 to 11
func get_adv_stat(stat_name : String) -> int:
	return adv_stats[StatNames.get(stat_name)]
func set_adv_stat(value : int, stat_name : String) -> void:
	adv_stats[StatNames.get(stat_name)] = value
