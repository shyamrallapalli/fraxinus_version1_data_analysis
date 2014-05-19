#!/usr/bin/ruby
# encoding: utf-8
#
# ruby ./export-mysql.rb

require 'rubygems'
require './cigar_class'
require 'pp'

puzzles = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] ={} } }
input = File.read(ARGV[0])
input.split("\n").each do | puzzle |
	line = puzzle.gsub(">", "").split("\t")
	lineid = [line[0], line[1]].join("_")
	puzzles[line[3]][lineid][puzzle] = 1
		#   bamfile   ref & seq  line
end

Dir.glob("*.vcf") do |filename|
	bamfilename = filename.gsub("\.vcf", "")
	variants = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
	sam = File.read(filename)
	sam.split("\n").each do |entry|
		if entry !~ /^\#/
			info = entry.split("\t")
			puzzleid = [info[4], info[3]].join("_")
			if puzzles[bamfilename.to_s].key?(puzzleid.to_s) == true
				puzzles[bamfilename.to_s][puzzleid.to_s].each_key { |key|
					print "#{info[4]}\t#{info[3]}\t#{info[5]}\t#{key}"

					data = key.split("\t")
					pos_in_play = data[2].to_i
					bwapos = data[12].to_i
					readseq = data[13]
					bwacigar = data[14].to_s
					playercigar = data[15].to_s
					playerpos = data[16].to_i

					if bwacigar != '*'
						# now we have real variant position and long reference sequence around the 21bp pattern
						correct_pos_in_play = info[5].to_i - 10
						# 102074 - 10
						difference = correct_pos_in_play - pos_in_play
						# 102064-102024 = 40
						corrected_playerpos = playerpos + difference
						# 101986 + 40 = 102026
						longref_startpos = info[1].to_i

						types, counts = Cigar.alignchunks(bwacigar)
						adjbwapos = bwapos
						if types[0] =~ /S/
								adjbwapos -= counts[0]
						end
						newbwacigar = Cigar.newcigars(bwacigar,correct_pos_in_play,adjbwapos)
=begin
						initial_gap = bwapos.to_i - longref_startpos
						adjusted = initial_gap
						if types[0] =~ /S/
							adjusted = adjusted - counts[0].to_i # BWA cigar treats alingment position after soft clipping (default)
						end
						percent, match, mismatch = Cigar.percent_identity(bwacigar, info[0].upcase, initial_gap, readseq)
=end
						types2, counts2 = Cigar.alignchunks(playercigar)
						newplayercigar = Cigar.newcigars(playercigar,correct_pos_in_play,corrected_playerpos)
						print "\t#{newbwacigar}\t#{newplayercigar}"
=begin
						initial_gap2 = corrected_playerpos - longref_startpos
						adjusted2 = initial_gap2
						if types2[0] =~ /S/
							adjusted2 = adjusted2 + counts2[0].to_i # Fraxinus cigar treats alingment position begining of a read even for soft clipping (take care about this)
						end

						bwaalign = Cigar.aligner(types, counts, info[0], adjusted, readseq)
						playeralign = Cigar.aligner(types2, counts2, info[0], initial_gap2, readseq)

						print "\n#{bwaalign}\n#{playeralign}\n"

						percent2, match2, mismatch2 = Cigar.percent_identity(playercigar, info[0].upcase, adjusted2, readseq)

						if percent2 > percent and (percent2 - percent) > 1
						# if percent2 > percent
							stats = [percent, match, mismatch, percent2, match2, mismatch2].join("\t")
							bwaalign = Cigar.aligner(types, counts, info[0], adjusted, readseq)
							playeralign = Cigar.aligner(types2, counts2, info[0], initial_gap2, readseq)
							alignments = [bwaalign, playeralign].join("_")
							keyid = [puzzleid, correct_pos_in_play].join("_")
							variants[keyid][key][stats] = alignments
						end
=end
					else
						print "\t*\t-"
					end
					print "\n"
				}
			end
		end
	end
=begin
	file = File.new("#{bamfilename}_player_alignments_selected.txt", "w")
	variants.each_key { |key|
		# if variants[key].length > 1
			file.print "#{key}\n"
			useraln = []
			variants[key].each_key { |puzzle|
				variants[key][puzzle].each_key { |stats|
					alns = variants[key][puzzle][stats].split("_")
					file.print "#{alns[0]}"
					useraln.push(alns[1])
				}
			}
			file.print "Player alignments\n"
			useraln.each { |aln|
				file.print "#{aln}"
			}
		# end
	}
=end
end


=begin
	# print "#{info[4]}\t#{info[3]}\t#{info[5]}\t#{key}\n"
	print "\t#{percent}\t#{match}\t#{mismatch}\n"
	print "\t#{percent2}\t#{match2}\t#{mismatch2}\t#{data[20]}\n"
	print "\n"
	data = key.split("\t")
	refid = data[0]
	pattern = data[1]
	pos_in_play = data[2]
	bamfile = data[3]
	readid = data[14]
	bwapos = data[15]
	readseq = data[16]
	bwacigar = data[17]
	playercigar = data[18]
	playerpos = data[19]
=end
