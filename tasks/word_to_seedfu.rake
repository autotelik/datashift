# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
#
# License::   Free, OpenSource... MIT ?
#
# About::     Rake tasks to read Word documents, containing product descriptions,
#             convert to HTML, tidy the HTML and then create seed_fu ready fixtures,
#             from a template, with product description supplied by the HTML
#
#             Note cleanest HTML is produced by this combination : saving with WdFormatHTML
#             not WdFormatFilteredHTML and using the '--word-2000', 'y' option to tidy
#             (don't use the '--bare' option)
#
#             Not currently available for JRuby due to Win32Ole requirement
#
#             Requires local exes available in PATH for :
#             Microsoft Word
#             HTML Tidy - http://tidy.sourceforge.net  (Free)
#
require 'erb'

namespace :datashift do

  desc "Convert MS Word to HTML and seed_fu fixtures. help=true for detailed usage."

  task :word2html, [:help] => [:environment] do |t, args|
    x =<<-EOS

  USAGE::
      Convert MS Word docs to HTML and seed_fu fixtures, by default searches for docs
      in RAILS_ROOT/doc/copy

      You can change the directory where Word document files are located
      with the COPY_PATH  environment variable.

      Examples:
        # default, to convert all Word files for the current environment
        rake datashift:word2seedfu

        # to load seed files matching orders or customers
        rake db:seed SEED=orders,customers

        # to load files from RAILS_ROOT/features/fixtures
        rake db:seed FIXTURE_PATH=features/fixtures
    EOS

    if(args[:help])
      puts x
      exit(0)
    end

    site_extension_lib = File.join(SiteExtension.root, 'lib')

    require File.join(site_extension_lib, 'word')

    copy_path = ENV["COPY_PATH"] ? ENV["COPY_PATH"] : File.join(RAILS_ROOT, "doc", "copy")
    fixtures_path = ENV["FIXTURES_PATH"] ? ENV["FIXTURES_PATH"] : File.join(RAILS_ROOT, "db", "fixtures")

    copy_files = Dir[File.join(copy_path, '*.doc')]

    copy_files.each do |file|

      name = File.basename(file, '.doc')

      puts "\n== Generate raw HTML from #{name}.doc =="

      @word = Word.new(true)

      @word.open( file )

      html_file = File.join(copy_path, "#{name}.ms.html")

      @word.save_as_html( html_file )

      tidy_file = File.join(copy_path, "#{name}.html")

      tidy_config = File.join(site_extension_lib, 'tasks', 'tidy_config.txt')

      puts "tidy cmd line:", "tidy -config #{tidy_config} -clean --show-body-only y --word-2000 y --indent-spaces 2 -output #{tidy_file} #{html_file}"

      result = system("tidy", '-config', "#{tidy_config}", '-clean', '--show-body-only', 'y', '--word-2000', 'y', '--indent-spaces', '2', '-output', "#{tidy_file}", "#{html_file}")

      # TODO maybe report on result, $?

      File.open( tidy_file ) do |f|
        puts f.read
      end

      @word.quit
    end
  end

  desc "Convert MS Word to HTML and seed_fu fixtures. help=true for detailed usage."
  task :word2seedfu => :environment do
    site_extension_lib = File.join(SiteExtension.root, 'lib')

    require File.join(site_extension_lib, 'word')

    sku_id     = ENV["INITIAL_SKU_ID"] ? ENV["INITIAL_SKU_ID"] : 0
    sku_prefix = ENV["SKU_PREFIX"] ? ENV["SKU_PREFIX"] : File.basename( RAILS_ROOT )

    seedfu_template = File.join(site_extension_lib, 'tasks', 'seed_fu_product_template.erb')

    begin
      File.open( seedfu_template ) do |f|
        @template = ERB.new(f.read)
      end
    rescue => e
      puts "ERROR: #{e.inspect}"
      puts "Cannot open or read template #{seedfu_template}"
      raise e
    end

    copy_path = ENV["COPY_PATH"] ? ENV["COPY_PATH"] : File.join(RAILS_ROOT, "doc", "copy")
    fixtures_path = ENV["FIXTURES_PATH"] ? ENV["FIXTURES_PATH"] : File.join(RAILS_ROOT, "db", "fixtures")

    copy_files = Dir[File.join(copy_path, '*.doc')]

    copy_files.each do |file|

      name = File.basename(file, '.doc')

      puts "\n== Generate raw HTML from #{name}.doc =="

      @word = Word.new(true)

      @word.open( file )

      html_file = File.join(copy_path, "#{name}.ms.html")

      @word.save_as_html( html_file )

      tidy_file = File.join(copy_path, "#{name}.html")

      tidy_config = File.join(site_extension_lib, 'tasks', 'tidy_config.txt')

      puts "tidy cmd line:", "tidy -config #{tidy_config} -clean --show-body-only y --word-2000 y --indent-spaces 2 -output #{tidy_file} #{html_file}"

      result = system("tidy", '-config', "#{tidy_config}", '-clean', '--show-body-only', 'y', '--word-2000', 'y', '--indent-spaces', '2', '-output', "#{tidy_file}", "#{html_file}")

      # TODO maybe report on result, $?

      File.open( tidy_file ) do |f|
        @description = f.read
      end

      sku_id_str  = "%03d" % sku_id

      seed_file = "#{sku_id_str}_#{name.gsub(' ', '_')}.rb"
      puts "\n== Generate seed fu file #{seed_file} =="

      @sku  = "#{sku_prefix}_#{sku_id_str}"
      @name = 'TODO'
  
      File.open( File.join(fixtures_path, seed_file), 'w' ) do |f|
        f.write @template.result(binding)
        puts "\nFile created: #{File.join(fixtures_path, seed_file)}"
      end

      sku_id += 1

      @word.quit
    end

  end
end