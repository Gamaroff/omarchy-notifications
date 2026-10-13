// node --test
const test = require("node:test")
const assert = require("node:assert")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "../lib/Mute.js"), "utf8")
function load() {
  const Mute = vm.createContext({})
  vm.runInContext(source.replace(/^\.pragma library$/m, ""), Mute)
  return Mute
}

const claude = { app: "", summary: "Claude Code", body: "Claude is waiting for your input" }
const slack = { app: "Slack", summary: "Ana", body: "lunch?" }

test("rules split on semicolons, trimmed, lowercased, blanks dropped", () => {
  const Mute = load()
  assert.deepStrictEqual(Array.from(Mute.parse(" Waiting For Input ;; Update ; ")), ["waiting for input", "update"])
  assert.deepStrictEqual(Array.from(Mute.parse("")), [])
  assert.deepStrictEqual(Array.from(Mute.parse(undefined)), [])
})

test("a rule matches app, summary or body, ignoring case", () => {
  const Mute = load()
  assert.ok(Mute.isMuted(claude, Mute.parse("is waiting for your INPUT")))
  assert.ok(Mute.isMuted(claude, Mute.parse("claude code")))
  assert.ok(Mute.isMuted(slack, Mute.parse("slack")))
  assert.ok(!Mute.isMuted(slack, Mute.parse("claude")))
})

test("no rules mutes nothing", () => {
  const Mute = load()
  assert.ok(!Mute.isMuted(claude, []))
  assert.ok(!Mute.isMuted(claude, null))
})

test("filter drops muted entries and keeps the order of the rest", () => {
  const Mute = load()
  const kept = Mute.filter([claude, slack, claude], Mute.parse("waiting for your input"))
  assert.deepStrictEqual(Array.from(kept), [slack])
})
