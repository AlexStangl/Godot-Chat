extends RichTextLabel

var parent_node

func _ready():
	parent_node = get_parent()
	
	if parent_node.get_class() == "Panel":
		parent_node.connect("resized", self, "_panel_resized")
		_panel_resized()

func _panel_resized():
	margin_top = 0
	margin_left = 0
	margin_bottom = parent_node.margin_bottom - parent_node.margin_top
	margin_right = parent_node.margin_right - parent_node.margin_left