extends RichTextLabel

export(int) var stroke_limit = 10
export(String, "a", "b") var type = "a"

var color_name = {
	"a": "Red",
	"b": "Blue",
	}

func on_stroke_count_changed(count_a, count_b):
	var count = count_a
	if type == "b":
		count = count_b
	var coloring = "%s"
	if count > stroke_limit:
		coloring = "[color=#aa0000]%s[/color]"
	var counter = "%d/%d" % [count, stroke_limit]
	var colored_counter = coloring % counter
	bbcode_text = "[right]%s Strokes  Left:   %s[/right]" % [color_name[type], colored_counter]

func _ready():
	on_stroke_count_changed(0, 0)
