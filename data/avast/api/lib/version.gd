extends RefCounted

static func compare(a: String, b: String) -> int:
	var pa := _split(a)
	var pb := _split(b)
	for i in maxi(pa.numbers.size(), pb.numbers.size()):
		var x: int = pa.numbers[i] if i < pa.numbers.size() else 0
		var y: int = pb.numbers[i] if i < pb.numbers.size() else 0
		if x != y:
			return 1 if x > y else -1
	if pa.pre == pb.pre:
		return 0
	if pa.pre.is_empty() or pb.pre.is_empty():
		return 1 if pa.pre.is_empty() else -1
	var ia: PackedStringArray = pa.pre.split(".")
	var ib: PackedStringArray = pb.pre.split(".")
	for i in mini(ia.size(), ib.size()):
		if ia[i] == ib[i]:
			continue
		if ia[i].is_valid_int() and ib[i].is_valid_int():
			return 1 if ia[i].to_int() > ib[i].to_int() else -1
		return 1 if ia[i] > ib[i] else -1
	return 1 if ia.size() > ib.size() else -1

static func at_least(version: String, minimum: String) -> bool:
	return compare(version, minimum) >= 0

static func _split(v: String) -> Dictionary:
	v = v.strip_edges().trim_prefix("v").trim_prefix("V").get_slice("+", 0)
	var pre := v.get_slice("-", 1) if v.contains("-") else ""
	var numbers: Array[int] = []
	for part in v.get_slice("-", 0).split("."):
		numbers.append(part.to_int())
	return {"numbers": numbers, "pre": pre}
