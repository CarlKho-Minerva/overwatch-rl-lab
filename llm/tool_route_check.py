"""Does the model get to see the result of its own tool call? A four-message check against a local Ollama server.

    python llm/tool_route_check.py --model gemma4:12b --out data/llm/tool_route_check.json

Found on 2026-11-22: a tau-bench airline task run through one adapter scored 0 because the agent made the same lookup
19 times. The size of its prompt, as counted by the server, had stopped growing. This check isolates why. The same
short conversation is sent in two forms:

  dropped   the agent's tool call reduced to an empty assistant message, the result sent as a bare tool message
            (what that adapter produced);
  kept      the tool call kept on the assistant message and the result named after the tool (the server's own form).

For each form it records how many prompt tokens the server read and what the model did next. If the result is not
reaching the model, the prompt does not grow when the result is added, and the model repeats the lookup.
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.request
from pathlib import Path

TOOLS = [{"type": "function", "function": {"name": "get_user_details", "description": "Get user details", "parameters": {"type": "object", "properties": {"user_id": {"type": "string"}}, "required": ["user_id"]}}},
         {"type": "function", "function": {"name": "get_reservation_details", "description": "Get reservation details", "parameters": {"type": "object", "properties": {"reservation_id": {"type": "string"}}, "required": ["reservation_id"]}}}]
SYSTEM = {"role": "system", "content": "You are an airline agent. Use the tools to look things up before answering. The customer's trip is the reservation that goes from Philadelphia to LaGuardia."}
USER = {"role": "user", "content": "My user ID is raj_sanchez_7340. Please look at my Philadelphia to LaGuardia reservation."}
RESULT = json.dumps({"user_id": "raj_sanchez_7340", "reservations": ["Q69X3R", "ZZ77TT"], "membership": "silver"})


def chat(base, model, messages):
    body = {"model": model, "stream": False, "options": {"temperature": 0, "seed": 7}, "messages": messages, "tools": TOOLS}
    req = urllib.request.Request(base + "/api/chat", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    out = json.loads(urllib.request.urlopen(req, timeout=300).read())
    m = out["message"]
    calls = [f"{t['function']['name']}({json.dumps(t['function']['arguments'])})" for t in m.get("tool_calls", [])]
    return {"prompt_tokens": out.get("prompt_eval_count"), "next": calls[0] if calls else "says: " + (m.get("content") or "")[:120]}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--model", default="gemma4:12b")
    ap.add_argument("--base", default="http://127.0.0.1:11434")
    ap.add_argument("--out", default="")
    a = ap.parse_args(argv)
    dropped = [{"role": "assistant", "content": ""}, {"role": "tool", "content": RESULT}]
    kept = [{"role": "assistant", "content": "", "tool_calls": [{"function": {"name": "get_user_details", "arguments": {"user_id": "raj_sanchez_7340"}}}]},
            {"role": "tool", "tool_name": "get_user_details", "content": RESULT}]
    try:
        R = {"model": a.model,
             "before_any_call": chat(a.base, a.model, [SYSTEM, USER]),
             "dropped_once": chat(a.base, a.model, [SYSTEM, USER] + dropped),
             "dropped_three_times": chat(a.base, a.model, [SYSTEM, USER] + dropped * 3),
             "kept_once": chat(a.base, a.model, [SYSTEM, USER] + kept)}
    except Exception as err:
        print(f"FAIL: {err!r}", file=sys.stderr)
        return 1
    R["result_reached_the_model_when_dropped"] = R["dropped_once"]["prompt_tokens"] - R["before_any_call"]["prompt_tokens"] > 20
    R["result_reached_the_model_when_kept"] = R["kept_once"]["prompt_tokens"] - R["before_any_call"]["prompt_tokens"] > 20
    R["repeats_the_lookup_when_dropped"] = R["dropped_once"]["next"] == R["before_any_call"]["next"]
    R["moves_on_when_kept"] = R["kept_once"]["next"] != R["before_any_call"]["next"]
    for k in ("before_any_call", "dropped_once", "dropped_three_times", "kept_once"):
        print(f"{k:22s} prompt tokens {R[k]['prompt_tokens']:5d}   next: {R[k]['next']}")
    if a.out:
        Path(a.out).write_text(json.dumps(R, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
