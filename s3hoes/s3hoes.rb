Shoes.setup { gem 'aws-s3' }
require 'aws/s3'
require 'yaml'

class S3hoes
  attr_accessor :accounts

  def initialize
    @accounts = {}
    load_accounts
  end
  
  def account?(name)
    @accounts.keys.include?(name)
  end

  def load_accounts
    YAML.load_file('accounts.yml').each_pair do |name, details|
      add_account(name, details['key'], details['secret'])
    end
  end
  
  def add_account(name, key, secret, save_for_later=false)
    @accounts[name] = Account.new(name, key, secret)
  end
  
  class Account
    attr_reader :name, :key, :secret
    def initialize(name, key,secret)
      @name, @key, @secret = name, key, secret
    end

    def connect!
      AWS::S3::Base.establish_connection!(
         :access_key_id     => key,
         :secret_access_key => secret
       )
    end
    
    def buckets
      AWS::S3::Service.buckets
    end
  end
end

module S3hoesDrawingMethods
  def draw_everything
    clear do
      background gradient(beige, '#CECEBB')
      stack :margin => 10 do
        para strong("s3hoes"), em(" a window into your S3 sole", :size => 16), :family => "Georgia", :size => 20
        draw_accounts
      end
    end
  end
  
  def draw_accounts
    @toolbar ||= stack :margin => 10, :width => "100%"
    @toolbar.clear.append do
      if @s3hoes.accounts.empty?
        para strong("select an account:"), em(" no accounts yet")
      else
        para strong("select an account:")
        @list = list_box :top => 2, :left => 150, :width => 200, :items => @s3hoes.accounts.map { |k,v| k }.sort 
        button('load', :top => 0, :left => 350) do
          draw_account(@list.text) if !@list.text.empty?
        end
      end
      button "new", :top => 0, :left => 410 do
        name = ask("What name should we give it?").strip
        if !@s3hoes.account?(name) || (@s3hoes.account?(name) && confirm("'#{name}' already exists; overwrite?"))
          @s3hoes.add_account(
            name, 
            ask("What is the account key?"),
            ask("What is the secret key?", :secret => true),
            confirm("Save account info on your computer for later?")
          )
        end
        draw_accounts
      end
    end
  end
  
  def draw_account(name)
    @account = @s3hoes.accounts[name]
    @account.connect!
    @browser ||= stack :width => '100%', :margin => 20
    @browser.clear.append do
      if @account.buckets.empty? then em("You don't have any buckets yet!")
      else
        stack :width => "100%", :margin => [0,5], :height => 26 do
          flow(:width => '50%', :top => 0, :left => 0) { para strong("BUCKET"), :size => 10, :family => "Georgia" }
          flow(:width => '10%', :top => 0, :left => '50%') { para strong("SIZE"), :size => 10, :align => 'center', :family => "Georgia" }
          flow(:width => '40%', :top => 0, :left => '60%') { para strong("CREATED ON"), :align => 'right', :size => 10, :family => "Georgia" }
        end
        @account.buckets.each do |bucket|
          stack :width => "100%", :margin => [0,5], :height => 26 do
            background "#EFEFDD"
            flow(:width => '50%', :top => 0, :left => 0) { para(link(bucket.name, :stroke => black){ draw_bucket(bucket) }) }
            flow(:width => '10%', :top => 0, :left => '50%') { para bucket.size, :align => 'center', :size => 10 }
            flow(:width => '40%', :top => 0, :left => '60%') { para bucket.creation_date, :align => 'right', :size => 10 }
          end
        end
      end
    end
  end
  
  def draw_bucket(bucket, prefix=nil)
    @browser ||= stack :width => '100%', :margin_left => 20
    @browser.clear.append do
      if bucket.objects(:prefix => prefix).empty? then em("No files yet!")
      else
        objects                = bucket.objects
        objects_without_prefix = objects.select { |o| o.key !~ /\// }
        prefixes               = objects.map { |o| o.key }.
                                         select { |k| k =~ /\// }.
                                         map { |k| prefix.nil? ? k : k.gsub(/#{Regexp.escape(prefix)}\/?/, '') }.
                                         map { |k| k.split('/').first }.
                                         uniq
        
        ary = [link(strong("BUCKETS"), :stroke => black, :size => 10, :family => "Georgia") { draw_account(@account.name) }, ' / ']
        ary << link(strong(bucket.name.upcase), :stroke => black, :size => 10, :family => "Georgia") { draw_bucket(bucket) } unless prefix.nil?
        prefix.split('/').each { |p|
          ary += [' / ', link(p.upcase, :stroke => black, :size => 10, :family => "Georgia")]
        } unless prefix.nil?
        para ary, :top => 120
          
        stack :width => "100%", :margin => [0,5], :height => 26 do
          flow(:width => '50%', :top => 0, :left => 0) { para strong("NAME"), :size => 10, :family => "Georgia" }
          flow(:width => '10%', :top => 0, :left => '50%') { para strong("SIZE"), :size => 10, :align => 'center', :family => "Georgia" }
          flow(:width => '40%', :top => 0, :left => '60%') { para strong("MODIFIED ON"), :align => 'right', :size => 10, :family => "Georgia" }
        end
        prefixes.each do |p|
          stack :width => "100%", :margin => [0,5], :height => 26 do
            wouldbe_prefix = "#{prefix + '/' if prefix}#{p}"
            background "#EFEFDD"
            flow(:width => '50%', :top => 0, :left => 0) { para(link("#{p}/", :stroke => black){ alert(wouldbe_prefix); draw_bucket(bucket, wouldbe_prefix) }) }
            # flow(:width => '10%', :top => 0, :left => '50%') { para bucket.objects(, :align => 'center', :size => 10 }
            # extra attrs: owner, url, value, 
          end
        end
        objects_without_prefix.each do |object|
          stack :width => "100%", :margin => [0,5], :height => 26 do
            background "#EFEFDD"
            flow(:width => '50%', :top => 0, :left => 0) { para(link(object.key, :stroke => black){ }) }
            flow(:width => '10%', :top => 0, :left => '50%') { para object.size, :align => 'center', :size => 10 }
            flow(:width => '40%', :top => 0, :left => '60%') { para object.last_modified, :align => 'right', :size => 10 }
            # extra attrs: owner, url, value, 
          end
        end
      end
    end
  end
end

Shoes.app :title => "S3hoes", :width => 800, :height => 600, :resizable => true do
  extend S3hoesDrawingMethods
  @s3hoes = S3hoes.new

  draw_everything
  draw_account('tieg') # for testing
end
