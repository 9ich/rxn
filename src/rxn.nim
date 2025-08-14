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
	state = WAIT; stime = now + initduration(rand(waitrange))
	
func median(a:openarray[float64]):float64 =
	if a.len > 0: a.sorted[a.len div 2] else: 0
		
proc update() =
	now = getmonotime()
	let ack = ismousebuttonpressed(LEFT) or iskeypressed(SPACE) or
		iskeypressed(KeyboardKey.W)
	case state:
		of WAIT:
			if now >= stime: (state = FIRED; stime = now)
			elif ack:        reset()
		of FIRED:
			if ack:
				hist &= (now - stime).inmilliseconds.float64
				rs.push(hist[^1])
				reset()
	if iskeypressed(KeyboardKey.R): (hist.setlen(0); rs.clear(); reset())
	if iskeypressed(KeyboardKey.F): togglefullscreen()
	
proc draw() =
	let c = [0x000000ffu32,0x00ff00ff][state.int].getcolor
	clearbackground(c)
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
	drawtext(fon, s, Vector2(x:4,y:100), fon.basesize.float32, 1,
		0xffffffffu32.getcolor)
	enddrawing()

proc main() =
	setconfigflags(Flags[ConfigFlags](FullscreenMode))
	let m = getcurrentmonitor()
	initwindow(m.getmonitorwidth, m.getmonitorheight, "rxn")
	defer: closewindow()
	setexitkey(KeyboardKey.Q)
	settargetfps(999999)
	const fd = slurp("terminusmin.ttf")
	fon = loadfontfrommemory(".ttf", cast[seq[uint8]](fd), 24, 127)
	randomize(); reset()
	while not windowshouldclose(): (update(); draw())
main()
