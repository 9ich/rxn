#? replace(sub="\t",by="    ")
import std/[algorithm,monotimes,random,stats,strformat,strutils,times]
import raylib

type State = enum WAIT,FIRED

const waitrange = 1500000000i64..4000000000i64

var fon:Font
var now = getmonotime()
var state:State
var stime:MonoTime
var hist = newseqofcap[float64](20)
var rs:RunningStat

proc reset() =
	state = WAIT; stime = now + waitrange.rand.initduration
	
func median[T](a:openarray[T]):T =
	if a.len > 0: a.sorted[a.len div 2] else: 0
		
proc update() =
	now = getmonotime()
	let click = ismousebuttonpressed(LEFT) or iskeypressed(SPACE) or
			iskeypressed(W)
	case state:
	of WAIT:
		if click:          (reset())
		elif now >= stime: (state = FIRED; stime = now)
	of FIRED:
		if click:
			hist &= (now - stime).inmilliseconds.float64
			rs.push hist[^1]
			reset()
	if iskeypressed(R): (hist.setlen 0; rs.clear(); reset())
	if iskeypressed(F): (togglefullscreen())
	
proc draw() =
	clearbackground [0x000000ffu32,0x00ff00ff][state.int].getcolor
	let last = if hist.len > 0: hist[^1] else: 0f64
	let fs = iswindowfullscreen().int
	let s = &(
		"{hist}\n"&
		"last   {last:3} ms\n"&
		"min    {rs.min:3} ms\n"&
		"max    {rs.max:3} ms\n"&
		"median {hist.median:3} ms\n"&
		"mean   {rs.mean:3} ms\n"&
		"sd     {rs.standarddeviation:3} ms\n"&
		"\nf:fullscreen[{fs}] r:reset q:quit\n"
	)
	begindrawing()
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
