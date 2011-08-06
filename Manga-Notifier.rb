#!/usr/bin/env ruby

# encoding: utf-8
#====================================================================
# Name        : 
#			Manga-Notifier.rb
# Version    : 
#			v0.04a
#			
#====================================================================

class MangaReader
  require 'rubygems'
  require 'hpricot'
  require 'open-uri'
  require 'timeout'

  def initialize()
  end

  def  manga
    page = Hpricot(open('http://mangastream.com/').read)
    all_names = page.search('//li[@class="new"]/a').collect {|name| name.innerHTML}
    all_times = page.search('//li[@class="new"]/em').collect {|time| time.innerHTML}
    
    if all_names.length == 0
      puts 'No new manga for today, sorry :('
      print `figlet ':(' `
    elsif all_names.length == 1
      print `figlet #{all_names[0].tr_s("\'", " ")}`
      puts '-----> ' + all_names.length.to_s() + ' New Manga' +' <-----' + "\n From http://mangastream.com/ \n "
      puts 'Only manga -> ' + all_names[0] + '   Posted at: ' + all_times[0]
    else
      print `figlet #{all_names[0].tr_s("\'", " ")}`
      puts '-----> ' + all_names.length.to_s() + ' New Mangas' +' <-----' + "\n From http://mangastream.com/ \n "
      all_names.length.times do |i|
    	  puts (i+1).to_s() + ') ' + all_names[i] + '   Posted at: ' + all_times[i]
      end
    end
    
    @my_thread = Thread.new {
      Thread.stop
      b=[]
      all_names.size.times { |i| b[i] = (all_names[i].include? "One Piece") && (all_times[i].include? "Today") }
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

  def  anime
    @my_thread.run
    @my_thread.join
    
    all_names = Hpricot(open('http://www.watchop.com/').read).search('//*[@class="movie"]')
    puts "\n \n "
    puts '-----> ' + 'One Piece Anime' + ' <-----' + "\n From http://www.watchop.com/ \n "
    puts 'Current anime: ' + all_names[0].innerHTML
    
    return self
  end
end

MangaReader.new.manga.anime