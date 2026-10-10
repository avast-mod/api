extends RefCounted

const _SELECT_LIGHT := Color(0, 0.2766668, 0.83)
const _CODE_LIGHT := {
	"comment": "6e7781", "string": "0a3069", "number": "0550ae", "keyword": "cf222e",
	"section": "8250df", "added": "116329", "removed": "82071e",
}
const _CODE_DARK := {
	"comment": "9aa39a", "string": "a5d6ff", "number": "79c0ff", "keyword": "ff8f87",
	"section": "d2a8ff", "added": "7ee787", "removed": "ffa198",
}

static func current() -> Dictionary:
	var theme: Resource = AppearanceManager.active_theme
	var body: Color = theme.window_body_color if theme != null else Color(0.95, 0.94, 0.85)
	var border: Color = theme.panel_border_color if theme != null else Color(0.67, 0.67, 0.52)
	var accent: Color = theme.group_title_color if theme != null else Color(0, 0.275, 0.67)
	var label: Color = theme.label_color if theme != null else Color(0.05, 0, 0.1, 0.77)
	var dark := body.get_luminance() < 0.5
	var field := body.darkened(0.38) if dark else Color.WHITE
	var text := Color(label, 1.0).lerp(Color.WHITE, 0.1) if dark else Color(0.12, 0.13, 0.16)
	return {
		"dark": dark,
		"body": body,
		"field": field,
		"border": border.lightened(0.12) if dark else border,
		"text": text,
		"muted": text.lerp(field, 0.42),
		"link": Color(0.55, 0.76, 1.0) if dark else Color(0.0, 0.33, 0.8),
		"line": field.lightened(0.16) if dark else Color(0.82, 0.84, 0.87),
		"code_back": field.lightened(0.07) if dark else Color(0.95, 0.96, 0.97),
		"select": accent.darkened(0.45) if dark else _SELECT_LIGHT,
		"select_text": Color.WHITE,
		"accent": accent,
		"hover": Color(1, 1, 1, 0.12) if dark else Color(1, 1, 1, 0.35),
		"picked": Color(1, 1, 1, 0.2) if dark else Color(1, 1, 1, 0.6),
		"code": _CODE_DARK if dark else _CODE_LIGHT,
	}

static func readable(color: Color, palette: Dictionary) -> Color:
	return color.lightened(0.35) if palette.dark else color

static func box(back: Color, border: Color, width: int = 1, padding: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = back
	style.border_color = border
	style.set_border_width_all(width)
	style.set_content_margin_all(padding)
	return style
