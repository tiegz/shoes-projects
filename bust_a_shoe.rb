#
# Bust A Shoe - Tieg Zaharia
# 

# pseudocode:
# Draw a screen 
# Draw a ball at bottom of screen in center
# Onkeypress, shoot ball at an angle until it hits the top
# Draw the arm which shows the angle
# Let the user change the angle
# ...

class Bubble
  RADIUS = 25
  STEP = 20
  attr_writer :x
  attr_writer :y
  attr_accessor :dissolving
  attr_reader :opacity
  attr_reader :r, :g, :b, :a
  def initialize(x=0,y=0)
    @x, @y = x, y
    @r, @g, @b = *random_color_value
    @a = 1.0
    @stuck, @moving, @dissolving, @kapoot = false, false, false, false # STATES
    @angle = 0
  end
  def radius; RADIUS; end
  def diameter; RADIUS*2; end
  def x; @x - radius; end
  def y; @y - radius; end
  def stuck?; @stuck; end
  def color; [r,g,b,a]; end
  def random_color_value
    possible = [[30,10,50], [50,30,10]]
    possible[rand(possible.size)]
  end

  def fire(angle)
    @angle = angle
    @moving = true
  end
  
  def stick
    @moving = false
    @stuck = true
    adj_bubbles = get_adjacent_identical_bubbles
    $app.alert(adj_bubbles.map { |b| "[#{b.xbase}, #{b.ybase}]" }.join(', ')) unless adj_bubbles.empty?
    if !adj_bubbles.empty? && adj_bubbles.size > 1
      adj_bubbles << self unless adj_bubbles.include? self
      adj_bubbles.each { |b| b.dissolving = true }
    end
  end
  
  def get_adjacent_identical_bubbles(ary=[])
    directions = [[-1,-1], [0,-1], [-1,0], [-1,1], [0,1], [1,0], [1,-1]]
    directions.each do |pos|
      x, y = xbase + pos[0], ybase + pos[1]
      if adj = $app.bubble_at([x,y])
        ary << adj if (adj.color.to_s == color.to_s) && !ary.include?(adj)
        # recursively call this function here for every match
#       ary = ybase == 0 ? ary : ary.inject([]) { |all, bub| all + bub.get_adjacent_identical_bubbles(all) }.uniq
      end
    end
    ary
  end

  def xbase
    # unless @xbase
      @xbase, xmod = x.round/50, x.round%50
      @xbase += 1 if xmod >= radius
      @xbase
    # end
  end

  def ybase
    # unless @ybase
      @ybase, ymod = y.round/50, y.round%50
      @ybase += 1 if ymod >= radius
      @ybase
    # end
  end
  
  def calculate_stuck_position!
    @x = (ybase%2==0) ? (xbase*50)+radius : (xbase*50)
    @y = (ybase>0) ? (ybase*50)+(radius-(ybase*5)) : (ybase*50)+radius
  end
  
  def draw
    if @dissolving
      @a -= 0.1
      @kapoot = true and @dissolving = false if @a <= 0.1
    elsif @kapoot
      $app.bubbles.delete(self)
    end
    $app.fill $app.rgb(r,g,b,a) #$app.rgb(r,g,b,a)
    $app.stroke $app.rgb(0,0,0,a)
    $app.strokewidth 2
    $app.oval(x, y, diameter, diameter)

    if stuck?
      $app.para(xbase, :top => y+8, :left => x+11, :size => 10, :stroke => "FFF")
    end
  end

  def move
    if @moving
      @x += STEP*Math.cos(@angle)
      @y += STEP*Math.sin(@angle)
      if b = $app.bubbles.find { |b| xbase==b.xbase && ybase==b.ybase} # TODO improve circle collision
        @x -= STEP*Math.cos(@angle)
        collided = true
      end
      if b = $app.bubbles.find { |b| xbase==b.xbase && ybase==b.ybase } # TODO improve circle collision
        @y -= STEP*Math.sin(@angle)
        collided = true
      end
      stick if collided
      if y <= 0
        @y = radius
        stick
      end
      if x <= 0
        @x = radius
        @angle += 2*(Math::PIa - @angle) 
      elsif x >= $app.width-radius
        @x = $app.width-radius
        @angle -= 2*(@angle - Math::PI/2)
      end
    end
  end
end

Shoes.app :width => 400, :height => 600 do
  $app = self
  BOTTOM = 550
  MIDDLE = 200
  @pointer_angle = -Math::PI/2 # degrees
  @bubble = Bubble.new(MIDDLE, BOTTOM)
  @bubbles = []

  def bubbles; @bubbles; end
  def bubble_at(pos=[0,0]); @bubbles.find { |b| b.xbase == pos[0] && b.ybase == pos[1] }; end
  def draw_bubbles
    @bubbles.each { |b| b.draw }
    @bubble.draw
  end
  def draw_pointer
    radius = 75
    stroke rgb(0,0,0)
    strokewidth 4
    line MIDDLE, BOTTOM, MIDDLE+(radius*Math.cos(@pointer_angle)), BOTTOM+(radius*Math.sin(@pointer_angle))
  end
  def spew_bubble(b)
    draw_board
  end
  def draw_board
    clear do
      @bubble.move
      if @bubble.stuck?
        @bubble.calculate_stuck_position!
        @bubbles << @bubble
        @bubble = Bubble.new(MIDDLE, BOTTOM)
      end
      background '#315AA5'
      draw_pointer
      draw_bubbles
    end
  end
    
  stack :margin => 10 do
    animate(60) do
      draw_board
      
      keypress do |k|
        case k
        when /w/
          @bubble.fire(@pointer_angle)
        when /a/i
          @pointer_angle -= 0.05 unless @pointer_angle <= -Math::PI
        when /s/i
          @pointer_angle += 0.05 unless @pointer_angle >= 0
        end
      end
    end
  end
end
