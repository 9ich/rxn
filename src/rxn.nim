#? replace(sub="\t",by="    ")
import std/[algorithm,monotimes,random,stats,sequtils,strformat,strutils,
	syncio,times]
import raylib

type State = enum WAIT,FIRED,PAUSED
type Msg = tuple[t:MonoTime,s:string]

const waitrange = 1500000000i64..4000000000i64

var fon:Font
var now = getmonotime()
var state:State
var stime:MonoTime
var hist = newseqofcap[float] 20
var rs:RunningStat
var msgq = newseqofcap[Msg] 1

proc msg(s:string) = msgq.add((now,s))
proc msgupdate() =   msgq = msgq.filterit(now < it.t + initduration(seconds=2))

proc reset() =
	state = WAIT; stime = now + waitrange.rand.initduration

func median[T](a:openarray[T]):T =
	if a.len > 0: a.sorted[a.len div 2] else: 0

proc statmsg():string {.inline.} =
	let last = if hist.len > 0: hist[^1] else: 0f64
	&(
		"{hist}\n"&
		"last   {last:3} ms\n"&
		"min    {rs.min:3} ms\n"&
		"max    {rs.max:3} ms\n"&
		"median {hist.median:3} ms\n"&
		"mean   {rs.mean:3} ms\n"&
		"sd     {rs.standarddeviation:3} ms\n"
	)

proc dump() =
	let t = now().format("yyyyMMdd-HHmm")
	let name = &"rxn_{t}.txt"
	try: (writefile(name, &"{statmsg()}\n"); msg(&"dumped stats to {name}"))
	except: msg(&"error dumping stats to {name}:\n{getcurrentexceptionmsg()}")

proc update() =
	now = getmonotime()
	let click = ismousebuttonpressed(LEFT) or iskeypressed(W)
	case state:
	of WAIT:
		if iskeypressed(SPACE): state = PAUSED
		elif click:             (reset())
		elif now >= stime:      ((state,stime) = (FIRED,now))
	of FIRED:
		if click:
			hist &= (now - stime).inmilliseconds.float
			rs.push hist[^1]
			reset()
	of PAUSED:
		if iskeypressed(SPACE): (reset())
	if iskeypressed(D): (dump())
	if iskeypressed(F): (togglefullscreen())
	if iskeypressed(R): (hist.setlen 0; rs.clear(); reset())

proc draw() =
	clearbackground [0x000000ffu32,0x00ff00ff,0x100000ff][state.int].getcolor
	begindrawing()
	let p = ["pause","PAUSED"][(state == PAUSED).int]
	let fs = iswindowfullscreen().int
	var s = &("{statmsg()}\nspace:{p} d:dump f:fullscreen[{fs}] r:reset"&
		" q:quit\n\n\n")
	msgupdate()
	for m in msgq: s &= &"{m.s}\n"
	drawtext fon, s, Vector2(x:4,y:100), fon.basesize.float32, 1,
			0xffffffffu32.getcolor
	enddrawing()

proc main() =
	setconfigflags flags(FullscreenMode)
	let m = getcurrentmonitor()
	initwindow m.getmonitorwidth, m.getmonitorheight, "rxn"
	defer: closewindow()
	const fd = slurp "terminusmin.ttf"
	fon = loadfontfrommemory(".ttf", cast[seq[uint8]](fd), 24, 127)
	setexitkey Q; settargetfps 999999
	randomize(); reset()
	while not windowshouldclose(): (update(); draw())
main()
