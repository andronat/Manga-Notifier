#!/usr/bin/env ruby

# encoding: utf-8
#====================================================================
# Name        : 
#			Manga-Notifier.rb
# Version    : 
#			v0.06
#			
#====================================================================

class MangaReader
  require 'rubygems'
  require 'hpricot'
  require 'open-uri'
  require 'timeout'
  require 'rbconfig'
  require 'optparse'

  def initialize
    void = RbConfig::CONFIG['host_os'] =~ /msdos|mswin|djgpp|mingw/ ? 'NUL' : '/dev/null'
    @figlet = system "figlet -v >>#{void} 2>&1"
    @manga_url = 'http://mangastream.com'
    @anime_url = 'http://www.watchop.com'
  end

  def  manga
    @page = Hpricot(open(@manga_url).read)
    @all_names = @page.search('//li[@class="new"]/a').collect {|name| name.innerHTML}
    @all_times = @page.search('//li[@class="new"]/em').collect {|time| time.innerHTML}
    
    if @all_names.length == 0
      puts 'No new manga for today, sorry :('
      print `figlet ':(' ` if @figlet
    elsif @all_names.length == 1
      print `figlet #{@all_names[0].tr_s("\'", " ")}` if @figlet
      puts '-----> ' + @all_names.length.to_s() + ' New Manga <-----' 
      puts ' From http://mangastream.com/'
      puts 'Only manga -> ' + @all_names[0] + '   Posted at: ' + @all_times[0]
    else
      print `figlet #{@all_names[0].tr_s("\'", " ")}` if @figlet
      puts '-----> ' + @all_names.length.to_s() + ' New Mangas <-----' 
      puts ' From http://mangastream.com/'
      @all_names.length.times do |i|
    	  puts (i+1).to_s() + ') ' + @all_names[i] + '   Posted at: ' + @all_times[i]
      end
    end
    
    @my_thread = Thread.new {
      Thread.stop
      b=[]
      @all_names.size.times { |i| b[i] = (@all_names[i].include? "One Piece") && (@all_times[i].include? "Today") }
      if b.include?(true)
        flag = true
        print "Press enter to exit!"
        while flag do
          begin
            Timeout::timeout(1) {
              value = gets
              flag = false
            }
          rescue Timeout::Error
            10.times {
              print "\a"
              STDOUT.flush
            }
          end
        end
      end
    }

    return self
  end

  def anime
    @my_thread.run
    @my_thread.join
    
    all_names = Hpricot(open(@anime_url).read).search('//*[@class="movie"]')
    puts "\n \n "
    puts '-----> One Piece Anime <-----' 
    puts ' From http://www.watchop.com/'
    puts 'Current anime: ' + all_names[0].innerHTML
    
    return self
  end
  
  def downloader
    return self if @all_names.length == 0
        
    begin
      puts "\n \n "
      puts "Choose which one manga would you like to download:"
      @all_names.length.times do |i|
    	  puts (i+1).to_s() + ') ' + @all_names[i] + '   Posted at: ' + @all_times[i]
      end
      
      number = Integer(gets.chomp)
    end while number < 1 || number > @all_names.size
    
    first_page_url = @page.search('//li[@class="new"]/a').collect { |name| name.attributes['href'] }[number-1].chop!
    i=1
    
    directory_name = File.dirname(__FILE__) + "/" + @all_names[number-1]
    if !FileTest::directory?(directory_name)
      Dir::mkdir(directory_name)
    end
    
    Dir::chdir(directory_name)
    
    puts 'Downloading...'
    
    loop do
      begin
        img_url = Hpricot(open("#{first_page_url}#{i}")).search('//div[@id="p"]/a').collect {|link| link.inner_html}.first.split("\"")[1]

        open("#{i}.png", 'wb') do |file|
          file << open(img_url).read
        end

        i+=1
      rescue OpenURI::HTTPError
        break
      end
    end
    
    puts 'You manga is ready!'
    puts "You can find it at #{directory_name}"
    
  end
  
end

options = {}
puts "Run with -h for more options!" if ARGV.length == 0

optparse = OptionParser.new do |opts|
  
  opts.banner = "Usage: Manga-Notifier.rb [-amdvh]"
  
  options[:anime] = true
  opts.on( '-a', '--no-anime', 'Omit anime notify.' ) do
   options[:anime] = false
  end

  options[:manga] = true
  opts.on( '-m', '--no-manga', 'Omit manga notify.' ) do
   options[:manga] = false
  end

  options[:download] = true
  opts.on( '-d', '--no-download', 'Omit manga downloader.' ) do
   options[:download] = false
  end

  opts.on( '-v', '--version', 'Display current version:' ) do
    puts "Version: 0.06"
    exit 0
  end
  
  opts.on( '-h', '--help', 'Display this screen:' ) do
    puts opts
    exit 0
  end
end

begin
  optparse.parse!
rescue OptionParser::InvalidOption => e
  puts e
  puts optparse
  exit 1
end

m = MangaReader.new
m.manga if options[:manga]
m.anime if options[:anime]
m.downloader if options[:download]
exit 0