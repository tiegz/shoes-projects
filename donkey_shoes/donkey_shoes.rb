#
#  untitled
#
#  Created by Tieg Zaharia on 2008-11-26.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

$dir = `pwd`.strip # Easier way to do this?

module DK
  class Sprite
    def initialize(options={})
      @x        = options[:x] || 0
      @y        = options[:y] || 0
      @stack    = draw_stack
      @state    = nil
    end
    # ex: Sprite.define_states({:stand => [0,10]})
    def self.define_states(states={})
      (@@states = states).each_pair do |meth, position|
        # TODO use define_method instead?
        eval %Q!
        def #{meth}
          @state = :#{meth}
          @img.style :left => -#{position[0]}, :top => -#{position[1]}
        end
        def #{meth}?
          @state == :#{meth}
        end!
      end
    end
    
    # ex: Sprite.add_cycle(:walk, [:stand, :walk_one, :walk_two])
    def self.add_cycle(meth, state_names={})
      raise "Already defined method '#{meth}'" if @@states.has_key?(meth.to_sym)
      @@cycles ||= {}
      @@cycles[meth.to_sym] = state_names
      eval %Q!
      def #{meth}
        @#{meth} = @#{meth} ? @#{meth}+1 : 0
        @#{meth} = 0 if @#{meth} >= @@cycles[:#{meth}].size

        send(@@cycles[:#{meth}][@#{meth}])
      end!
    end
  
    def draw_stack
      @img_stack = $app.stack :width => self.width, :height => self.height, :left => @x, :top => @y do
        @img = $app.image img_path
      end
    end
    
    # Overwrite these for custom attributes
    def img_path() "#{$dir}/sprites.gif"; end # 278px x 240px
    def width() 278; end
    def height() 240; end

    def left() @img_stack.left; end
    def left=(val) @img_stack.left = val; end
    def top() @img_stack.top; end # this is actually the bottom of the sprite
    def top=(val) @img_stack.top = val; end

    def move_horiz(val) @img_stack.left += val; end
    def move_vert(val) @img_stack.top += val; end
  end
  
  class Barrel < Sprite
    def width() 20; end
    def height() 35; end

    define_states :sit => [5, 0]
  end

  class DonkeyKong < Sprite
    def width() 46; end
    def height() 40; end

    define_states :stand => [26, 0], :hold_barrel => [76, 0], 
                  :left_arm => [26, 40], :right_arm => [76, 40],
                  :climb_one => [24, 80], :climb_two => [70, 80], 
                  :hang_one => [28, 120], :hang_two => [72, 120], 
                  :walk_left => [22, 160], :walk_right => [74, 160],
                  :crazy => [17, 204]
  end
  
  class Mario < Sprite
    attr_accessor :jumping
    def initialize(*args)
      super(*args)
      @jumping = 0
      @ladder = nil
    end

    def jumping?
      @jumping > 0
    end
    
    def jump
      if @jumping < 5
        move_vert(-2)
      else
        move_vert(2)
      end
      @jumping += 1
      @jumping = 0 if @jumping >= 10 || on_piece?
    end

    def climbing?
      @ladder
    end

    def climb_ladder(val=-2)
      if @ladder || (@ladder = adjacent_ladder)
        move_vert(val)
        if just_below_piece?
          climb_over_two
          move_vert(-1) while below_piece?
          move_vert(1) while above_piece?
          @ladder = nil
        else
          climb
        end
      end
    end

    def move_horiz(val)
      @ladder = nil
      return false if (left+val) < 0

      super(val)
#      $app.alert("falling") if !above_piece? && !below_piece?
      $app.fall_animation.toggle if !below_piece? && !above_piece?
      #   end
      move_vert(-1) while below_piece?
      move_vert(1) while above_piece?
    end
    
    # return the closest ladder if Mario is near one
    def adjacent_ladder
      $app.ladders.find { |_|
        _.pieces.find { |piece| (piece[0]-20..(piece[0]+height-10)).include?(left) && (top <= piece[3] && top >= piece[1]) }
      }
    end
    
    # is Mario near the top of the closest piece?
    def just_below_piece?
      $app.platforms.any? { |_|
        _.pieces.any? { |piece| (piece[0]..piece[0]+Platform::WIDTH).include?(left) && top < piece[1]-Platform::HEIGHT && top > piece[1]-Platform::HEIGHT-6 }
      }
    end
    
    # is Mario below the top of the closest piece?
    def below_piece?
      $app.platforms.any? { |_|
        _.pieces.any? { |piece| (piece[0]..piece[0]+Platform::WIDTH).include?(left) && top < piece[1]-Platform::HEIGHT && top > piece[1]-Platform::HEIGHT-10 }
      }
    end

    def just_above_piece?
      $app.platforms.any? { |_|
        _.pieces.any? { |piece| (piece[0]..piece[0]+Platform::WIDTH).include?(left) && top < piece[1]-Platform::HEIGHT-7 && top > piece[1]-Platform::HEIGHT-13 }
      }
    end

    # is Mario on top of the closest piece?
    def above_piece?
      $app.platforms.any? { |_|
        _.pieces.any? { |piece| (piece[0]..piece[0]+Platform::WIDTH).include?(left) && top < piece[1]-Platform::HEIGHT-7 && top > piece[1]-Platform::HEIGHT-30 }
      }
    end

    # is Mario directly on top of the closest piece?
    def on_piece?
      $app.platforms.any? { |_|
        _.pieces.any? { |piece| (piece[0]..piece[0]+Platform::WIDTH).include?(left) && top == piece[1]-Platform::HEIGHT-8 }
      }
    end

    def img_path() "#{$dir}/mario.gif"; end
    def width() 27; end
    def height() 29; end
    
    define_states :stand => [-1, 0], :run_one => [28, 0], :run_two => [55, 0],
                  :climb_one => [85, 0], :climb_two => [115, 0], 
                  :climb_over_one => [142, 0], :climb_over_two => [170, 0]
    
    add_cycle(:walk, [:stand, :run_one, :run_two])
    add_cycle(:climb, [:climb_over_two, :climb_one, :climb_two])
    add_cycle(:climb_over, [:climb_one, :climb_two, :climb_over_one, :climb_over_two])
  end

  class Platform
    WIDTH = 35
    HEIGHT = 21

    attr_reader :pieces

    def initialize(*coords)
      @pieces = []
      coords.each do |coord|
        @pieces << [coord[0], coord[1], coord[0]+WIDTH, coord[1]+HEIGHT] # left, top, right, bottom
        $app.stack :left => coord[0], :top => coord[1], :width => WIDTH, :height => HEIGHT do
          $app.fill "#{$dir}/platform.gif"
          $app.rect :left => 0, :top => 0, :width => WIDTH, :height => HEIGHT
        end
      end
    end
  end

  class Ladder
    WIDTH = 20

    attr_reader :pieces, :height

    def initialize(height, *coords)
      @height = height
      @pieces = []
      coords.each do |coord|
        @pieces << [coord[0], coord[1]-height, coord[0]+WIDTH, coord[1]] # coords: left, top, right, bottom
        $app.stack :left => coord[0], :top => coord[1], :width => WIDTH, :height => height do
          $app.fill "#{$dir}/ladder.gif"
          $app.rect :left => 0, :top => 0, :width => WIDTH, :height => height
        end
      end
    end
  end
end

Shoes.app :width => 600, :height => 600 do
  $app = self
  def platforms() @platforms ||= []; end
  def ladders()   @ladders ||= []; end

  background "#111"
  
  stack do # :top => 0, :left => 32 do
    # 1st level
    platforms << DK::Platform.new([0,579],[35,579],[70,579],[105,579],[140,579],[175,579],[210,579])
    platforms << DK::Platform.new([245,577],[280,575],[315,573],[350,571],[385,569],[420,567],[455,565])
    ladders << DK::Ladder.new(10, [180,520])
    ladders << DK::Ladder.new(20, [180,560])
    ladders << DK::Ladder.new(32, [400,538])

    # 2nd level
    platforms << DK::Platform.new([420,520],[385,518],[350,516],[315,514],[280,512],[245,510],[210,508],
                                  [175,506],[140,504],[105,502],[70,500],[35,498],[0,496])

    # 3rd level
    platforms << DK::Platform.new([35,450],[70,448],[105,446],[140,444],[175,442],[210,440],[245,438],[280,436],
                                  [315,434],[350,432],[385,430],[420,428],[455,426])

    @barrel = DK::Barrel.new :x => 50, :y => 545
    @barrel.sit

    @mario = DK::Mario.new :x => 10, :y => 550
    @mario.stand

    @donkey_kong = DK::DonkeyKong.new
    @donkey_kong.stand
    
  end

  # animate(60) do
  #   @mario.jump if @mario.jumping?
  # end
  
  def fall_animation
    @fall_animation ||= animate(60) {
      if @mario.above_piece?
        @fall_animation.toggle
        @mario.move_vert(-1) while @mario.below_piece?
        @mario.move_vert(1) while @mario.above_piece?
      end
      
      @mario.move_vert(4)
    }
  end
  
  keypress do |k|
    case k
    when :left
      @mario.move_horiz(-8)
      @mario.walk
    when :right
      @mario.move_horiz(8)
      @mario.walk
    when :down
      @mario.climb_ladder(4)
    when :up
      # @mario.jump # is there even jumping?
      @mario.climb_ladder(-4)
    end
  end
  
end

