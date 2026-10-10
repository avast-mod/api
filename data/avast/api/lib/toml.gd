extends RefCounted

var _s: String
var _i := 0

static func parse(text: String) -> Dictionary:
	var parser := new()
	parser._s = text.replace("\r\n", "\n")
	return parser._document()

func _document() -> Dictionary:
	var root := {}
	var table := root
	while _i < _s.length():
		_skip_blank_and_comments()
		if _i >= _s.length():
			break
		if _peek() == "[":
			var array_table := _s.substr(_i, 2) == "[["
			_i += 2 if array_table else 1
			var path := _key_path()
			_skip_spaces()
			_i += 2 if array_table else 1
			table = _open_table(root, path, array_table)
		else:
			var path := _key_path()
			_skip_spaces()
			if _peek() != "=":
				return root
			_i += 1
			_skip_spaces()
			var target := _open_table(table, path.slice(0, -1), false)
			target[path[-1]] = _value()
		_skip_line()
	return root

func _open_table(root: Dictionary, path: Array, array_table: bool) -> Dictionary:
	var node := root
	for i in path.size():
		var key: String = path[i]
		var last := i == path.size() - 1
		if last and array_table:
			if not node.get(key) is Array:
				node[key] = []
			node[key].append({})
			return node[key][-1]
		if node.get(key) is Array and not node[key].is_empty():
			node = node[key][-1]
		else:
			if not node.get(key) is Dictionary:
				node[key] = {}
			node = node[key]
	return node

func _key_path() -> Array:
	var path := []
	while true:
		_skip_spaces()
		var c := _peek()
		if c == "\"" or c == "'":
			path.append(_string())
		else:
			var start := _i
			while _i < _s.length() and (_peek().is_valid_identifier() or _peek() == "-" or _peek().is_valid_int()):
				_i += 1
			path.append(_s.substr(start, _i - start))
		_skip_spaces()
		if _peek() != ".":
			return path
		_i += 1
	return path

func _value() -> Variant:
	var c := _peek()
	if c == "\"" or c == "'":
		return _string()
	if c == "[":
		_i += 1
		var out := []
		while true:
			_skip_blank_and_comments()
			if _peek() == "]" or _i >= _s.length():
				_i += 1
				return out
			var before := _i
			out.append(_value())
			if _i == before:
				_i += 1
			_skip_blank_and_comments()
			if _peek() == ",":
				_i += 1
	if c == "{":
		_i += 1
		var out := {}
		while true:
			_skip_spaces()
			if _peek() == "}" or _i >= _s.length():
				_i += 1
				return out
			var before := _i
			var path := _key_path()
			_skip_spaces()
			if _peek() != "=" or _i == before:
				_i += 1
				continue
			_i += 1
			_skip_spaces()
			_open_table(out, path.slice(0, -1), false)[path[-1]] = _value()
			_skip_spaces()
			if _peek() == ",":
				_i += 1
	var start := _i
	while _i < _s.length() and not _peek() in [",", "]", "}", "\n", "#"]:
		_i += 1
	var raw := _s.substr(start, _i - start).strip_edges()
	match raw:
		"true":
			return true
		"false":
			return false
		"inf", "+inf":
			return INF
		"-inf":
			return -INF
	var number := raw.replace("_", "")
	if number.is_valid_int():
		return number.to_int()
	if number.begins_with("0x"):
		return number.hex_to_int()
	if number.is_valid_float():
		return number.to_float()
	return raw

func _string() -> String:
	var quote := _peek()
	var multi := _s.substr(_i, 3) == quote.repeat(3)
	_i += 3 if multi else 1
	if multi and _peek() == "\n":
		_i += 1
	var out := ""
	while _i < _s.length():
		var c := _peek()
		if multi and _s.substr(_i, 3) == quote.repeat(3):
			_i += 3
			return out
		if not multi and (c == quote or c == "\n"):
			_i += 1
			return out
		if c == "\\" and quote == "\"":
			_i += 1
			var e := _peek()
			match e:
				"n": out += "\n"
				"t": out += "\t"
				"r": out += "\r"
				"\"": out += "\""
				"\\": out += "\\"
				"u", "U":
					var digits := 4 if e == "u" else 8
					out += char(_s.substr(_i + 1, digits).hex_to_int())
					_i += digits
				"\n":
					while _i + 1 < _s.length() and _s[_i + 1] in [" ", "\t", "\n"]:
						_i += 1
				_: out += e
			_i += 1
			continue
		out += c
		_i += 1
	return out

func _peek() -> String:
	return _s[_i] if _i < _s.length() else ""

func _skip_spaces() -> void:
	while _peek() == " " or _peek() == "\t":
		_i += 1

func _skip_blank_and_comments() -> void:
	while _i < _s.length():
		var c := _peek()
		if c == " " or c == "\t" or c == "\n":
			_i += 1
		elif c == "#":
			_skip_line()
		else:
			return

func _skip_line() -> void:
	while _i < _s.length() and _peek() != "\n":
		_i += 1
