"""Play the customer yourself against a local model, and watch what it believes turn by turn.

    python llm/live.py --model gemma4:12b --port 8811
    open http://127.0.0.1:8811

Same world as hidden_order.py: you want one of four things and hold a basic or flex ticket; the agent is told neither.
You choose what the agent is shown each turn (only your latest message, your latest message and its own notes, or the
whole conversation) and type as the customer in your own words. Before every step the model is asked, with exactly
the context it has, how likely each wish and ticket type is; the page draws that as bars.

The model runs in Ollama on this machine. The server answers only two paths (the page and one JSON call), keeps no
state between calls and writes nothing to disk.
"""
from __future__ import annotations

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hidden_order as ho  # noqa: E402

PAGE = r"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The hidden order, live</title><style>
:root{--bg:#141310;--panel:#1d1b17;--ink:#f4eee3;--muted:#c3bbad;--line:#484239;--grid:#2c2924;--mono:ui-monospace,SFMono-Regular,Consolas,monospace}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.55 system-ui,-apple-system,sans-serif}main{max-width:720px;margin:auto;padding:22px 16px 80px}
h1{font-size:28px;line-height:1.15;margin:6px 0 10px}p{margin:0 0 12px}.k{font:13px/1.5 var(--mono);color:var(--muted)}
.btn{display:inline-block;background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:9px 13px;color:var(--ink);font:inherit;margin:4px 6px 4px 0}
.btn.on{border-color:var(--ink)}.btn.go{background:#2b2618;border-color:#8a6d3b}.card{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:12px 14px;margin:10px 0}
.me{border-color:#3c4a3f;background:#1f2420}.bar{height:16px;border-radius:5px;background:var(--grid);overflow:hidden;flex:1}.bar i{display:block;height:100%;background:#6fb3ff}
.row{display:flex;align-items:center;gap:8px;font:13px var(--mono);color:var(--muted);margin:3px 0}.row span:first-child{width:96px}.row span:last-child{width:38px;text-align:right}
textarea{width:100%;min-height:64px;background:var(--panel);color:var(--ink);border:1px solid var(--line);border-radius:10px;padding:10px;font:inherit}[hidden]{display:none!important}
</style></head><body><main>
<div class="k">the hidden order · live · model __MODEL__ on this Mac</div>
<h1>You are the customer. The agent cannot see what you want.</h1>
<div id="setup">
<p>Pick what you really want and your ticket type. The agent is told neither. Then pick how much the agent is shown each turn.</p>
<p class="k">what you want</p><div id="s-wish"></div>
<p class="k">your ticket</p><div id="s-ticket"></div>
<p class="k">each turn the agent is shown</p><div id="s-cond"></div>
<p class="k">your first message (say it vaguely, the way a customer would)</p>
<textarea id="s-open"></textarea>
<p><button class="btn go" id="s-go">Start</button></p>
</div>
<div id="chat" hidden>
<div id="log"></div>
<div id="reply" hidden><textarea id="r-text" placeholder="Answer as the customer, in your own words"></textarea><p><button class="btn go" id="r-send">Send</button></p></div>
<p class="k" id="status"></p>
<p><button class="btn" id="again" hidden>Play again</button></p>
</div>
<script>
(function(){
var WISH={cancel:"cancel for a refund",change_date:"move to another date",add_bag:"add a checked bag",upgrade:"upgrade the seat"};
var COND={last:"only my latest message",notes:"my latest message and its own notes",full:"the whole conversation"};
var OPEN={cancel:"Hi, something has come up and I can't fly on the 14th as booked. Can you help?",change_date:"Hi, something has come up and I can't fly on the 14th as booked. Can you help?",
          add_bag:"Hi, I'd like to add something to the flight I already booked. Is that possible?",upgrade:"Hi, I'd like to add something to the flight I already booked. Is that possible?"};
var st={wish:"cancel",ticket:"flex",cond:"last",t:[],notes:"",turns:0};
function $(i){return document.getElementById(i)}
function pick(box,map,key){box.innerHTML="";Object.keys(map).forEach(function(k){var b=document.createElement("button");b.className="btn"+(st[key]===k?" on":"");b.textContent=map[k];
  b.onclick=function(){st[key]=k;pick(box,map,key);if(key==="wish")$("s-open").value=OPEN[k]};box.appendChild(b)})}
pick($("s-wish"),WISH,"wish");pick($("s-ticket"),{basic:"basic",flex:"flex"},"ticket");pick($("s-cond"),COND,"cond");$("s-open").value=OPEN[st.wish];
function add(cls,who,text,extra){var d=document.createElement("div");d.className="card "+cls;var k=document.createElement("div");k.className="k";k.textContent=who;d.appendChild(k);
  var p=document.createElement("p");p.textContent=text;d.appendChild(p);if(extra)d.appendChild(extra);$("log").appendChild(d);d.scrollIntoView({behavior:"smooth",block:"end"})}
function bars(b){var box=document.createElement("div");var k=document.createElement("div");k.className="k";k.textContent="what it says it believes, from what it was shown";box.appendChild(k);
  function row(l,v){var r=document.createElement("div");r.className="row";r.innerHTML="<span></span><div class='bar'><i style='width:"+Math.round(100*v)+"%'></i></div><span>"+Math.round(100*v)+"%</span>";r.firstChild.textContent=l;box.appendChild(r)}
  ["cancel","change_date","add_bag","upgrade"].forEach(function(w){row(w.replace("_"," "),b.wish[w])});row("ticket is flex",b.flex);return box}
function turn(){$("status").textContent="the model is thinking (two calls, a few seconds each)";$("reply").hidden=true;
  fetch("api/turn",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({condition:st.cond,transcript:st.t,notes:st.notes})})
  .then(function(r){return r.json()}).then(function(o){
    if(o.error){$("status").textContent="FAILED: "+o.error;return}
    st.turns++;st.notes=o.notes||"";$("status").textContent="";
    var extra=document.createElement("div");if(o.shown){var s=document.createElement("div");s.className="k";s.textContent="it was shown: "+o.shown;extra.appendChild(s)}
    extra.appendChild(bars(o.belief));
    if(st.cond==="notes"&&o.notes){var n=document.createElement("div");n.className="k";n.textContent="note to itself for next turn: "+o.notes;extra.appendChild(n)}
    if(o.step==="ask_customer"){add("","agent · turn "+st.turns+" · asks",o.say||"What exactly would you like to do?",extra);st.t.push(["You","(asked the customer what exactly they want)"]);$("reply").hidden=false;$("r-text").value="";$("r-text").focus()}
    else if(o.step==="lookup_booking"){add("","agent · turn "+st.turns+" · looks the booking up",o.reason,extra);st.t.push(["You","(looked the booking up)"]);var said="The ticket type is "+st.ticket.toUpperCase()+".";st.t.push(["Booking system",said]);add("","booking system",said);
      if(st.turns>=10){finish("No final step after 10 turns. It kept going round.")}else turn()}
    else{add("","agent · turn "+st.turns+" · FINAL STEP: "+o.step.replace("_"," "),o.say||o.reason,extra);
      var right=(st.ticket==="flex"||st.wish==="add_bag"||st.wish==="upgrade")?st.wish:"refuse";
      finish(o.step===right?"Right. That was the correct final step, in "+st.turns+" turn(s).":"Wrong. The correct final step was "+right.replace("_"," ")+". It cannot be undone.")}
  }).catch(function(e){$("status").textContent="FAILED: "+e})}
function finish(msg){add("me","result",msg);$("again").hidden=false;$("reply").hidden=true}
$("s-go").onclick=function(){var m=$("s-open").value.trim();if(!m)return;st.t=[["Customer",m]];st.notes="";st.turns=0;$("setup").hidden=true;$("chat").hidden=false;$("log").innerHTML="";$("again").hidden=true;
  add("me","you · wanting "+WISH[st.wish]+" · "+st.ticket+" ticket · agent shown "+COND[st.cond],m);turn()};
$("r-send").onclick=function(){var m=$("r-text").value.trim();if(!m)return;st.t.push(["Customer",m]);add("me","you",m);if(st.turns>=10){finish("No final step after 10 turns. It kept going round.")}else turn()};
$("again").onclick=function(){$("setup").hidden=false;$("chat").hidden=true};
})();
</script></main></body></html>"""


class Talk:
    """The slice of hidden_order.World that visible() needs, built from the page's transcript."""

    def __init__(self, transcript):
        self.transcript = [(str(w)[:20], str(t)[:600]) for w, t in transcript][-40:]
        self.wish = self.ticket = "(not told)"

    def last_message(self):
        who, text = self.transcript[-1]
        return f"{who}: {text}"

    def full_text(self):
        return "\n".join(f"{who}: {text}" for who, text in self.transcript)


def make_handler(base: str, model: str):
    _, belief = ho.model_agent(base, model)

    class H(BaseHTTPRequestHandler):
        def log_message(self, *a):          # quiet: one line per failure only
            pass

        def _send(self, code, body, ctype):
            data = body.encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):
            if self.path.split("?")[0] in ("/", "/index.html"):
                return self._send(200, PAGE.replace("__MODEL__", model), "text/html; charset=utf-8")
            self._send(404, "not found", "text/plain")

        def do_POST(self):
            if self.path.split("?")[0] not in ("/api/turn", "api/turn"):
                return self._send(404, "not found", "text/plain")
            try:
                n = int(self.headers.get("Content-Length", "0"))
                if n > 40000:
                    raise ValueError("request too large")
                req = json.loads(self.rfile.read(n))
                cond = req.get("condition")
                if cond not in ("last", "notes", "full") or not req.get("transcript"):
                    raise ValueError("bad request")
                talk, notes = Talk(req["transcript"]), str(req.get("notes", ""))[:400]
                seen = ho.visible(talk, cond, notes)
                b = belief(talk, cond, notes)
                schema = ho.act_schema(cond)
                schema["properties"]["say"] = {"type": "string"}
                schema["required"] = schema["required"] + ["say"]
                ask = ("Reply in JSON. " + ('"notes": everything worth remembering for your next turn, in under 40 words (it is all you will have). ' if cond == "notes" else "")
                       + '"reason": one short sentence. "step": the one step you take now. "say": what you say to the customer in one or two sentences.')
                out = ho.ollama(base, model, ho.RULES, seen + "\n\n" + ask, schema)
                step = out.get("step") if out.get("step") in ho.STEPS else "ask_customer"
                shown = talk.last_message() if cond != "full" else f"all {len(talk.transcript)} lines so far"
                body = {"step": step, "reason": out.get("reason", ""), "say": out.get("say", ""), "notes": (out.get("notes", "") or "")[:400] if cond == "notes" else "", "belief": b, "shown": shown}
                self._send(200, json.dumps(body), "application/json")
            except Exception as err:        # the page shows the failure; nothing is guessed in its place
                print(f"FAIL: {err!r}", file=sys.stderr, flush=True)
                self._send(500, json.dumps({"error": str(err)[:200]}), "application/json")
    return H


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--model", default="gemma4:12b")
    ap.add_argument("--base", default="http://127.0.0.1:11434")
    ap.add_argument("--port", type=int, default=8811)
    ap.add_argument("--host", default="127.0.0.1")
    a = ap.parse_args(argv)
    srv = ThreadingHTTPServer((a.host, a.port), make_handler(a.base, a.model))
    print(f"the hidden order, live: http://{a.host}:{a.port}  (model {a.model})", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
