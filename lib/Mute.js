.pragma library

// Muted notifications.
//
// A rule is a piece of text; a notification is muted when any rule appears,
// ignoring case, in its app name, summary or body. Rules are separated by
// semicolons, so one setting line holds as many as needed:
//
//   Claude is waiting for your input; Software update
//
// Muting hides a notification from the panel, the count and the bell. It stays
// in the archive, so removing the rule brings it back.

function parse(text) {
  var rules = []
  var parts = String(text || "").split(";")
  for (var i = 0; i < parts.length; i++) {
    var rule = parts[i].trim().toLowerCase()
    if (rule !== "") rules.push(rule)
  }
  return rules
}

function isMuted(entry, rules) {
  if (!entry || !rules || rules.length === 0) return false
  var haystack = [entry.app, entry.summary, entry.body]
    .map(function(part) { return String(part || "") })
    .join("\n")
    .toLowerCase()
  for (var i = 0; i < rules.length; i++)
    if (haystack.indexOf(rules[i]) !== -1) return true
  return false
}

function filter(entries, rules) {
  if (!rules || rules.length === 0) return entries
  return entries.filter(function(entry) { return !isMuted(entry, rules) })
}
