
class Game

	fps = 0
	tps = 0
	lastTic = (new Date)*1 - 1
	lastRender = (new Date)*1 - 1
	fpsFilter = 50
	context = null

	addFpsCounter = ->
		fpsOut = document.getElementById('fps')
		tpsOut = document.getElementById('tps')
		tics = document.getElementById('tics')
		setInterval =>
			fpsOut.innerHTML = 'fps:'+fps.toFixed(1)
			tpsOut.innerHTML = 'tps:'+tps.toFixed(1)
			tics.innerHTML = 'tic: '+game.board.tics
		, 500

	resetFpsCounter = ->
		fps = 0

	_getMousePos: (event) ->
		rect = @canvas.getBoundingClientRect()
		x: event.clientX - rect.left
		y: event.clientY - rect.top

	constructor: ->
		@canvas = document.querySelector "canvas#nnaive"
		window.canvas = @canvas
		$(".wrapper").height($(document).height()-20)
		@canvas.width = $('.wrapper').width()  # window.innerWidth
		@canvas.height = $('.wrapper').height() # window.innerHeight
		context = @canvas.getContext("2d")
		window.context = context

		@board = new window.Board()

		window.canvasStop = false
		$(document).keydown (event) =>
			if event.keyCode == 32
				console.log('spacebar hit')
				window.canvasStop = !window.canvasStop
				$("#flags #stopped").html(if window.canvasStop then "Stopped" else "")

	loopTic: ->
		if not window.canvasStop
			@board.tic(1/50)
		window.setTimeout((=> @loopTic()), 1)
		# Synchronise tps
		thisFrameTPS = 1000 / ((now=new Date) - lastTic)
		tps += (thisFrameTPS - tps) / 10;
		lastTic = now * 1 - 1

	loopRender: ->
		if not window.canvasStop
			@board.render(context)
		window.AnimateOnFrameRate(=>@loopRender())
		# Synchronise fps
		thisFrameFPS = 1000 / ((now=new Date) - lastRender)
		fps += (thisFrameFPS - fps) / 10;
		lastRender = now * 1 - 1

	start: ->
		addFpsCounter()
		console.log("Start looping board", @board, "with painter", @)
		@loopTic()
		@loopRender()


window.AnimateOnFrameRate = do ->
	# thanks, Paul Irish
	window.requestAnimationFrame 			or
	window.webkitRequestAnimationFrame		or
	window.mozRequestAnimationFrame			or
	window.oRequestAnimationFrame			or
	window.msRequestAnimationFrame			or
	(callback) ->
		window.setTimeout callback, 1000/60


window.onload = ->
	# Start the game and loop.
	window.game = new Game
	window.game.start()
	return

$("body").keydown (e) ->
	switch e.keyCode or e.keyCode
		when 37 then window.leftPressed = true
		when 38 then window.upPressed = true
		when 39 then window.rightPressed = true
		when 40 then window.downPressed = true

$("body").keyup (e) ->
	switch e.keyCode or e.keyCode
		when 37 then window.leftPressed = false
		when 38 then window.upPressed = false
		when 39 then window.rightPressed = false
		when 40 then window.downPressed = false