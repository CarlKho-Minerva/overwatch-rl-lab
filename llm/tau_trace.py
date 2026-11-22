"""Trim one tau-bench simulation (tau2-bench results.json) to the lines a reader needs, tagged as a POMDP.

    python llm/tau_trace.py <results.json> <out.json>

Each line of the conversation becomes one record: who spoke, what was said or which tool was called, and a tag:
  observation   a customer message or a tool result (the only way the agent learns anything)
  ask           the agent said something to the customer (a question or an answer)
  lookup        the agent called a tool that only reads
  act           the agent called a tool that changes the database (cannot be undone)
The task's hidden instructions and its end-of-task check are copied from the task itself, so the page can show what
the agent was never shown. Nothing is judged here beyond what the benchmark's own reward says.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

READS = ("get_", "list_", "search_", "calculate", "think", "find_")


def trim(results_path: Path) -> dict:
    d = json.loads(results_path.read_text())
    if not d.get("simulations"):
        raise SystemExit("FAIL: the results file holds no finished simulation")
    sim, task = d["simulations"][0], d["tasks"][0]
    lines, cur = [], 0
    for m in sim["messages"]:
        role, text, calls = m.get("role"), (m.get("content") or "").strip(), m.get("tool_calls") or []
        if role == "user" and text:
            lines.append({"who": "customer", "tag": "observation", "text": text})
        elif role == "assistant":
            if text:
                lines.append({"who": "agent", "tag": "ask", "text": text})
            for c in calls:
                name = c.get("name", "")
                args = json.dumps(c.get("arguments", {}), ensure_ascii=False)
                lines.append({"who": "agent", "tag": "lookup" if name.startswith(READS) else "act", "text": f"{name}({args})"})
        elif role == "tool":
            lines.append({"who": "system", "tag": "observation", "text": text[:700] + (" ..." if len(text) > 700 else "")})
    # how large the agent's prompt was on each of its calls: a prompt that stops growing while the conversation
    # gets longer means the server is cutting the conversation to fit its context window
    prompt_tokens = [m["usage"]["prompt_tokens"] for m in sim["messages"] if m.get("role") == "assistant" and (m.get("usage") or {}).get("prompt_tokens")]
    repeats, prev = 0, None
    for x in lines:                      # the longest run of one identical lookup
        if x["tag"] == "lookup":
            cur = cur + 1 if x["text"] == prev else 1
            prev, repeats = x["text"], max(repeats, cur)
        elif x["who"] != "system":
            prev, cur = None, 0
    ins = task["user_scenario"]["instructions"]
    ri = sim.get("reward_info") or {}
    return {"task_id": task["id"], "domain": ins.get("domain"), "purpose": (task.get("description") or {}).get("purpose"),
            "hidden": {"reason_for_call": ins.get("reason_for_call"), "task_instructions": ins.get("task_instructions"), "known_info": ins.get("known_info")},
            "checked_at_the_end": {"nl_assertions": task["evaluation_criteria"].get("nl_assertions"), "expected_actions": [a["name"] for a in task["evaluation_criteria"].get("actions") or []],
                                   "reward_basis": task["evaluation_criteria"].get("reward_basis")},
            "agent_model": (d["info"].get("agent_info") or {}).get("llm"), "user_model": (d["info"].get("user_info") or {}).get("llm"),
            "reward": ri.get("reward"), "db_match": (ri.get("db_check") or {}).get("db_match"), "termination": sim.get("termination_reason"),
            "seconds": sim.get("duration"), "agent_prompt_tokens": prompt_tokens, "longest_repeat_of_one_lookup": repeats,
            "agent_llm_args": (d["info"].get("agent_info") or {}).get("llm_args"), "acts": [x["text"] for x in lines if x["tag"] == "act"], "lines": lines}


if __name__ == "__main__":
    out = trim(Path(sys.argv[1]))
    Path(sys.argv[2]).write_text(json.dumps(out, ensure_ascii=False, indent=1))
    print(f"task {out['task_id']}: reward {out['reward']}, {len(out['lines'])} lines, tool calls that are not lookups: {out["acts"] or "none"}, ended by {out['termination']}, "
          f"longest repeat of one lookup {out['longest_repeat_of_one_lookup']}, agent prompt tokens {out['agent_prompt_tokens'][:3]} ... {out['agent_prompt_tokens'][-2:]}")
