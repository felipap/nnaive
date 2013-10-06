// Generated by CoffeeScript 1.6.3
var Board, Bot, Circle, Drawable, FixedPole, Food, GeneticEngine, NeuralNet, Neuron, NeuronLayer, Square, Triangle, calcNumWeights, dist, dist2, genEng, mod, painter, parameters, sigmoid, _Bot, _ref, _ref1, _ref2, _ref3,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

painter = {
  applyCanvasOptions: function(context, options) {
    if (options.fill === true) {
      return context.fillStyle = options.color || 'black';
    } else {
      context.strokeStyle = options.color || 'blue';
      return context.lineWidth = options.width || 1;
    }
  },
  drawCircle: function(context, position, radius, options) {
    if (radius == null) {
      radius = 2;
    }
    if (options == null) {
      options = {};
    }
    this.applyCanvasOptions(context, options);
    context.beginPath();
    context.arc(position.x, position.y, radius, 0, 2 * Math.PI, true);
    if (options.fill) {
      return context.fill();
    } else {
      return context.stroke();
    }
  },
  drawLine: function(context, p1, p2, options) {
    if (options == null) {
      options = {};
    }
    this.applyCanvasOptions(context, options);
    context.beginPath();
    context.moveTo(p1.x, p1.y);
    context.lineTo(p2.x, p2.y);
    return context.stroke();
  },
  drawTriangle: function(context, p1, p2, p3, options) {
    if (options == null) {
      options = {};
    }
    this.applyCanvasOptions(context, options);
    context.beginPath();
    context.moveTo(p1.x, p1.y);
    context.lineTo(p2.x, p2.y);
    context.lineTo(p3.x, p3.y);
    context.closePath();
    return context.stroke();
  },
  drawCenteredPolygon: function(context, center, points, angle, options) {
    var point, _i, _len, _ref;
    if (angle == null) {
      angle = 0;
    }
    if (options == null) {
      options = {};
    }
    this.applyCanvasOptions(context, options);
    context.save();
    context.translate(center.x, center.y);
    context.rotate(angle);
    context.beginPath();
    context.moveTo(points[0].x, points[0].y);
    _ref = points.slice(1);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      point = _ref[_i];
      context.lineTo(point.x, point.y);
    }
    context.closePath();
    if (options.fill) {
      context.fill();
    } else {
      context.stroke();
    }
    return context.restore();
  },
  drawPolygon: function(context, points, options) {
    var point, _i, _len, _ref;
    if (options == null) {
      options = {};
    }
    this.applyCanvasOptions(context, options);
    context.beginPath();
    context.moveTo(points[0].x, points[0].y);
    _ref = points.slice(1);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      point = _ref[_i];
      context.lineTo(point.x, point.y);
    }
    context.lineTo(points[0].x, points[0].y);
    context.closePath();
    if (options.fill) {
      return context.fill();
    } else {
      return context.stroke;
    }
  },
  drawRectangle: function(context, p1, p2, angle, options) {
    if (angle == null) {
      angle = 0;
    }
    if (options == null) {
      options = {};
    }
    this.applyCanvasOptions(context, options);
    context.beginPath();
    if (angle !== 0) {
      context.save();
      context.translate((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
      context.rotate(angle);
      context.rect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
      context.restore();
    } else {
      context.rect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
    }
    if (options.fill) {
      return context.fill();
    } else {
      return context.stroke();
    }
  },
  drawSizedRect: function(context, point, size, angle, options) {
    if (angle == null) {
      angle = 0;
    }
    if (options == null) {
      options = {};
    }
    this.applyCanvasOptions(context, options);
    context.beginPath();
    if (angle) {
      context.save();
      context.translate(point.x, point.y);
      context.rotate(angle);
      context.rect(-size.x / 2, -size.y / 2, size.x, size.y);
      context.restore();
    } else {
      context.rect(point.x - size.x / 2, point.y - size.y / 2, size.x, size.y);
    }
    if (options.fill) {
      return context.fill();
    } else {
      return context.stroke();
    }
  }
};

mod = function(a, n) {
  return ((a % n) + n) % n;
};

dist2 = function(a, b) {
  return Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2);
};

dist = function(a, b) {
  return Math.sqrt(dist2(a, b));
};

Drawable = (function() {
  Drawable.prototype.type = 'Drawable';

  Drawable.prototype.multipliers = {};

  Drawable.prototype.angle = 0;

  Drawable.prototype.position = {
    x: 0,
    y: 0
  };

  Drawable.prototype.angularSpeed = 0;

  function Drawable(position) {
    this.position = position != null ? position : {
      x: Math.floor(Math.random() * canvas.width),
      y: Math.floor(Math.random() * canvas.height)
    };
    this.vel = {
      x: 0,
      y: 0
    };
    this.acc = {
      x: 0,
      y: 0
    };
    this.thrust = {
      a: .2,
      b: .2,
      c: .2,
      d: .2
    };
    this.angle = Math.random() * Math.PI * 2;
  }

  Drawable.prototype.render = function(context) {};

  Drawable.prototype.tic = function(step) {
    return this.angle += this.angularSpeed * step;
  };

  return Drawable;

})();

Circle = (function(_super) {
  __extends(Circle, _super);

  function Circle() {
    _ref = Circle.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Circle.prototype.render = function(context) {
    return painter.drawCircle(context, this.position, this.size, {
      color: this.color,
      fill: true
    });
  };

  return Circle;

})(Drawable);

Square = (function(_super) {
  __extends(Square, _super);

  function Square() {
    this.render = __bind(this.render, this);
    _ref1 = Square.__super__.constructor.apply(this, arguments);
    return _ref1;
  }

  Square.prototype.render = function(context) {
    return painter.drawSizedRect(context, this.position, {
      x: this.size,
      y: this.size
    }, this.angle, {
      color: this.color,
      fill: true
    });
  };

  return Square;

})(Drawable);

Triangle = (function(_super) {
  __extends(Triangle, _super);

  function Triangle() {
    _ref2 = Triangle.__super__.constructor.apply(this, arguments);
    return _ref2;
  }

  Triangle.prototype.render = function(context) {
    this.p1 = {
      x: 0,
      y: -1.154700 * this.size
    };
    this.p2 = {
      x: -this.size,
      y: 0.5773 * this.size
    };
    this.p3 = {
      x: this.size,
      y: 0.5773 * this.size
    };
    return painter.drawCenteredPolygon(context, this.position, [this.p1, this.p2, this.p3], this.angle, {
      color: this.color,
      fill: true
    });
  };

  return Triangle;

})(Drawable);

FixedPole = (function(_super) {
  __extends(FixedPole, _super);

  function FixedPole() {
    _ref3 = FixedPole.__super__.constructor.apply(this, arguments);
    return _ref3;
  }

  FixedPole.prototype.color = 'grey';

  FixedPole.prototype.size = 70;

  FixedPole.prototype.tic = function(step) {
    return FixedPole.__super__.tic.apply(this, arguments);
  };

  return FixedPole;

})(Circle);

Food = (function(_super) {
  __extends(Food, _super);

  Food.prototype.size = 5;

  Food.prototype.color = 'blue';

  function Food() {
    Food.__super__.constructor.apply(this, arguments);
    this.angularSpeed = Math.random() * 4 - 2;
  }

  Food.prototype.eat = function(eater) {
    return this.position = {
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height
    };
  };

  return Food;

})(Triangle);

_Bot = (function(_super) {
  __extends(_Bot, _super);

  _Bot.prototype.color = '#A2A';

  _Bot.prototype.size = 10;

  _Bot.closestFood = null;

  function _Bot(position) {
    this.position = position;
    _Bot.__super__.constructor.apply(this, arguments);
    window.lastAdded = this;
  }

  _Bot.prototype.tic = function(step) {
    var food, output, speed, _i, _len, _ref4;
    speed = 100;
    this.position.x += speed * Math.cos(this.angle) * step;
    this.position.y += speed * Math.sin(this.angle) * step;
    this.position.x = mod(this.position.x, window.canvas.width);
    this.position.y = mod(this.position.y, window.canvas.height);
    this.closestFood = this.closestFood || game.board.food[0];
    this.closestFood.color = 'blue';
    _ref4 = game.board.food.slice(1);
    for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
      food = _ref4[_i];
      if (dist2(this.position, food.position) < dist2(this.position, this.closestFood.position)) {
        this.closestFood = food;
      }
    }
    painter.drawLine(context, this.position, this.closestFood.position, {
      width: 1,
      color: 'grey'
    });
    this.closestFood.color = 'red';
    output = this.nn.fire([Math.atan2(this.closestFood.position.y - this.position.y, this.closestFood.position.x - this.position.x), this.angle]);
    if (this === window.lastAdded) {
      this.color = 'red';
      console.log([Math.atan2(this.closestFood.position.y - this.position.y, this.closestFood.position.x - this.position.x), this.angle, output[0]]);
    }
    this.angle += output[0] - output[1];
    /*
    		context.lineWidth = @size-6
    		angles = {x:[Math.PI, Math.PI*3/2], y:[Math.PI*3/2, 0]}
    		context.save() 
    		context.translate(@position.x, @position.y)
    		context.rotate(@angle)
    		for t, a of angles
    			context.beginPath()
    			context.strokeStyle = "rgba(0,0,0,#{@thrust[t]})"
    			context.arc(0, 0, @size/2+6, a[0], a[1]);
    			context.stroke()
    		context.restore()
    */

    if (window.leftPressed) {
      this.angle += 0.2;
    }
    if (window.rightPressed) {
      return this.angle -= 0.2;
    }
  };

  _Bot.prototype.render = function(context) {
    _Bot.__super__.render.apply(this, arguments);
    this.p1 = {
      x: this.size / 2,
      y: 0
    };
    this.p2 = {
      x: -this.size * 2 / 3,
      y: this.size / 3
    };
    this.p3 = {
      x: -this.size * 2 / 3,
      y: -this.size / 3
    };
    if (this.fitness) {
      painter.drawCircle(context, this.position, this.size + this.fitness * 4, {
        color: 'rgba(0,0,0,.4)'
      });
    }
    return painter.drawCenteredPolygon(context, this.position, [this.p1, this.p2, this.p3], this.angle, {
      color: 'white',
      fill: true
    });
  };

  _Bot.prototype.foundFood = function() {
    if (dist2(this.position, this.closestFood.position) < Math.pow(this.size + this.closestFood.size, 2)) {
      this.closestFood.eat(this);
      return true;
    }
    return false;
  };

  return _Bot;

})(Circle);

sigmoid = function(netinput, response) {
  return 1 / (1 + Math.exp(-netinput / response));
};

Neuron = (function() {
  function Neuron(nInputs) {
    var i;
    this.nInputs = nInputs;
    this.weights = (function() {
      var _i, _ref4, _results;
      _results = [];
      for (i = _i = 0, _ref4 = this.nInputs; 0 <= _ref4 ? _i <= _ref4 : _i >= _ref4; i = 0 <= _ref4 ? ++_i : --_i) {
        _results.push(0);
      }
      return _results;
    }).call(this);
  }

  Neuron.prototype.fire = function(input) {
    var i, out, value, _i, _len;
    out = 0;
    console.assert(this.weights.length === input.length + 1, this.weights.length);
    for (i = _i = 0, _len = input.length; _i < _len; i = ++_i) {
      value = input[i];
      out += value * this.weights[i];
    }
    out += -1 * this.weights[this.weights.length - 1];
    return sigmoid(out, parameters.activationResponse);
  };

  Neuron.prototype.getWeights = function() {
    return this.weights;
  };

  Neuron.prototype.putWeights = function(weights) {
    return this.weights = weights.splice(0, this.nInputs + 1);
  };

  return Neuron;

})();

NeuronLayer = (function() {
  function NeuronLayer(nNeurons, nInputs) {
    var i;
    this.neurons = (function() {
      var _i, _results;
      _results = [];
      for (i = _i = 0; 0 <= nNeurons ? _i < nNeurons : _i > nNeurons; i = 0 <= nNeurons ? ++_i : --_i) {
        _results.push(new Neuron(nInputs));
      }
      return _results;
    })();
  }

  NeuronLayer.prototype.calculate = function(input) {
    var neuron, output, _i, _len, _ref4;
    output = [];
    _ref4 = this.neurons;
    for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
      neuron = _ref4[_i];
      output.push(neuron.fire(input));
    }
    return output;
  };

  NeuronLayer.prototype.getWeights = function() {
    var neuron;
    return _.flatten((function() {
      var _i, _len, _ref4, _results;
      _ref4 = this.neurons;
      _results = [];
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        neuron = _ref4[_i];
        _results.push(neuron.getWeights());
      }
      return _results;
    }).call(this));
  };

  NeuronLayer.prototype.putWeights = function(weights) {
    var neuron, _i, _len, _ref4, _results;
    _ref4 = this.neurons;
    _results = [];
    for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
      neuron = _ref4[_i];
      _results.push(neuron.putWeights(weights));
    }
    return _results;
  };

  return NeuronLayer;

})();

NeuralNet = (function() {
  function NeuralNet(layersConf, nInputs) {
    var e, i, _i, _len;
    this.layers = [];
    for (i = _i = 0, _len = layersConf.length; _i < _len; i = ++_i) {
      e = layersConf[i];
      this.layers.push(new NeuronLayer(e, i > 0 ? layersConf[i - 1] : nInputs));
    }
  }

  NeuralNet.prototype.getWeights = function() {
    var layer;
    return _.flatten((function() {
      var _i, _len, _ref4, _results;
      _ref4 = this.layers;
      _results = [];
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        layer = _ref4[_i];
        _results.push(layer.getWeights());
      }
      return _results;
    }).call(this));
  };

  NeuralNet.prototype.putWeights = function(weights) {
    var layer, _i, _len, _ref4, _results, _weights;
    _weights = weights.slice(0);
    _ref4 = this.layers;
    _results = [];
    for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
      layer = _ref4[_i];
      _results.push(layer.putWeights(_weights));
    }
    return _results;
  };

  NeuralNet.prototype.fire = function(inputNeurons) {
    var layer, outputs, _i, _len, _ref4;
    outputs = inputNeurons;
    _ref4 = this.layers;
    for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
      layer = _ref4[_i];
      outputs = layer.calculate(outputs);
    }
    return outputs;
  };

  return NeuralNet;

})();

GeneticEngine = (function() {
  var avgFitness, bestFitness, bestGenoma, crossover, mutate, population, totalFitness, worstFitness;

  function GeneticEngine() {}

  population = [];

  totalFitness = 0;

  bestFitness = 0;

  avgFitness = 0;

  worstFitness = 0;

  bestGenoma = null;

  crossover = function(mum, dad) {
    var baby1, baby2, cp, i, _i, _j, _ref4;
    if (mum === dad || parameters.crossoverRate < Math.random()) {
      return [mum.slice(0), dad.slice(0)];
    }
    baby1 = [];
    baby2 = [];
    cp = Math.floor(Math.random() * mum.length);
    for (i = _i = 0; 0 <= cp ? _i < cp : _i > cp; i = 0 <= cp ? ++_i : --_i) {
      baby1.push(mum[i]);
      baby2.push(dad[i]);
    }
    for (i = _j = cp, _ref4 = mum.length; cp <= _ref4 ? _j < _ref4 : _j > _ref4; i = cp <= _ref4 ? ++_j : --_j) {
      baby1.push(dad[i]);
      baby2.push(mum[i]);
    }
    return [baby1, baby2];
  };

  mutate = function(a) {
    return a;
  };

  GeneticEngine.prototype.getChromoRoulette = function(population) {
    var fitnessCount, g, slice, _i, _len;
    slice = Math.random() * _.reduce(_.pluck(population, 'fitness'), (function(a, b) {
      return a + b;
    }));
    fitnessCount = 0;
    for (_i = 0, _len = population.length; _i < _len; _i++) {
      g = population[_i];
      fitnessCount += g.fitness;
      if (fitnessCount >= slice) {
        return g;
      }
    }
  };

  GeneticEngine.prototype.makeNew = function(popSize, numWeights) {
    var i, i2, pop, _i;
    pop = [];
    for (i = _i = 0; 0 <= popSize ? _i < popSize : _i > popSize; i = 0 <= popSize ? ++_i : --_i) {
      pop.push(new Bot((function() {
        var _j, _results;
        _results = [];
        for (i2 = _j = 0; 0 <= numWeights ? _j < numWeights : _j > numWeights; i2 = 0 <= numWeights ? ++_j : --_j) {
          _results.push(Math.random() - Math.random());
        }
        return _results;
      })()));
    }
    return pop;
  };

  GeneticEngine.prototype.reset = function() {};

  GeneticEngine.prototype.epoch = function(oldpop) {
    var baby1, baby2, father, g, mother, newpop, sorted, _i, _len, _ref4, _ref5;
    sorted = _.sortBy(oldpop, function(a) {
      return a.fitness;
    });
    newpop = [];
    _ref4 = sorted.slice(sorted.length - 5);
    for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
      g = _ref4[_i];
      g.reset();
      newpop.push(g);
      g.isTop = true;
    }
    while (newpop.length < parameters.popSize) {
      mother = this.getChromoRoulette(oldpop);
      father = this.getChromoRoulette(oldpop);
      _ref5 = crossover(mother.weights, father.weights), baby1 = _ref5[0], baby2 = _ref5[1];
      mutate(baby1);
      mutate(baby2);
      newpop.push(new Bot(baby1));
      newpop.push(new Bot(baby2));
    }
    return newpop;
  };

  return GeneticEngine;

})();

Bot = (function(_super) {
  __extends(Bot, _super);

  function Bot(weights) {
    this.weights = weights;
    Bot.__super__.constructor.call(this);
    this.fitness = 0;
    this.isTop = false;
    this.nn = new NeuralNet(window.layersConf, window.nInputs);
    this.nn.putWeights(this.weights);
  }

  Bot.prototype.reset = function() {
    return this.fitness = 0;
  };

  Bot.prototype.tic = function() {
    Bot.__super__.tic.apply(this, arguments);
    if (this.isTop) {
      return this.color = '#088';
    }
  };

  return Bot;

})(_Bot);

calcNumWeights = function(matrix, nInputs) {
  var e, i, lastNum, numWeights, _i, _len;
  lastNum = nInputs;
  numWeights = 0;
  for (i = _i = 0, _len = matrix.length; _i < _len; i = ++_i) {
    e = matrix[i];
    numWeights += (lastNum + 1) * e;
    lastNum = e;
  }
  return numWeights;
};

parameters = {
  activationResponse: 1,
  ticsPerGen: 2000,
  popSize: 20,
  crossoverRate: 0.7,
  mutationRate: 0.3,
  foodCount: 20
};

window.nInputs = 2;

window.layersConf = [5, 5, 5, 2];

window.numWeights = calcNumWeights(layersConf, window.nInputs);

window.stats = {
  foodEaten: 0,
  genCount: 0
};

window.tics = 0;

genEng = new GeneticEngine();

Board = (function() {
  function Board() {
    var i, _i, _ref4;
    this.bots = [];
    this.food = [];
    window.pop = genEng.makeNew(parameters.popSize, window.numWeights);
    for (i = _i = 0, _ref4 = parameters.foodCount; 0 <= _ref4 ? _i <= _ref4 : _i >= _ref4; i = 0 <= _ref4 ? ++_i : --_i) {
      this.food.push(new Food());
    }
  }

  Board.prototype.render = function(context) {
    var item, _i, _j, _len, _len1, _ref4, _ref5, _results;
    _ref4 = this.food;
    for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
      item = _ref4[_i];
      item.render(context);
    }
    _ref5 = this.bots;
    _results = [];
    for (_j = 0, _len1 = _ref5.length; _j < _len1; _j++) {
      item = _ref5[_j];
      _results.push(item.render(context));
    }
    return _results;
  };

  Board.prototype.tic = function(step) {
    var bot, food, item, _i, _j, _k, _len, _len1, _len2, _ref4, _ref5, _ref6, _results;
    context.clearRect(0, 0, canvas.width, canvas.height);
    if (++window.tics < parameters.ticsPerGen) {
      _ref4 = window.pop;
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        bot = _ref4[_i];
        bot.tic(step);
        if (bot.foundFood()) {
          ++bot.fitness;
          ++stats.foodEaten;
        }
      }
    } else {
      console.log("Ending generation " + window.stats.genCount + ". Next...");
      ++window.stats.genCount;
      $("#flags #stats").html("last eaten: " + (stats.foodEaten / parameters.popSize).toFixed(2));
      $("#flags #generation").html("generation: " + window.stats.genCount);
      _ref5 = game.board.food;
      for (_j = 0, _len1 = _ref5.length; _j < _len1; _j++) {
        food = _ref5[_j];
        food.eat();
      }
      window.tics = stats.foodEaten = 0;
      window.pop = genEng.epoch(window.pop);
    }
    _ref6 = this.food;
    _results = [];
    for (_k = 0, _len2 = _ref6.length; _k < _len2; _k++) {
      item = _ref6[_k];
      _results.push(item.tic(step));
    }
    return _results;
  };

  return Board;

})();
