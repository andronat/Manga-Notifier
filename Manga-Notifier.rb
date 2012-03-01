#!/usr/bin/env ruby

# encoding: utf-8
#====================================================================
# Name        : 
#			Manga-Notifier.rb
# Version    : 
#			v0.08
#			
#====================================================================

class MangaNotifier
  require 'rubygems'
  require 'hpricot'
  require 'open-uri'
  require 'timeout'
  require 'rbconfig'
  require 'optparse'

  def initialize(options)
    
    m = MangaReader.new
    m.print_manga if options[:manga]
    m.bell if options[:bell]
    AnimeReader.new.print_anime if options[:anime]
    Downloader.new.download(m) if options[:download]
  end
  
  class MangaReader
    
    attr_accessor :page, :manga_names, :manga_times
    
    def initialize
      void = RbConfig::CONFIG['host_os'] =~ /msdos|mswin|djgpp|mingw/ ? 'NUL' : '/dev/null'
      @figlet = system "figlet -v >>#{void} 2>&1"
      @manga_url = 'http://mangastream.com'
    end
    
    def print_manga
      @page = Hpricot(open(@manga_url).read)
      @manga_names = @page.search('//li[@class="new"]/a').collect {|name| name.innerHTML}
      @manga_times = @page.search('//li[@class="new"]/em').collect {|time| time.innerHTML}

      if @manga_names.length == 0
        puts 'No new manga for today, sorry :('
        print `figlet ':(' ` if @figlet
      elsif @manga_names.length == 1
        print `figlet #{@manga_names[0].tr_s("\'", " ")}` if @figlet
        puts '-----> ' + @manga_names.length.to_s() + ' New Manga <-----' 
        puts ' From http://mangastream.com/'
        puts 'Only manga -> ' + @manga_names[0] + '   Posted at: ' + @manga_times[0]
      else
        print `figlet #{@manga_names[0].tr_s("\'", " ")}` if @figlet
        puts '-----> ' + @manga_names.length.to_s() + ' New Mangas <-----' 
        puts ' From http://mangastream.com/'
        @manga_names.length.times do |i|
      	  puts (i+1).to_s() + ') ' + @manga_names[i] + '   Posted at: ' + @manga_times[i]
        end
      end
      
    end
    
    def bell
      b=[]
      @manga_names.size.times { |i| b[i] = (@manga_names[i].include? "One Piece") && (@manga_times[i].include? "Today") }
      if b.include?(true)
        flag = 0
        print "Press enter to exit!"
        while flag < 10 do
          begin
            flag += 1
            Timeout::timeout(1) {
              value = gets
              flag = 10
            }
          rescue Timeout::Error
            10.times {
              print "\a"
              STDOUT.flush
            }
          end
        end
      end
    end
    
  end

  class AnimeReader
    
    attr_accessor :page, :manga_names, :manga_times
    
    def initialize
      @anime_url = 'http://www.watchop.com'
    end
    
    def print_anime
      all_names = Hpricot(open(@anime_url).read).search('//*[@class="movie"]')
      puts "\n \n "
      puts '-----> One Piece Anime <-----' 
      puts ' From http://www.watchop.com/'
      puts 'Current anime: ' + all_names[0].innerHTML
    end
    
  end
  
  class Downloader
    
    def download(manga)
      return self if manga.manga_names.length == 0

      begin
        puts "\n \n "
        puts "Choose which one manga would you like to download."
        puts "Or -1 to cancel"
        manga.manga_names.length.times do |i|
      	  puts (i+1).to_s() + ') ' + manga.manga_names[i] + '   Posted at: ' + manga.manga_times[i]
        end
        
        begin
          number = Integer(gets.chomp)
        rescue Exception
          number = -1
        end
        
        return if number == -1
        
      end while number < 1 || number > manga.manga_names.size

      first_page_url = manga.page.search('//li[@class="new"]/a').collect { |name| name.attributes['href'] }[number-1].chop!
      i=1

      directory_name = File.dirname(__FILE__) + "/" + manga.manga_names[number-1]
      if !FileTest::directory?(directory_name)
        Dir::mkdir(directory_name)
      end

      Dir::chdir(directory_name)

      puts 'Downloading...'

      loop do
        begin
          img_url = Hpricot(open("#{first_page_url}#{i}")).search('//img[@id="p"]').first.attributes["src"]

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
   options[:bell] = false
   options[:download] = false
  end

  options[:download] = true
  opts.on( '-d', '--no-download', 'Omit manga downloader.' ) do
   options[:download] = false
  end

  options[:bell] = true
  opts.on( '-b', '--no-bell', 'Omit bell notifier.' ) do
   options[:bell] = false
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

m = MangaNotifier.new options
exit 0