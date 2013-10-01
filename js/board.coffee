
# board.coffee for nnaive

painter =
	###### Canvas manipulation functions
	fillCircle : (context, position, radius=2, color="black") ->
		context.fillStyle = color
		context.beginPath()
		context.arc(position.x, position.y, radius, 0, 2*Math.PI, true)
		context.fill()

	drawCircle : (context, position, radius=2, color="black") ->
		context.strokeStyle = color
		context.beginPath()
		context.arc(position.x, position.y, radius, 0, 2*Math.PI, true)
		context.stroke()

	drawLine : (context, p1, p2, lineWidth=1, color="black") -> 
		context.strokeStyle = color
		context.lineWidth = lineWidth
		context.beginPath()
		context.moveTo p1.x, p1.y
		context.lineTo p2.x, p2.y
		context.stroke()

	drawTriangle : (context, p1, p2, p3, lineWidth=1, color="black") ->
		context.strokeStyle = color
		context.lineWidth = lineWidth
		context.beginPath()
		context.moveTo p1.x, p1.y
		context.lineTo p2.x, p2.y
		context.lineTo p3.x, p3.y
		context.lineTo p1.x, p1.y
		context.stroke()

	drawPolygon : (context, points, lineWidth=1, color="black", angle=0) ->
		context.fillStyle = '#F00'
		context.beginPath()
		context.moveTo(points[0].x, points[0].y)
		for point in points[1..]
			context.lineTo(point.x,point.y)
		context.lineTo(points[0].x, points[0].y)
		context.closePath()
		context.fill()

	drawRectangle : (context, p1, p2, lineWidth=1, color="black") ->
		# context.strokeStyle = 'black'
		context.rect(p1.x, p1.y, p2.x-p1.x, p2.y-p2.y)
		context.stroke()

	# fillRectangle : (context, p1, p2, color="black") ->
	# 	context.fillStyle = color
	# 	context.fillRect(p1.x, p1.y, p2.x-p1.x, p2.y-p1.y)

	fillRectangle : (context, point, size, color="black", angle=0) ->
		context.fillStyle = color
		if angle
			context.save()
			context.translate(point.x, point.y) # Translate center of canvas to center of figure.
			context.rotate(angle)
			context.fillRect(-size/2, -size/2, size, size)
			context.restore()
		else # optimize for angle=0?
			context.fillRect(point.x-size/2, point.y-size/2, size, size)

mm = (min, num, max) -> # min max
	Math.max(min, Math.min(max, num))

xy = (x,y) -> x:x, y:y


getResultant = (m, objects) ->
	fx = fy = 0
	for obj in objects when obj isnt m
		# Delta calculations. 
		dx = m.position.x - obj.position.x
		dy = m.position.y - obj.position.y
		# Vector direction corrections.
		rx = if dx > 0 then -1 else 1
		ry = if dy > 0 then -1 else 1
		# Distance calculation.
		d2 = Math.pow(m.position.x-obj.position.x,2)+Math.pow(m.position.y-obj.position.y,2)
		# Force is inversely proportional to the distance².
		F = 1/d2
		# Calculate vector projections. (update to shortcut functions?)
		alpha = Math.atan(dy/dx)
		dfx = Math.abs(Math.cos(alpha))*F*rx
		dfy = Math.abs(Math.sin(alpha))*F*ry
		# Draw point-to-point vector.
		painter.drawLine(context, m.position, obj.position, mm(0, F*5000,200), "grey")
		# Multiplier
		multiplier = m.getMultiplier(obj)
		# Test if too close.
		if d2 < Math.pow(obj.size+m.size,2)
			# console.log('too close', obj.size, m.size, Math.pow(obj.size+m.size,2), d2)
			dfx = -2*dfx
			dfy = -2*dfy
		# Update projections.
		fx += dfx * multiplier
		fy += dfy * multiplier
	# Draw resultant.
	painter.drawLine(context, m.position, {x: m.position.x+fx*10000, y: m.position.y+fy*10000}, 1, "red")
	return {x: fx, y: fy}

class Drawable
	type: 'Drawable'
	multipliers: {}
	mass : 1
	position : {x:null, y:null}
	velocity : {x:null, y:null}
	acceleration : {x:null, y:null}
	shift: {x:null, y:null}
	angle: 0
	angularSpeed: 0
	
	constructor: (@position) ->
		@velocity =	{x: 0, y: 0}
		@acceleration = {x: 0, y: 0}

		# angle = Math.random()*Math.PI*2
		# speed = 0
		# @shift = {x: Math.cos(angle)*speed, y: Math.sin(angle)*speed}
	
	getMultiplier: (obj) ->
		# console.log('getting', obj.type, @multipliers)
		return @multipliers[obj.type] or 1

	tic: (step) ->
		step = 20
		# Verlet Integration
		@_acceleration = {x: @acceleration.x, y: @acceleration.y}
		@position.x += @velocity.x*step+(0.5*@_acceleration.x*step*step)
		@position.y += @velocity.y*step+(0.5*@_acceleration.y*step*step)
		
		@acceleration = getResultant(@, game.board.state)
		@acceleration.x *= 1/@mass # add multipliers here
		@acceleration.y *= 1/@mass
		avg_acceleration =
			x : (@_acceleration.x+@acceleration.x)/2
			y : (@_acceleration.y+@acceleration.y)/2
		
		@velocity.x += avg_acceleration.x * step * window.vars.rest / 10
		@velocity.y += avg_acceleration.y * step * window.vars.rest / 10

		@angle += @angularSpeed * step * Math.pow(Math.abs(@velocity.x)+Math.abs(@velocity.y), 4) / @mass
		
		@position.x = mm(0, @position.x, window.canvas.width)
		@position.y = mm(0, @position.y, window.canvas.height)

	render: (context) ->

class Triangle extends Drawable

	@p1 = @p2 = @p3 = null

	constructor: (@position) ->
		@p1 = {x: -60*Math.random(), y: -60*Math.random()}
		@p2 = {x: 60*Math.random(), y: 60*Math.random()}
		@p3 = {x: 60*Math.random(), y: 60*Math.random()}
	
	setPoints: (@p1, @p2, @p3) ->

	tic: (step) ->

	render: (context) ->
		# Calculate absolute position from relative points.
		_p1 = {x: @p1.x+@position.x, y: @p1.y+@position.y}
		_p2 = {x: @p2.x+@position.x, y: @p2.y+@position.y}
		_p3 = {x: @p3.x+@position.x, y: @p3.y+@position.y}
		painter.drawTriangle(context, _p1, _p2, _p3)

class Circle extends Drawable
	
	size: 20
	
	constructor: (@position) ->

	render: (context) ->
		# Calculate something.
		painter.drawCircle(context, @position, @size)

window.lastAdded = null

class Square extends Drawable

	type: 'Square'
	endPoint: null
	color: "black"
	size: 15

	constructor: (@position) ->
		super

	render: (context) =>
		vertex1 = {x: @position.x-@size, y: @position.y-@size}
		vertex2 = {x: @position.x+@size, y: @position.y+@size}
		painter.fillRectangle(context, @position, @size, @color, @angle)

class Bot extends Square
	
	type: 'Bot'
	multipliers: [ 
		'Bot': -2,
		'FixedPole': -1,
	]
	color: "red"
	angularSpeed: 2

	constructor: (@position) ->
		super
		window.lastAdded = @

	tic: (step) ->
		super
		if @ is window.lastAdded
			console.log

class FixedPole extends Circle

	color: "#08e"
	size: 20

	tic: (step) ->
		@size = window.vars.polesize

################################################################################
################################################################################

class Board

	addObject: (object) ->
		@state.push object

	constructor: (@canvas) ->
		window.context = @canvas.getContext("2d")
		
		window.vars = {}
		vars = ['rest', 'polesize']
		for name in vars
			window.vars[name] = parseInt($(".control#"+name+" input").attr('value'))
			do ->
				# scope
				n = name
				$(".control#"+name+" input").bind 'change', (event) =>
					window.e = event
					value = Math.max(0.1, parseInt(event.target.value)/parseInt(event.target.dataset.divisor or 1))
					event.target.parentElement.querySelector('span').innerHTML = value
					window.vars[n] = value
		@state = [] # Objects to be drawn.

	render: (context) ->
		for item in @state
			item.render(context)

	tic: (step) ->
		context.clearRect(0, 0, @canvas.width, @canvas.height)
		for item in @state
			item.tic(step)