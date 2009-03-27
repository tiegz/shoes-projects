class CubeDrawer
  @@x, @@y, @@z = 0, 0, 0

  def initialize
    @grid = []
  end
  
  def <<(cube)
    @grid << cube
#    cube.draw
  end
  
  
  def self.draw() Cube.new; end
  def self.move(x=0, y=0, z=0) @@x += x; @@y += y; @@z += z; end

  def self.x() @@x; end
  def self.y() @@y; end
  def self.z() @@z; end
  
  def self.north(spaces=1)     spaces.times { @@y -= 1; draw } end
  def self.east(spaces=1)      spaces.times { @@x += 1; draw } end
  def self.south(spaces=1)     spaces.times { @@y += 1; draw } end
  def self.west(spaces=1)      spaces.times { @@x -= 1; draw } end
  def self.down(spaces=1)      spaces.times { @@z -= 1; draw } end
  def self.up(spaces=1)        spaces.times { @@z += 1; draw } end
  def self.northeast(spaces=1) spaces.times { @@y -= 1; @@x +=1; draw } end
  def self.northwest(spaces=1) spaces.times { @@y -= 1; @@x -= 1; draw } end
  def self.southeast(spaces=1) spaces.times { @@y += 1; @@x +=1; draw } end
  def self.southwest(spaces=1) spaces.times { @@y += 1; @@x -= 1; draw } end

  def self.r() 
    move(16, 6, 0)
    draw
    south(6)
    move(0, -6, 0)
    east(2)
    down
    south
    move(-2, 1, 0)
    draw
    east(2)
    move(-2, 1, 0)
    draw
    southeast(2)
    # southwest(6)
    # northeast(0)
    # draw
    # move(6, 6, 0)
    # southeast(3)
    # south
    # north(6)
    # east(2)
    # southeast
    # south(2)
    # west(2)
    # south
    # southeast(2)
    # move(3, -6, 0)
  end
  
end

class Cube
  H = 10
  W = 20
  def initialize
    # $app.stack :top => (H * CubeDrawer.y), :left => (W * CubeDrawer.x) do
    $app.stack :top => ((CubeDrawer.x * 10) + (CubeDrawer.y * 10) - (CubeDrawer.z * 20)), 
               :left => ((CubeDrawer.x * 20) + (CubeDrawer.y * -20)) do
      $app.fill "#FEFEFE"
      $app.stroke "#000000"
      $app.strokewidth 1
      $app.shape do
        $app.move_to(0, 10) and $app.line_to(20, 20) and $app.line_to(40, 10) and $app.line_to(20, 0) and $app.line_to(0, 10)
      end
      $app.fill "#fff".."#eed"
      $app.shape do
        $app.move_to(0, 10) and $app.line_to(0, 35) and $app.line_to(20, 45) and $app.line_to(20, 20)
      end
      $app.fill "#fff".."#eed"
      $app.shape do
        $app.move_to(20, 20) and $app.line_to(20, 45) and $app.line_to(40, 35) and $app.line_to(40, 10)
      end
    end
  end
end

Shoes.app :title => "Block Drawerer", :width => 800, :height => 600, :resizable => true do
  $app = self

  stack :margin_top => 0 do
    stack :height => 30 do
      background darkgray
      para strong('Block Drawerer'), :stroke => white
    end
    stack :top => 30 do
      CubeDrawer.r
    end
  end
end
