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
      "Connection successful."
    rescue => e
      e
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
        # Breadcrumb
        para strong("> BUCKETS"), :stroke => black, :size => 10, :family => "Georgia", :top => 115

        # Header
        stack :width => "100%", :margin => [0,15,0,0] do
          flow(:width => '50%', :top => 0, :left => 0) { para strong("NAME"), :size => 14, :family => "Georgia" }
          flow(:width => '10%', :top => 0, :left => '50%') { para strong("SIZE"), :size => 14, :align => 'center', :family => "Georgia" }
          flow(:width => '40%', :top => 0, :left => '60%') { para strong("CREATED ON"), :size => 14, :align => 'right', :family => "Georgia" }
        end

        # File listing
        @account.buckets.each do |bucket|
          stack :width => "100%", :margin => [0,0,0,5] do
            background "#EFEFDD"
            flow(:width => '50%', :top => 5, :left => 0) { para(link(bucket.name, :stroke => black, :size => 12){ draw_bucket(bucket) }) }
            flow(:width => '10%', :top => 5, :left => '50%') { para bucket.size, :align => 'center', :size => 12 }
            flow(:width => '40%', :top => 5, :left => '60%') { para bucket.creation_date, :align => 'right', :size => 12 }
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
        objects_without_prefix = objects.select { |o| o.key.gsub("#{prefix.to_s + '/' if prefix}", '') !~ /\// }
        prefixes               = objects.map { |o| o.key }.
                                         map { |k| prefix.nil? ? k : k.gsub(/#{Regexp.escape(prefix)}\/?/, '') }.
                                         select { |k| k =~ /\// }.
                                         map { |k| k.split('/').first }.
                                         uniq
        
        # Breadcrumb
        ary = [link(strong("> BUCKETS"), :stroke => black, :size => 10, :family => "Georgia", :top => 112) { draw_account(@account.name) }, ' > ']
        if prefix.nil?
          ary << strong(bucket.name.upcase, :stroke => black, :size => 10, :family => "Georgia")
        else
          ary << link(strong(bucket.name.upcase), :stroke => black, :size => 10, :family => "Georgia") { draw_bucket(bucket) } 
        end
        prefix.split('/').each { |p|
          ary += [' > ', link(p.upcase, :stroke => black, :size => 10, :family => "Georgia")]
        } unless prefix.nil?
        para ary, :top => 113

        # Header
        stack :width => "100%", :margin => [0,15,0,5] do
          flow(:width => '50%', :top => 0, :left => 0) { para strong("NAME"), :size => 14, :family => "Georgia" }
          flow(:width => '10%', :top => 0, :left => '50%') { para strong("SIZE"), :size => 14, :align => 'center', :family => "Georgia" }
          flow(:width => '40%', :top => 0, :left => '60%') { para strong("MODIFIED ON"), :size => 14, :align => 'right', :family => "Georgia" }
        end
        
        # File Listing
        # Note: "prefix" is the aws/s3 term for "folder", "directory", etc. because we're dealing with keys
        prefixes.each do |p|
          stack :width => "100%", :margin => [0,0,0,5] do
            wouldbe_prefix = "#{prefix + '/' if prefix}#{p}"
            background "#EFEFDD"
            flow(:width => '50%', :top => 5, :left => 0) { para(link("#{p}/", :stroke => black, :size => 12){ draw_bucket(bucket, wouldbe_prefix) }) }
            flow(:width => '10%', :top => 5, :left => '50%') { para bucket.objects(:prefix => wouldbe_prefix).size, :align => 'center', :size => 12 }
            # extra attrs: owner, url, value, 
          end
        end
        
        objects_without_prefix.each do |object|
          stack :width => "100%", :margin => [0,0,0,5] do
            background "#EFEFDD"
            flow(:width => '50%', :top => 5, :left => 0, :size => 12) {
              # COME ON! There has to be a better way than this hide/show hack to bold some text on hover ^_^
              k1 = para object.key.split('/').last
              k2 = para strong(object.key.split('/').last), :hidden => true
              hover { k1.hide; k2.show }; leave { k1.show; k2.hide }
            }
            flow(:width => '10%', :top => 5, :left => '50%') { para object.size, :align => 'center', :size => 12 }
            flow(:width => '40%', :top => 5, :left => '60%') { para object.last_modified, :align => 'right', :size => 12 }
            # hover { |_| _.background rgb(0.0, 0.0, 0.0, 0.5) }
            # leave { |_| _.background nil }
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
