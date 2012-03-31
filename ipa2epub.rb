# -*- coding: utf-8 -*-
#/usr/bin/env ruby
#
# O'Reilly の iPhone App を epub ファイルに変換し，
# 入力と同じディレクトリに出力する．
# ziprubyが必要 (gem install zipruby)．
#
# $ ruby epub_extractor.rb {iPhone App}

require "fileutils"
require 'zipruby'
require 'pathname'
require 'tmpdir'
require 'find'
require 'readline'

class Ipa2Epub
  def self.extract(zip)
    # 作成予定ファイルが既に存在していないかチェック
    output_path = Pathname(zip).sub_ext(".epub")
    if File.exist?(output_path)
      while buf = Readline.readline("Overwrite #{output_path}? (y/n): ")
        if (buf == "y")
          break
        elsif (buf == "n")
          puts "exit."
          exit
        end
      end
    end

    Dir.mktmpdir {|tmpdir|
      # zipをtmpdir下に解凍
      Zip::Archive.open(zip) {|archives|
        archives.each do |a|
          d = File.dirname(a.name)
          FileUtils.mkdir_p("#{tmpdir}/#{d}")
          unless a.directory?
            open("#{tmpdir}/#{a.name}", "w") {|f| f.puts a.read }
          end
        end
      }

      # epubに必要なファイルをepubに追加
      puts "create #{output_path.realpath.to_s} "
      Zip::Archive.open(output_path.to_s, Zip::CREATE | Zip::TRUNC) {|output|
        book_path = Pathname(Dir.glob("#{tmpdir}/Payload/*.app/book")[0])
        Find.find(book_path) do |f|
          next if f == book_path
          relative_path = Pathname.new(f).relative_path_from(book_path)
          if File.directory?(f)
            output.add_dir(relative_path.to_s)
          else
            output.add_file(relative_path.to_s, f)
          end
        end
      }
    }
  end
end


if __FILE__ == $0
  ARGV.each do |zip|
    Ipa2Epub.extract(zip)
  end
  puts "complete."
end

