"""The hidden order: the island's hidden-wall experiment, moved onto a language-model agent.

A customer writes to an airline's support agent. Two things decide the right final action, and the agent can see
neither at the start:

  what the customer wants   cancel, change_date, add_bag or upgrade   (in the customer's head; found by asking)
  the ticket type           basic or flex                             (in the database; found by a lookup)

Basic tickets cannot be cancelled or changed, so for those two wishes the right final action is to refuse.
The customer's first message is vague on purpose: it fits two of the four wishes. This is a partially observable
decision problem (a POMDP) small enough that the exact belief after every message is known.

The agent is a local model served by Ollama. Four conditions differ only in what the model is shown each turn,
and mirror the island's three runners:

  last     only the most recent message                      (RUNNER BLIND)
  notes    the most recent message, and its own short notes   (RUNNER REMEMBERS BUMPS)
  full     the whole transcript so far                        (the usual agent)
  told     the whole transcript, and the two hidden facts     (RUNNER SEES THE WALL)

After every message a second call asks the model, with the same visible context, how likely each wish and ticket
type is. That stated belief is compared with the exact one.

    python llm/hidden_order.py --model gemma4:12b --out data/llm/hidden_order_gemma4-12b.jsonl
    python llm/hidden_order.py --selftest          # no model needed: scripted agents, checks the world's rules

Nothing leaves the machine. The customer is scripted, so every run with the same model and settings repeats.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.request
from pathlib import Path

WISHES = ["cancel", "change_date", "add_bag", "upgrade"]
TICKETS = ["basic", "flex"]
FINALS = WISHES + ["refuse"]
STEPS = ["ask_customer", "lookup_booking"] + FINALS
CONDITIONS = ["last", "notes", "full", "told"]
MAX_TURNS = 8

# The first message fits both wishes of its group and neither wish of the other group.
OPENERS = {
    0: ["Hi, something has come up and I can't fly on the 14th as booked. Can you help me sort this out?",
        "Hello, my plans for next week fell through and the flight I booked no longer works. What can we do?",
        "I have a problem with the date of my flight, I won't be able to take it as it stands. Can you help?"],
    1: ["Hi, I'd like to get a bit more out of my booking for next week's flight. Can you help?",
        "Hello, I want to add something to the flight I already booked. Is that possible?",
        "I'm thinking of making my trip next week more comfortable. Can you set something up on my booking?"],
}
GROUP = {"cancel": 0, "change_date": 0, "add_bag": 1, "upgrade": 1}
ANSWERS = {
    "cancel": "I want to cancel the flight altogether and get my money back.",
    "change_date": "I want to keep the trip but move the flight to a different date.",
    "add_bag": "I want to add one checked bag to the booking.",
    "upgrade": "I want to upgrade my seat to the next cabin.",
}

RULES = """You are a support agent for an airline. A customer has written in. Choose ONE next step.

Rules of the job:
- The customer wants exactly one of four things: cancel (cancel the flight for a refund), change_date (move the flight), add_bag (add a checked bag), upgrade (a better seat).
- Basic tickets cannot be cancelled or changed. If that is what the customer wants and the ticket is basic, the correct final step is refuse.
- Flex tickets can be cancelled or changed. Bags and upgrades are allowed on any ticket.
- You do not know the ticket type until you look the booking up.
- A final step cannot be undone. A wrong final step is much worse than asking or looking up first. Extra steps cost a little time.

Steps you can take:
- ask_customer: ask the customer what exactly they want.
- lookup_booking: read the ticket type from the booking system.
- a final step: cancel, change_date, add_bag, upgrade or refuse.
"""


def allowed(wish: str, ticket: str) -> bool:
    return ticket == "flex" or wish in ("add_bag", "upgrade")


def right_final(wish: str, ticket: str) -> str:
    return wish if allowed(wish, ticket) else "refuse"


def needs_lookup(wish: str) -> bool:
    return wish in ("cancel", "change_date")


def fewest_steps(wish: str, ticket: str) -> int:
    """Steps the best plan takes in this case. For a "can't fly as booked" opener the best first step is the lookup:
    a basic ticket ends it (refuse, 2 steps), a flex ticket needs the question too (3). Asking first always takes 3.
    For an "add something" opener the ticket never matters: ask, then act (2)."""
    if not needs_lookup(wish):
        return 2
    return 2 if ticket == "basic" else 3


class World:
    """One conversation. The hidden facts are fixed at the start; step() returns what the agent can observe."""

    def __init__(self, wish: str, ticket: str, phrasing: int):
        self.wish, self.ticket, self.phrasing = wish, ticket, phrasing
        self.asked = self.looked = False
        self.transcript = [("Customer", OPENERS[GROUP[wish]][phrasing])]
        self.done, self.final = False, None

    def exact_belief(self) -> dict:
        """What someone who remembered everything said so far, and nothing else, should believe."""
        if self.asked:
            wishes = {w: 1.0 if w == self.wish else 0.0 for w in WISHES}
        else:
            wishes = {w: 0.5 if GROUP[w] == GROUP[self.wish] else 0.0 for w in WISHES}
        flex = (1.0 if self.ticket == "flex" else 0.0) if self.looked else 0.5
        return {"wish": wishes, "flex": flex}

    def enough_known(self) -> bool:
        """True when the transcript so far settles the right final step: every wish and ticket type still possible
        leads to the same one. A basic ticket settles a "can't fly as booked" opener by itself (refuse either way)."""
        b = self.exact_belief()
        tickets = [t for t in TICKETS if (b["flex"] > 0 if t == "flex" else b["flex"] < 1)]
        return len({right_final(w, t) for w in WISHES if b["wish"][w] > 0 for t in tickets}) == 1

    def step(self, step: str) -> str:
        if step == "ask_customer":
            said = ANSWERS[self.wish] if not self.asked else "As I said: " + ANSWERS[self.wish]
            self.asked = True
            self.transcript += [("You", "(asked the customer what exactly they want)"), ("Customer", said)]
            return said
        if step == "lookup_booking":
            self.looked = True
            said = f"The ticket type is {self.ticket.upper()}."
            self.transcript += [("You", "(looked the booking up)"), ("Booking system", said)]
            return said
        self.done, self.final = True, step
        return ""

    def last_message(self) -> str:
        who, text = self.transcript[-1]
        return f"{who}: {text}"

    def full_text(self) -> str:
        return "\n".join(f"{who}: {text}" for who, text in self.transcript)


def visible(world: World, condition: str, notes: str) -> str:
    if condition == "last":
        return "This is the only thing you can see. You have no memory of earlier turns.\n\nLatest message:\n" + world.last_message()
    if condition == "notes":
        return ("You have no memory of earlier turns except the notes you wrote yourself.\n\nYour notes so far:\n" + (notes or "(none yet)")
                + "\n\nLatest message:\n" + world.last_message())
    text = "The conversation so far:\n" + world.full_text()
    if condition == "told":
        text += f"\n\nKnown for certain (you have been told): the customer wants {world.wish}, and the ticket type is {world.ticket.upper()}."
    return text


def ollama(base: str, model: str, system: str, user: str, schema: dict, timeout: int = 180) -> dict:
    body = {"model": model, "stream": False, "format": schema, "think": False, "options": {"temperature": 0, "num_ctx": 4096, "seed": 7},
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]}
    req = urllib.request.Request(base + "/api/chat", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        out = json.loads(r.read())
    return json.loads(out["message"]["content"])


def act_schema(condition: str) -> dict:
    props = {"reason": {"type": "string"}, "step": {"type": "string", "enum": STEPS}}
    req = ["reason", "step"]
    if condition == "notes":
        props = {"notes": {"type": "string"}, **props}
        req = ["notes"] + req
    return {"type": "object", "properties": props, "required": req}


BELIEF_SCHEMA = {"type": "object", "required": WISHES + ["flex"],
                 "properties": {**{w: {"type": "number"} for w in WISHES}, "flex": {"type": "number"}}}


def model_agent(base: str, model: str):
    def agent(world: World, condition: str, notes: str):
        ask = ("Reply in JSON. " + ('"notes": everything worth remembering for your next turn, in under 40 words (it is all you will have). ' if condition == "notes" else "")
               + '"reason": one short sentence. "step": the one step you take now.')
        out = ollama(base, model, RULES, visible(world, condition, notes) + "\n\n" + ask, act_schema(condition))
        return out.get("step"), out.get("notes", ""), out.get("reason", "")

    def belief(world: World, condition: str, notes: str):
        ask = ("Do not take a step. From what you can see above, how likely is each thing the customer might want, and how likely is it that the ticket is flex? "
               "Reply in JSON with a number from 0 to 100 for each of: cancel, change_date, add_bag, upgrade (these four should sum to 100), and flex (0 to 100).")
        out = ollama(base, model, RULES, visible(world, condition, notes) + "\n\n" + ask, BELIEF_SCHEMA)
        vals = [max(0.0, float(out.get(w, 0))) for w in WISHES]
        tot = sum(vals) or 1.0
        return {"wish": {w: v / tot for w, v in zip(WISHES, vals)}, "flex": min(1.0, max(0.0, float(out.get("flex", 50)) / 100))}
    return agent, belief


def belief_error(stated: dict, exact: dict) -> dict:
    """Total variation distance on the wish (0 = same, 1 = all weight in the wrong place), and the gap on P(flex)."""
    return {"wish": 0.5 * sum(abs(stated["wish"][w] - exact["wish"][w]) for w in WISHES), "flex": abs(stated["flex"] - exact["flex"])}


def run_episode(agent, belief, wish: str, ticket: str, phrasing: int, condition: str) -> dict:
    world, notes, turns = World(wish, ticket, phrasing), "", []
    while not world.done and len(turns) < MAX_TURNS:
        exact = world.exact_belief()
        stated = belief(world, condition, notes) if belief else None
        enough = world.enough_known()
        step, new_notes, reason = agent(world, condition, notes)
        if step not in STEPS:
            step = "ask_customer"
        seen = world.last_message()
        said = world.step(step)
        turns.append({"saw": seen, "notes_in": notes, "step": step, "reason": reason, "reply": said, "exact": exact, "stated": stated,
                      "err": belief_error(stated, exact) if stated else None, "enough_known_before": enough})
        if condition == "notes":
            notes = (new_notes or "")[:400]
    right = right_final(wish, ticket)
    outcome = "no final step" if not world.done else ("right" if world.final == right else "wrong")
    return {"condition": condition, "wish": wish, "ticket": ticket, "phrasing": phrasing, "right_final": right, "final": world.final, "outcome": outcome,
            "turns": len(turns), "asks": sum(t["step"] == "ask_customer" for t in turns), "lookups": sum(t["step"] == "lookup_booking" for t in turns),
            "premature": bool(world.done and not turns[-1]["enough_known_before"] and condition != "told"),
            "repeat_steps": max(0, sum(t["step"] == "ask_customer" for t in turns) - 1) + max(0, sum(t["step"] == "lookup_booking" for t in turns) - 1),
            "fewest_steps": 1 if condition == "told" else fewest_steps(wish, ticket), "steps": turns}


# ---- scripted agents, for the self-test: no model needed -------------------------------------------------------
def perfect_agent(world: World, condition: str, notes: str):
    """The best plan: take the step that can settle the most, and stop as soon as the right final step is settled."""
    if condition == "told" or world.enough_known():
        return right_final(world.wish, world.ticket), "", ""
    if GROUP[world.wish] == 0 and not world.looked:
        return "lookup_booking", "", ""
    return "ask_customer", "", ""


def memoryless_agent(world: World, condition: str, notes: str):
    """Acts on the latest message alone, by a fixed rule: the best a reader with no memory and no guessing can do."""
    who, text = world.transcript[-1]
    if who == "Booking system":
        return "ask_customer", "", ""              # knows the ticket, has forgotten the wish
    for w, a in ANSWERS.items():
        if a in text:
            return ("lookup_booking" if needs_lookup(w) else w), "", ""    # knows the wish, has forgotten the ticket
    return ("lookup_booking" if text in OPENERS[0] else "ask_customer"), "", ""


def selftest() -> int:
    cases = [(w, t, p) for w in WISHES for t in TICKETS for p in range(3)]
    for c in CONDITIONS:
        eps = [run_episode(perfect_agent, None, w, t, p, c) for w, t, p in cases]
        assert all(e["outcome"] == "right" and e["turns"] == e["fewest_steps"] and not e["premature"] for e in eps), c
    eps = [run_episode(memoryless_agent, None, w, t, p, "last") for w, t, p in cases]
    bags = [e for e in eps if not needs_lookup(e["wish"])]
    loops = [e for e in eps if needs_lookup(e["wish"])]
    assert all(e["outcome"] == "right" and e["turns"] == 2 for e in bags)
    assert all(e["outcome"] == "no final step" and e["turns"] == MAX_TURNS for e in loops), "a memoryless reader can never hold both facts at once"
    w = World("cancel", "basic", 0)
    assert not w.enough_known()
    w.step("lookup_booking")
    assert w.enough_known() and fewest_steps("cancel", "basic") == 2 and fewest_steps("cancel", "flex") == 3 and fewest_steps("upgrade", "basic") == 2
    w = World("change_date", "flex", 1); w.step("lookup_booking")
    assert not w.enough_known()
    w = World("cancel", "basic", 0)
    assert w.exact_belief() == {"wish": {"cancel": 0.5, "change_date": 0.5, "add_bag": 0.0, "upgrade": 0.0}, "flex": 0.5}
    w.step("ask_customer"); w.step("lookup_booking")
    assert w.exact_belief() == {"wish": {"cancel": 1.0, "change_date": 0.0, "add_bag": 0.0, "upgrade": 0.0}, "flex": 0.0} and right_final("cancel", "basic") == "refuse"
    assert belief_error({"wish": {"cancel": 1, "change_date": 0, "add_bag": 0, "upgrade": 0}, "flex": 1.0}, World("upgrade", "flex", 0).exact_belief()) == {"wish": 1.0, "flex": 0.5}
    print(f"selftest passed: {len(cases)} cases x {len(CONDITIONS)} conditions with the scripted perfect agent; the memoryless reader loops on {len(loops)} of {len(cases)}")
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--model", default="gemma4:12b")
    ap.add_argument("--base", default="http://127.0.0.1:11434")
    ap.add_argument("--out", default="")
    ap.add_argument("--conditions", default=",".join(CONDITIONS))
    ap.add_argument("--no-belief", action="store_true", help="skip the second call that asks the model for its belief")
    ap.add_argument("--limit", type=int, default=0, help="only the first N cases per condition (smoke test)")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args(argv)
    if a.selftest:
        return selftest()
    if not a.out:
        ap.error("--out is required")
    agent, belief = model_agent(a.base, a.model)
    cases = [(w, t, p) for p in range(3) for w in WISHES for t in TICKETS]
    if a.limit:
        cases = cases[:a.limit]
    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    done = set()
    if out.exists():           # resume: a run that was interrupted picks up where it stopped
        for line in out.read_text().splitlines():
            e = json.loads(line)
            done.add((e["condition"], e["wish"], e["ticket"], e["phrasing"]))
    t0, n = time.time(), 0
    with out.open("a") as f:
        for c in a.conditions.split(","):
            for w, t, p in cases:
                if (c, w, t, p) in done:
                    continue
                try:
                    e = run_episode(agent, None if a.no_belief else belief, w, t, p, c)
                except Exception as err:        # a failed call is reported and stops the run; it is never scored as a result
                    print(f"FAIL: {c} {w} {t} {p}: {err!r}", file=sys.stderr)
                    return 1
                e["model"] = a.model
                f.write(json.dumps(e) + "\n"); f.flush()
                n += 1
                print(f"{c:6s} {w:12s} {t:5s} #{p}  {e['outcome']:14s} {e['turns']} turns  ({time.time() - t0:.0f}s)", flush=True)
    print(f"done: {n} new episodes in {time.time() - t0:.0f}s -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
