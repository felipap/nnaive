
# board.coffee for nnaive

painter =
	applyCanvasOptions : (context, options) ->
		if options.fill is true
			if 'color' of options then context.fillStyle = options.color
		else
			if 'color' of options then context.strokeStyle = options.color
			if 'width' of options then context.lineWidth = options.width

	###### Canvas manipulation functions
	fillCircle : (context, position, radius=2, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.arc(position.x, position.y, radius, 0, 2*Math.PI, true)
		context.fill()

	drawCircle : (context, position, radius=2, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.arc(position.x, position.y, radius, 0, 2*Math.PI, true)
		context.stroke()

	drawLine : (context, p1, p2, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.moveTo p1.x, p1.y
		context.lineTo p2.x, p2.y
		context.stroke()

	drawTriangle : (context, p1, p2, p3, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.moveTo p1.x, p1.y
		context.lineTo p2.x, p2.y
		context.lineTo p3.x, p3.y
		context.closePath()
		context.stroke()

	drawCenteredPolygon : (context, center, points, angle=0, options={}) ->
		this.applyCanvasOptions(context, options)
		angle = 0
		context.save()
		context.translate(center.x, center.y)
		context.rotate(angle)
		context.beginPath()
		context.moveTo(points[0].x, points[0].y)
		for point in points[1..]
			context.lineTo(point.x,point.y)
		context.closePath()
		if options.fill
			context.fill()
		else context.stroke()
		context.restore()

	# Draws a polygon.
	# Won't take angle arg, because it is necessary to have the rotation center.
	# For that, use drawCenteredPolygo
	drawPolygon : (context, points, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.moveTo(points[0].x, points[0].y)
		for point in points[1..]
			context.lineTo(point.x,point.y)
		context.lineTo(points[0].x, points[0].y)
		context.closePath()
		if options.fill
			context.fill()
		else context.stroke

	# Fills a rectangle between two points.
	drawRectangle : (context, p1, p2, angle=0, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		if angle isnt 0
			context.save()
			context.translate((p1.x+p2.x)/2, (p1.y+p2.y)/2) # Translate center of canvas to center of figure.
			context.rotate(angle)
			context.rect(p1.x, p1.y, p2.x-p1.x, p2.y-p1.y)
			context.restore()
		else
			context.rect(p1.x, p1.y, p2.x-p1.x, p2.y-p1.y)
		if options.fill
			context.fill()
		else context.stroke()

	# Draws a rectangle using the center and size (x:width,y:height) as paramenters. 
	drawSizedRect : (context, point, size, angle=0, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		if angle
			context.save()
			context.translate(point.x, point.y) # Translate center of canvas to center of figure.
			context.rotate(angle)
			context.rect(-size.x/2, -size.y/2, size.x, size.y)
			context.restore()
		else
			context.rect(point.x-size.x/2, point.y-size.y/2, size.x, size.y)
		if options.fill
			context.fill()
		else context.stroke()

mm = (min, num, max) -> # restricts num to min max bounds.
	Math.max(min, Math.min(max, num))

getResultant = (m, objects, distDecay=2, reppel=2) ->
	fx = fy = 0
	for obj in objects when obj isnt m
		# Delta calculations. 
		dx = m.position.x - obj.position.x
		dy = m.position.y - obj.position.y
		# Vector direction corrections.
		rx = if dx > 0 then -1 else 1
		ry = if dy > 0 then -1 else 1
		# Distance calculation. (squared)
		d2 = Math.pow(m.position.x-obj.position.x,2)+Math.pow(m.position.y-obj.position.y,2)
		# Force is inversely proportional to the distance^distDecay.
		F = 1/(if distDecay is 2 then d2 else Math.pow(d2,distDecay/2)) 
		# Calculate vector projections. (update to shortcut functions?)
		alpha = Math.atan(dy/dx)
		dfx = Math.abs(Math.cos(alpha))*F*rx
		dfy = Math.abs(Math.sin(alpha))*F*ry
		# Draw point-to-point vector.
		painter.drawLine(context, m.position, obj.position, {color: "grey", width: mm(0, F*5000,200)})
		# Multiplier
		multiplier = m.getMultiplier(obj)
		# Test if too close.
		if d2 < Math.pow(obj.size+m.size,2)*2
			# console.log('too close', obj.size, m.size, Math.pow(obj.size+m.size,2), d2)
			dfx = -reppel*dfx
			dfy = -reppel*dfy
		# Update projections.
		fx += dfx * multiplier
		fy += dfy * multiplier
	# Draw resultant.
	painter.drawLine(context, m.position, {x: m.position.x+fx*10000, y: m.position.y+fy*10000}, {color: "red"})
	return {x: fx, y: fy, angle: Math.atan(dy/dx)}

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
	twalk: 0
	
	constructor: (@position) ->
		@vel =	{x: 0, y: 0}
		@acc = {x: 0, y: 0}

		angle = Math.random()*Math.PI*2
		# @shift = {x: Math.cos(angle)*speed, y: Math.sin(angle)*speed}
		@vel.x = (Math.random()>0.5?1:-1)*100*Math.random()
		@vel.y = 0.1*Math.random()-0.1/2
		
		@defineWalk()
	
	getMultiplier: (obj) ->
		return @multipliers[obj.type] or 1

	defineWalk: ->
		console.log('Defining twalk.')
		max = 0.1
		@vel.x = max*Math.random()-max/2
		@vel.y = max*Math.random()-max/2
		@twalk = Math.max(100, 200*Math.random())

	tic: (step) ->
		step = 200

		# Verlet Integration
		@_acc = {x: @acc.x, y: @acc.y}
		@position.x += @vel.x*step+(0.5*@_acc.x*step*step)
		@position.y += @vel.y*step+(0.5*@_acc.y*step*step)
		@acc = getResultant(@, game.board.state)
		@acc.x *= 1/@mass # add multipliers here
		@acc.y *= 1/@mass
		# Update velocity with average acceleration
		@vel.x += (@_acc.x+@acc.x) / 2 * step * window.vars.rest / 1000
		@vel.y += (@_acc.y+@acc.y) / 2 * step * window.vars.rest / 1000

		wholevel = Math.sqrt(@vel.x*@vel.x + @vel.y*@vel.y)
		# console.log(@angle, '\t', Math.sin(@angle))
		@vel.x = wholevel*Math.cos(@angle)
		@vel.y = wholevel*Math.sin(@angle)

		if not @twalk--
			@defineWalk()

		@angle += @angularSpeed * step # * Math.max(1, Math.pow(Math.abs(@acc.x)+Math.abs(@acc.y), 3) )/ @mass
		
		# Limit particle to canvas bounds.
		@position.x = mm(0, @position.x, window.canvas.width)
		@position.y = mm(0, @position.y, window.canvas.height)

	render: (context) ->

class Triangle extends Drawable

	size: 10

	constructor: (@position) ->
		@size = 30
		r3 = Math.sqrt(3)
		@p1 = {x: 0, y: -1.154700*@size}
		@p2 = {x: -@size, y: 0.5773*@size}
		@p3 = {x: @size, y: 0.5773*@size}
	
	setPoints: (@p1, @p2, @p3) ->

	tic: (step) ->

	render: (context) ->
		painter.drawCenteredPolygon(context, @position, [@p1,@p2,@p3], @angle, {color:@color, width:1})

class Circle extends Drawable
	
	size: 20
	
	constructor: (@position) ->

	render: (context) ->
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
		painter.drawSizedRect(context, @position, {x:@size,y:@size}, @angle, {color:@color, fill:false, width:1})

class Bot extends Square
	
	type: 'Bot'
	color: 'red'
	multipliers: {'Bot': -2,'FixedPole': -1}
	size: 10
	angularSpeed: .0001

	constructor: (@position) ->
		super
		window.lastAdded = @

	tic: (step) ->
		super
		if @ is window.lastAdded
			console.log

class FixedPole extends Triangle

	color: "#08e"
	size: 50
	angularSpeed: .0002

	tic: (step) ->
		step = 20
		@size = window.vars.polesize
		@angle += @angularSpeed * step 

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
		# context.clearRect(0, 0, @canvas.width, @canvas.height)
		painter.drawRectangle(context, {x:0,y:0}, {x:@canvas.width,y:@canvas.height}, 0, {color:"rgba(255,255,255,.02)", fill:true})
		for item in @state
			item.tic(step)