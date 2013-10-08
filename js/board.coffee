
# board.coffee for nnaive

painter =
	applyCanvasOptions : (context, options) ->
		if options.fill is true
			context.fillStyle = options.color or 'black'
		else
			context.strokeStyle = options.color or 'black'
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
		context.moveTo(p1.x, p1.y)
		context.lineTo(p2.x, p2.y)
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

	drawCrown : (context, center, radius, angles=[0,Math.PI*2], angle=0, options={}) ->
		this.applyCanvasOptions(context,options)
		context.save()
		context.translate(center.x, center.y)
		context.rotate(angle)
		context.beginPath()
		context.arc(0, 0, radius, angles[0], angles[1]);
		context.stroke()
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
			context.translate((p1.x+p2.x)/2, (p1.y+p2.y)/2)
			context.rotate(angle)
			context.rect(p1.x, p1.y, p2.x-p1.x, p2.y-p1.y)
			context.restore()
		else
			context.rect(p1.x, p1.y, p2.x-p1.x, p2.y-p1.y)
		if options.fill
			context.fill()
		else context.stroke()

	# Draws a rectangle using the center and size (x:width,y:height) as parameters. 
	drawSizedRect : (context, point, size, angle=0, options={}) ->
		this.applyCanvasOptions(context, options)
		context.beginPath()
		if angle
			context.save()
			context.translate(point.x, point.y)
			context.rotate(angle)
			context.rect(-size.x/2, -size.y/2, size.x, size.y)
			context.restore()
		else
			context.rect(point.x-size.x/2, point.y-size.y/2, size.x, size.y)
		if options.fill
			context.fill()
		else context.stroke()

##########################################################################################
##########################################################################################

mod  = (a,n) -> ((a%n)+n)%n
dist2= (a,b) -> Math.pow(a.x-b.x,2)+Math.pow(a.y-b.y,2)
dist = (a,b) -> Math.sqrt(dist2(a,b))
mm = (a,num,b) -> Math.max(a,Math.min(num,b))

class Drawable
	type: 'Drawable'
	multipliers: {}
	angle: 0
	position: {x:0, y:0}
	angularSpeed: 0
	
	constructor: (@position=\
			{x:Math.floor(Math.random()*canvas.width),\
			y:Math.floor(Math.random()*canvas.height)}) ->
		@vel = {x:0, y:0}
		@acc = {x:0, y:0}
		@thrust = {a:.2,b:.2,c:.2,d:.2}
		@angle = Math.random()*Math.PI*2

	render: (context) ->
	
	tic: (step) -> 
		@angle += @angularSpeed * step

class Circle extends Drawable

	render: (context, color) ->
		painter.drawCircle(context, @position, @size, {color:color, fill:true})

class Square extends Drawable

	render: (context) =>
		painter.drawSizedRect(context, @position, {x:@size,y:@size}, @angle, {color:@color, fill:true})

class Triangle extends Drawable

	render: (context) ->
		@p1 = {x: 0, y: -1.154700*@size}
		@p2 = {x: -@size, y: 0.5773*@size}
		@p3 = {x: @size, y: 0.5773*@size}
		painter.drawCenteredPolygon(context, @position, [@p1,@p2,@p3], @angle, {color:@color, fill:true})

class FixedPole extends Circle
	
	color: 'grey'
	size: 70

	tic: (step) ->
		super

class Food extends Triangle

	size: 5
	color: '#25A'

	constructor: ->
		super
		@angularSpeed = Math.random()*4-2

	eat: (eater) -> # reset position.
		@position = {x: Math.random()*canvas.width,	y: Math.random()*canvas.height}

class _Bot extends Circle
	
	color: '#F5A'
	size: 10
	closestFood: null

	constructor: (@position) ->
		super
		window.lastAdded = @
		@lastOutput = [0,0]

	tic: (step) ->
		# Set @closestFood
		@closestFood = @closestFood or game.board.food[0]
		@closestFood.color = '#25A'
		for food in game.board.food[1..]
			if dist2(@position,food.position) < dist2(@position,@closestFood.position)
				@closestFood = food
		@closestFood.color = '#F22'
		# Get output from Neural Network and update
		@lastOutput = @nn.fire([Math.atan2(@position.y-@closestFood.position.y,@position.x-@closestFood.position.x)-@angle])
		@angle += @lastOutput[0]-@lastOutput[1]
		# Limit particle to canvas bounds.
		@position.x = mod(@position.x+@speed*Math.cos(@angle)*step,window.canvas.width)
		@position.y = mod(@position.y+@speed*Math.sin(@angle)*step,window.canvas.height)
		
	render: (context) ->

		radius = @size/2+8+2*@fitness
		opacity = (@lastOutput[0]-@lastOutput[1])*10
		painter.drawCrown(context,@position,radius,[-Math.PI,0],@angle, {width:2, color:"rgba(0,0,0,#{mm(0,-opacity,1)})"})
		painter.drawCrown(context,@position,radius,[0,Math.PI], @angle, {width:2, color:"rgba(0,0,0,#{mm(0,opacity,1)})"})

		# Draw line to nearest food item.
		if @closestFood
			width = 100/Math.sqrt(Math.pow(@closestFood.position.x-@position.x,2)+Math.pow(@closestFood.position.y-@position.y,2))
			painter.drawLine(context, @position, @closestFood.position, {width:mm(0,width,1), color:'grey'})
		super
		# Draw middle triangle
		@p1 = {x: @size/2, y: 0}
		@p2 = {x: -@size*2/3, y: @size/3}
		@p3 = {x: -@size*2/3, y: -@size/3}
		painter.drawCenteredPolygon(context, @position, [@p1,@p2,@p3], @angle, {color:'white', fill:true})

	foundFood: ->
		if dist2(@position,@closestFood.position) < Math.pow(@size+@closestFood.size,2)
			@closestFood.eat(@)
			return yes
		return no

##########################################################################################
##########################################################################################

class Neuron

	sigmoid = (netinput, response) -> 1/(1+Math.exp(-netinput/response))
	
	constructor: (@nInputs) ->
		# Notice we're deliberately chosing to go for a nInputs+1 sized @weights
		# array, leaving space for the last item to be the bias weight.
		@weights = (0 for i in [0..@nInputs]) # Initialize to 0.

	fire: (input) ->
		out = 0
		console.assert(@weights.length is input.length+1, @weights.length)
		for value, i in input
			out += value*@weights[i]
		out += -1*@weights[@weights.length-1] # Add bias.
		return sigmoid(out, game.board.params.activationResponse)

	getWeights: -> @weights
	putWeights: (weights) ->
		@weights = weights.splice(0,@nInputs+1) # +1 for bias

class NeuronLayer
	
	constructor: (nNeurons, nInputs) ->
		@neurons = (new Neuron(nInputs) for i in [0...nNeurons])

	calculate: (input) ->
		output = []
		for neuron in @neurons
			output.push(neuron.fire(input))
		return output

	getWeights: -> _.flatten((neuron.getWeights() for neuron in @neurons))
	putWeights: (weights) ->
		for neuron in @neurons
			neuron.putWeights(weights)

class NeuralNet

	constructor: (layersConf, nInputs) ->
		@layers = []
		for e, i in layersConf
			@layers.push(new NeuronLayer(e, if i > 0 then layersConf[i-1] else nInputs))
	
	getWeights: -> _.flatten((layer.getWeights() for layer in @layers))	
	putWeights: (weights) ->
		# I'm setting these to work like streams: each neuron "splices" a bit of it.
		_weights = weights[..] # Make a copy in case the array needs to be used later.
		for layer in @layers
			layer.putWeights(_weights)
	
	fire: (inputNeurons) ->
		outputs = inputNeurons
		for layer in @layers
			outputs = layer.calculate(outputs)
		return outputs

##########################################################################################
##########################################################################################


class Bot extends _Bot
	
	constructor: (@weights, params, @color=@color) ->
		super()
		@speed = params.speed
		@fitness = 0
		@inEvidence = false
		$(@).bind('toggleEvidence', =>
			@inEvidence = not @inEvidence
			console.log('evidence?', @inEvidence))
		@nn = new NeuralNet(params.layersConf, params.nInputs)
		@nn.putWeights(@weights)

	reset: (params) -> # Is elite.
		@isElite = true
		@fitness = 0
		@speed = params.speed
		@closestFood = null

	render: (context) ->
		color = @color
		if @inEvidence
			painter.drawCircle(context, @position, @size+10, {color:'grey', fill:true})
		if game.board.stats.topBot is @ then color = 'black'
		else if @isElite then color = '#088'
		super(context, color)



class Board
	totalFitness: 0
	bestFitness: 0
	avgFitness: 0
	worstFitness: 0
	bestGenoma: null

	calcNumWeights = (matrix, nInputs) ->
		lastNum = nInputs
		numWeights = 0
		for e,i in matrix
			numWeights += (lastNum+1)*e
			lastNum = e
		return numWeights

	params:
		activationResponse: 1 					# for the sigmoid function
		ticsPerGen: 2000							# num of tics per generation
		mutationRate: 0.1 						# down to 0.05
		foodDensity: 0.4						# per 100x100 px² squares
		popSize: 20
		crossoverRate: 0.7
		maxMutationFactor: 0.3
		nInputs: 1
		speed: 50
		layersConf: [5,2]
		numWeights: null # calcNumWeights(this.layersConf) # Initialized in constructor

	stats:
		foodEaten: 0
		genCount: 0

	leaveEvidence: ->
		if @inEvidence then @inEvidence.inEvidence = false
		game.panel.hide()

	showSpecs: (pos) ->
		$(@inEvidence)?.trigger('toggleEvidence') if @inEvidence
		@inEvidence = null
		stop = false
		for bot in @pop
			if Math.pow(bot.size,2) > dist2(pos,bot.position)
				stop = true
				@inEvidence = bot
				$(@inEvidence)?.trigger('toggleEvidence')
				game.panel.show()
		window.canvasStop = stop

	genRandBot: -> new Bot(Math.random()-Math.random() for i2 in [0...@params.numWeights], @params)

	crossover: (mum, dad) ->
		if mum is dad or @params.crossoverRate < Math.random()
			return [mum[..], dad[..]]
		baby1 = []
		baby2 = []
		cp = Math.floor(Math.random()*mum.length)
		for i in [0...cp]
			baby1.push(mum[i])
			baby2.push(dad[i])
		for i in [cp...mum.length]
			baby1.push(dad[i])
			baby2.push(mum[i])
		return [baby1, baby2]

	mutate: (crom) ->
		mutated = false
		for e,i in crom
			if Math.random() < @params.mutationRate
				crom[i] = mm(-@params.maxMutationFactor,Math.random()-Math.random(),@params.maxMutationFactor)
				mutated = true
		if mutated
			++@stats.mutated
		return crom

	getChromoRoulette = (population) ->
		slice = Math.random()*_.reduce(_.pluck(population, 'fitness'),((a,b)->a+b))
		fitnessCount = 0
		for g in population by -1
			fitnessCount += g.fitness
			if fitnessCount >= slice
				console.log('selected for roulette:',g.fitness)
				return g
		# console.log('não', _.reduce(population,(a,b)->a.fitness+b.fitness), population)

	makeNew: (popSize, numWeights) ->
		@pop = []
		for i in [0...popSize]
			@pop.push(@genRandBot())
		@pop

	epoch: (oldpop) ->
		sorted = _.sortBy(oldpop, (a) -> a.fitness).reverse()
		newpop = []
		console.log('sorted: (%s)', sorted.length, _.pluck(sorted,'fitness'))
		
		for g in sorted[..5] # Use parameters
			g.reset(@params)
			newpop.push(g)

		newpop.push(new Bot(@mutate(sorted[0].weights[..]), @params, 'green'))
		newpop.push(new Bot(@mutate(sorted[1].weights[..]), @params, 'green'))
		newpop.push(new Bot(@mutate(sorted[2].weights[..]), @params, 'green'))

		newpop.push(new Bot(@crossover(sorted[0].weights[..],sorted[1].weights[..])[0], @params, 'yellow'))
		newpop.push(new Bot(@crossover(sorted[0].weights[..],sorted[2].weights[..])[1], @params, 'yellow'))

		@stats.mutated = 0
		# Generate until population cap is reached.
		while newpop.length < @params.popSize
			mother = getChromoRoulette(sorted)
			father = getChromoRoulette(sorted)
			if mother.fitness is 0 or father.fitness is 0
				console.log('fitness 0. making random')
				mother = @genRandBot()
			[baby1, baby2] = @crossover(mother.weights, father.weights)
			@mutate(baby1)
			@mutate(baby2)
			newpop.push(new Bot(baby1,@params))
			newpop.push(new Bot(baby2,@params))
		console.log('mutated:',@stats.mutated)
		return newpop

	constructor: ->
		@params.numWeights = calcNumWeights(@params.layersConf,@params.nInputs)
		@tics = @stats.genCount = 0
		@makeNew(@params.popSize, @params.numWeights)
		
		foodCount = Math.round(@params.foodDensity*canvas.height*canvas.width/10000)
		console.log("Making #{foodCount} of food for generation #{@stats.genCount}.")
		@food = (new Food() for i in [0..foodCount])

	tic: (step) ->
		# painter.drawRectangle(context, {x:0,y:0},
		# {x:canvas.width,y:canvas.height}, 0, {color:"rgba(255,255,255,.3)", fill:true})
		
		bestBot = @stats.topBot or @pop[0]
		if ++@tics < @params.ticsPerGen
			for bot in @pop
				bot.tic(step)
				bestBot = bot if bot.fitness > bestBot.fitness
				if bot.foundFood()
					++bot.fitness
					++@stats.foodEaten
		else @reset()
		@stats.topBot = bestBot

		item.tic(step) for item in @food

	render: (context) ->
		context.clearRect(0, 0, canvas.width, canvas.height)
		item.render(context) for item in @food
		item.render(context) for item in @pop

	reset: ->
		++@stats.genCount
		console.log("Ending generation #{@stats.genCount}. #{(@stats.foodEaten/@params.popSize).toFixed(2)}")
		$("#flags #lastEat").html("Last generation ate: "+(@stats.foodEaten/@params.popSize).toFixed(2))
		$("#flags #generation").html(@stats.genCount)
		
		foodCount = Math.round(@params.foodDensity*canvas.height*canvas.width/10000)
		console.log("Making #{foodCount} of food for generation #{@stats.genCount}.")
		@food = (new Food() for i in [0..foodCount])
		@tics = @stats.foodEaten = 0
		@pop = @epoch(@pop)

##########################################################################################
##########################################################################################
