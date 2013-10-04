
# board.coffee for nnaive

mod = (a, n) -> ((a%n)+n)%n

dist2 = (a, b) -> Math.pow(a.x-b.x,2)+Math.pow(a.y-b.y,2)
dist = (a, b) -> Math.sqrt(dist2(a,b))

painter =
	applyCanvasOptions : (context, options) ->
		if options.fill is true
			context.fillStyle = options.color or 'black'
		else
			context.strokeStyle = options.color or 'blue'
			context.lineWidth = options.width or 1

	###### Canvas manipulation functions

	drawCircle : (context, position, radius=2, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.arc(position.x, position.y, radius, 0, 2*Math.PI, true)
		if options.fill
			context.fill()
		else context.stroke()

	drawLine : (context, p1, p2, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.moveTo p1.x, p1.y
		context.lineTo p2.x, p2.y
		context.stroke()

	drawTriangle : (context, p1, p2, p3, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		context.moveTo(p1.x, p1.y)
		context.lineTo(p2.x, p2.y)
		context.lineTo(p3.x, p3.y)
		context.closePath()
		context.stroke()

	drawCenteredPolygon : (context, center, points, angle=0, options={}) ->
		this.applyCanvasOptions(context, options)
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
		# Distance calculation. (squared)
		d2 = Math.pow(m.position.x-obj.position.x,2)+Math.pow(m.position.y-obj.position.y,2)
		# Force is inversely proportional to the distance^distDecay.
		F = m.mass*obj.mass/(if distDecay is 2 then d2 else Math.pow(d2,distDecay/2)) 
		# Calculate vector projections. (update to shortcut functions?)
		alpha = Math.atan2(m.position.y-obj.position.y,m.position.x-obj.position.x)
		dfx = -Math.cos(alpha)*F
		dfy = -Math.sin(alpha)*F
		# Draw point-to-point vector.
		painter.drawLine(context, m.position, obj.position, {color: "#444", width: mm(0, F*50000,100)})
		# Multiplier
		multiplier = m.getMultiplier(obj)
		# Test if too close
		if d2 < Math.pow(obj.size+m.size,2)
			# console.log('too close', obj.size, m.size, Math.pow(obj.size+m.size,2), d2)
			fx += -Math.pow(reppel, 1)*dfx
			fy += -Math.pow(reppel, 1)*dfy
		else  
			fx += dfx * multiplier
			fy += dfy * multiplier

	# Draw resultant.
	painter.drawLine(context, m.position, {\
		x: m.position.x+fx*Math.pow(500000,1),\
		y: m.position.y+fy*Math.pow(500000,1)}, {color: "red"})
	return {x: fx, y: fy, angle: (if fx then Math.atan(fy/fx) else 0)+(if fx<0 then Math.PI else 0)}

class Drawable
	type: 'Drawable'
	multipliers: {}
	mass : 1
	angle: 0
	position: {x:0, y:0}
	angularSpeed: 0
	
	constructor: (@position=null) ->
		if @position is null
			@position = {x: Math.floor(Math.random()*canvas.width), y: Math.floor(Math.random()*canvas.height) }
		@vel = {x:0, y:0}
		@acc = {x:0, y:0}
		@twalk = 0
		@angle = Math.random()*Math.PI*2

		@defineWalk()
		@thrust = {a:.2,b:.2,c:.2,d:.2}
		
		@factor = {x: Math.random()>0.5?1:-1, y:Math.random()>0.5?1:-1}
	
	getMultiplier: (obj) ->
		if obj.type of @multipliers
			return @multipliers[obj.type]
		return 1

	defineWalk: ->
		# console.log('Defining twalk.')
		# max = 0.05
		# @vel.x = max*Math.random()-max/2
		# @vel.y = max*Math.random()-max/2
		# @angularSpeed *= (if @vel.x<0 then -1 else 1)
		# @twalk = Math.max(50, Math.floor(500*Math.random()))
		# # @angularSpeed = mm(0.00001, Math.random()*0.00001, 0.00002)

	ticTT: (step) ->
		step = window.vars.step # 100
		# Verlet Integration
		@_acc = {x: @acc.x, y: @acc.y}
		@position.x += @vel.x*step+(0.5*@_acc.x*step*step)
		@position.y += @vel.y*step+(0.5*@_acc.y*step*step)
		@acc = getResultant(@, game.board.state, 2, 4)
		@acc.x *= 1/@mass # add multipliers here
		@acc.y *= 1/@mass

		factor = step * window.vars.rest/100

		# Update velocity with average acceleration and defined factor
		@vel.x += (@_acc.x+@acc.x) / 2 * factor
		@vel.y += (@_acc.y+@acc.y) / 2 * factor

		wholevel = Math.sqrt(@vel.x*@vel.x + @vel.y*@vel.y)
		# # console.log(@angle, '\t', Math.sin(@angle))
		@vel.x = 1*@vel.x+0.01*wholevel*Math.cos(@angle)#*(@vel.x>0?1:-1)
		@vel.y = 1*@vel.y+0.01*wholevel*Math.sin(@angle)#*(@vel.y>0?1:-1)
		if not @twalk--
			@defineWalk()
		# if @ is lastAdded
		# 	console.log(@acc.angle)
		@angle += (@acc.angle-@angle)*0.2
		# @angle += -@angularSpeed * step * window.vars.anglemom # * Math.max(1, Math.pow(Math.abs(@acc.x)+Math.abs(@acc.y), 3) )/ @mass
		# # Bounce, please.
		# if canvas.height- @position.y < 0 or @position.y < 0 then @vel.y *= -0.5
		# if canvas.width - @position.x < 0 or @position.x < 0 then @vel.x *= -0.5
		# Limit particle to canvas bounds.
		@position.x = mm(0, @position.x, window.canvas.width)
		@position.y = mm(0, @position.y, window.canvas.height)

	render: (context) ->

class Triangle extends Drawable

	render: (context) ->
		@p1 = {x: 0, y: -1.154700*@size}
		@p2 = {x: -@size, y: 0.5773*@size}
		@p3 = {x: @size, y: 0.5773*@size}
		painter.drawCenteredPolygon(context, @position, [@p1,@p2,@p3], @angle, {color:@color})

class Circle extends Drawable
	
	color: "black"
	size: 10

	render: (context) ->
		# painter.drawCircle(context, @position, @size, {color: @color, fill: true})
		painter.drawCircle(context, @position, @size, {color: '#0D8', fill: true})

		@p1 = {x: @size/2, y: 0}
		@p2 = {x: -@size*2/3, y: @size/3}
		@p3 = {x: -@size*2/3, y: -@size/3}

		painter.drawCenteredPolygon(context, @position, [@p1,@p2,@p3], @angle, {color:'white', fill:true})

window.lastAdded = null

class Square extends Drawable

	color: "black"
	size: 15

	render: (context) =>
		painter.drawSizedRect(context, @position, {x:@size,y:@size}, @angle, {color:@color, fill:true})

class Food extends Triangle

	size: 5

	constructor: ->
		super
		@angularSpeed = Math.random()*20-10

	tic: (step) ->
		@angle += @angularSpeed * step

	eat: (eater) ->
		@position = {
			x: Math.random()*canvas.width,
			y: Math.random()*canvas.height
		}


class Bot extends Circle
	
	type: 'Bot'
	color: '#A2A'
	#multipliers: {'Bot': 0.01,'FixedPole': .5}
	size: 10
	#angularSpeed: .00001

	constructor: (@position) ->
		super
		window.lastAdded = @

	tic: (step) ->
		step = window.vars.step

		speed = 0.2

		@position.x += speed*Math.cos(@angle)*step # *(@_acc.x*step*step/2)
		@position.y += speed*Math.sin(@angle)*step # *(@_acc.y*step*step/2)

		# Limit particle to canvas bounds.
		@position.x = mod(@position.x,window.canvas.width)
		@position.y = mod(@position.y,window.canvas.height)

		for food in game.board.food
			if dist2(@position, food.position) < Math.pow(@size+food.size,2)
				food.eat(@)

		if window.leftPressed then @angle += 0.2
		# if window.upPressed then @thrust.b = 0.5 else @thrust.b = 0
		if window.rightPressed then @angle -= 0.2
		# if window.downPressed then @thrust.d = 0.5 else @thrust.d = 0

	render: (context) ->
		super
		context.lineWidth = @size-6
		angles = {a:[Math.PI, Math.PI*3/2], d:[Math.PI/2, Math.PI], c:[0, Math.PI/2], b:[Math.PI*3/2, 0]}
		context.save()
		context.translate(@position.x, @position.y)
		context.rotate(@angle)
		for t, a of angles
			context.beginPath()
			context.strokeStyle = "rgba(0,0,0,#{@thrust[t]})"
			context.arc(0, 0, @size/2+6, a[0], a[1]);
			context.stroke()
		context.restore()


class FixedPole extends Triangle

	type: 'FixedPole'
	color: "#08e"
	size: 30
	angularSpeed: .02

	tic: (step) ->
		step = 20
		@size = window.vars.polesize
		@angle += @angularSpeed * step

################################################################################
################################################################################

class Board

	addObject: (object) ->
		@state.push object

	addBot: (object) ->
		@bots.push object

	addFood: (object) ->
		@food.push object

	constructor: (@canvas) ->
		window.context = @canvas.getContext("2d")
		window.frame = 0
		window.vars = {}
		vars = _.map($(".control"), (i)-> i.id );
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
		@bots = []
		@food = []

		# @addBot(new Bot()) for i in [0..10]

		@addFood(new Food()) for i in [0..50]

	render: (context) ->
		item.render(context) for item in @state
		item.render(context) for item in @food
		item.render(context) for item in @bots

	tic: (step) ->
		window.frame++
		context.clearRect(0, 0, @canvas.width, @canvas.height)
		# painter.drawRectangle(context, {x:0,y:0}, {x:@canvas.width,y:@canvas.height}, 0, {color:"rgba(255,255,255,.1)", fill:true})
		item.tic(step) for item in @state
		item.tic(step) for item in @food
		item.tic(step) for item in @bots