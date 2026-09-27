class_name CloneTreeUI
extends RichTextLabel


@export var level_manager: LevelManager
@export var player_label: String = "@"
@export var in_progress_color: Color = Color(0.5, 0.5, 0.5)
@export var branch: String = "├─ "
@export var last_branch: String = "└─ "
@export var pipe: String = "│  "
@export var gap: String = "   "

var _last_text: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bbcode_enabled = true
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_OFF


func _process(_delta: float) -> void:
	if level_manager == null or level_manager.player == null or level_manager.max_total_clones <= 0:
		return
	var new_text := _build()
	if new_text != _last_text:
		_last_text = new_text
		text = new_text


func _build() -> String:
	var lines: PackedStringArray = []
	lines.append("clones %d/%d" % [level_manager.clone_parents.size(), level_manager.max_total_clones])
	lines.append(_format(level_manager.player, player_label))
	_append_children(level_manager.player, "", lines)
	lines.append("")
	return "\n".join(lines)


func _append_children(parent: Character, prefix: String, lines: PackedStringArray) -> void:
	var children: Array = level_manager.clone_children.get(parent, [])
	for i in children.size():
		var child: Character = children[i]
		if not is_instance_valid(child):
			continue
		var is_last := i == children.size() - 1
		lines.append(prefix + (last_branch if is_last else branch) + _format(child, str(child.clone_number)))
		_append_children(child, prefix + (gap if is_last else pipe), lines)


func _format(character: Character, label: String) -> String:
	var color := character.base_color
	var is_controlled := character == level_manager.controlled_character
	var is_in_progress := character != level_manager.player \
		and not level_manager.stored_clones.has(character)

	if is_controlled:
		label = ">" + label + "<"
	elif is_in_progress:
		color = in_progress_color

	var result := "[color=#%s]%s[/color]" % [color.to_html(false), label]
	if character.is_platform:
		result += " ="
	return result
