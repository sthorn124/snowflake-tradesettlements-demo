#!/usr/bin/env python3
"""Compare two saved testInterface renders leaf by leaf.

  render_leafdiff.py before.json after.json

Each file is one testInterface response as JSON: {"result": <component tree>,
"diagnostics": {...}}. Under Claude Code a render too large to show inline is
saved to a file by the client, and the tool result names the path; that file
is the input here.

Every leaf of the tree is compared by its path. Two kinds of leaf are left out
because they change on every render and say nothing about the page:
  _cId      a component id minted per render
  saveInto  an opaque token for a save binding
What remains is what the page shows and how: text, colours, sizes, tooltips,
grid rows and their order. Values driven by the clock (countdowns, "last read",
chart buckets by hour) still differ between two renders and have to be read as
such.

First used 2026-11-12 to show that SO_analystWatchlist version 24 renders as
version 23 did apart from its two totals and their tooltips.
"""
import json
import sys

SKIP = ("/_cId",)


def leaves(o, path=""):
    if isinstance(o, dict):
        for k, v in o.items():
            yield from leaves(v, path + "/" + k)
    elif isinstance(o, list):
        for i, v in enumerate(o):
            yield from leaves(v, path + "[%d]" % i)
    else:
        yield path, o


def load(p):
    j = json.load(open(p))
    if isinstance(j, list):  # a client wrapper: [{"type": "text", "text": "<json>"}]
        j = json.loads(j[0]["text"])
    return j


def keep(path):
    return not path.endswith(SKIP) and "/saveInto" not in path


def short(v):
    return v[:300] if isinstance(v, str) else v


def main():
    a, b = load(sys.argv[1]), load(sys.argv[2])
    print("before diagnostics:", a.get("diagnostics"))
    print("after  diagnostics:", b.get("diagnostics"))
    la = {p: v for p, v in leaves(a["result"]) if keep(p)}
    lb = {p: v for p, v in leaves(b["result"]) if keep(p)}
    changed = [(p, la[p], lb[p]) for p in la if p in lb and la[p] != lb[p]]
    removed = [(p, la[p]) for p in la if p not in lb]
    added = [(p, lb[p]) for p in lb if p not in la]
    print("leaves: before %d, after %d" % (len(la), len(lb)))
    print("changed %d, removed %d, added %d" % (len(changed), len(removed), len(added)))
    for p, x, y in changed:
        print("CHG %s\n    - %r\n    + %r" % (p[-90:], short(x), short(y)))
    for p, x in removed:
        print("DEL %s = %r" % (p[-90:], short(x)))
    for p, y in added:
        print("ADD %s = %r" % (p[-90:], short(y)))


if __name__ == "__main__":
    main()
