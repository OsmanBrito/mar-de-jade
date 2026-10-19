extends RefCounted
## Bounded transcript: only displayed lines, carried by the campaign save.
const LIMIT := 200
static func valid(value: Variant) -> bool:
 if not value is Array or value.size()>LIMIT: return false
 for row in value:
  if not row is Dictionary or row.size()!=2: return false
  if not row.get("speaker") is String or not row.get("text") is String: return false
  if row.speaker.is_empty() or row.speaker.length()>120 or row.text.is_empty() or row.text.length()>8000: return false
 return true
static func remember(p, who: String, words: String) -> void:
 var row := {"speaker":who,"text":words}
 if not valid([row]): return
 if not p.dialogue_history.is_empty() and p.dialogue_history.back()==row: return
 p.dialogue_history.append(row)
 if p.dialogue_history.size()>LIMIT: p.dialogue_history.pop_front()
