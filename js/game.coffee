
class Game

	###### Fps stuff

	window.fps = 0
	lastUpdate = (new Date)*1 - 1
	fpsFilter = 50
	context = null

	addFpsCounter = ->
		fpsOut = document.getElementById 'fps'
		window.fps = 0
		setInterval =>
			fpsOut.innerHTML = window.fps.toFixed(1)
		, 500

	resetFpsCounter = ->
		window.fps = 0

	_getMousePos: (event) ->
		rect = @canvas.getBoundingClientRect()
		x: event.clientX - rect.left
		y: event.clientY - rect.top

	######

	constructor: ->
		@canvas = document.querySelector "canvas#nnaive"
		window.canvas = @canvas
		$(".wrapper").height($(document).height()-20)
		@canvas.width = $('.wrapper').width()  # window.innerWidth
		@canvas.height = $('.wrapper').height() # window.innerHeight
		context = @canvas.getContext("2d")

		@board = new window.Board(@canvas)
		console.log 'board', @board
		
		$(@canvas).bind 'click', (event) =>
			t = new Bot(@_getMousePos(event))
			@board.addBot(t)

		$(@canvas).bind 'mousedown', (event) =>
			if event.button is 2
				t = new FixedPole(@_getMousePos(event))
				@board.addObject(t)

		window.canvasStop = false
		$(document).keydown (event) =>
			if event.keyCode == 32
				console.log('spacebar')
				window.canvasStop = !window.canvasStop
				$("#flags").html(if window.canvasStop then "Stopped" else "")

		return
		@dispatcher = new EventDispatcher(@board, @)

	loop: ->
		# Synchronise window.fps
		thisFrameFPS = 1000 / ((now=new Date) - lastUpdate)
		window.fps += (thisFrameFPS - window.fps) / 1;
		lastUpdate = now * 1 - 1

		if not window.canvasStop
			@board.tic(1/50)
			@board.render(context)

		window.setTimeout =>
			@loop()
		#, 1000/@fps
		, 20
		#window.AnimateOnFrameRate(->game.loop())

	start: ->
		addFpsCounter()
		console.log "Start looping board" # , @board, "with painter", @ 
		@loop()


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