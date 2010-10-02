require 'base64'
require 'mechanize'
require 'aws/s3'
require 'thor'
require 'tmpdir'

class FontSquirreler < Thor
  include Thor::Actions
  
  desc "search _search_string", "search for fonts on fontsquirrel"
  method_options :s3 => false
  def search(search_str)
    homepage
    fonts = get_search_result_fonts(@homepage, search_str)
    font_link = ask_which_font(fonts)
    font_name = download_font(font_link) if font_link
    say "saved " + font_name
    inline_font(font_name)
    if options[:s3]
      store_on_s3(font_name)      
    else
      store(font_name)
    end
  end

  desc "inline_font _font_name", "create an inlined stylesheet of a downloaded font"
  def inline_font(font_name)
    content = File.open(stylesheet_path(font_name)).read

    woff_filenames = (content.scan %r{url\('([^\)]*?\.woff)'\)}).flatten
    ttf_filenames  = (content.scan %r{url\('([^\)]*?\.ttf)'\)}).flatten

    woff_filenames.each do |woff_filename|
      content.gsub!( "'#{woff_filename}'",
                     "data:font/woff;charset=utf-8;base64,#{file_to_base64(File.join(font_path(font_name), woff_filename))}")      
    end
    ttf_filenames.each do |ttf_filename|    
      content.gsub!( "'#{ttf_filename}'",
                     "data:font/truetype;charset=utf-8;base64,#{file_to_base64(File.join(font_path(font_name), ttf_filename))}")
    end
    
    content.split('@font-face').each do |part|
      if !part.match(%r{/\*})
        name = part.match(%r{font-family:\s'(.*)'})[1]
        puts font_path(font_name)
        File.open(File.join(font_path(font_name), "#{name}.css"), 'w').write('@font-face' + part)
      end
    end
  end

  desc "store _font_name", "stores into current project (assumes the presence of a /public directory)"
  def store(font_name)
    varients = get_varients(font_name)
    varients.each do |varient|
      files = files_for_font_varient(font_name, varient)
      files.each do |file|
        FileUtils.mkdir_p("public/webfonts/#{varient.gsub('-','')}")
        store_path = "public/webfonts/#{varient.gsub('-','')}/#{File.basename file}"
        FileUtils.cp(file, store_path)
        puts "stored: #{File.expand_path store_path}"
      end
    end    
  end
  
  desc "store_on_s3 _font_name", "store font on s3"  
  def store_on_s3(font_name)
    AWS::S3::Base.establish_connection!(
                                        :access_key_id     => ENV['AMAZON_ACCESS_KEY_ID'],
                                        :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
                                        )
    varients = get_varients(font_name)
    varients.each do |varient|
      files = files_for_font_varient(font_name, varient)
      files.each do |file|
        options = { :access => :public_read,
          :cache_control => 'public, max-age=31557600',
          :content_type => 'text/plain'}
        if file.match /\.css$/
          options = options.merge({ :content_type => 'text/css' })
        end
        store_path = "webfonts/#{varient.gsub('-','')}/#{File.basename file}"
        AWS::S3::S3Object.store(store_path, open(file), ENV['S3_FONT_BUCKET'], options)
        puts "stored: http://#{ENV['S3_FONT_BUCKET']}.s3.amazonaws.com/" + store_path
      end
    end
  end
  
  protected
  
  def get_varients(font_name)
    col = { }
    Dir[font_path(font_name) + '/*webfont*'].each do |file|
      col[File.basename(file).gsub(/-webfont.*/, '')] = true
    end
    col.keys
  end

  def files_for_font_varient(font_name, varient)
    files = []
    files += Dir[font_path(font_name) + "/#{varient}-webfont*"]
    files += Dir[font_path(font_name) + "/#{varient.gsub('-','')}.css"]
  end
  
  def agent
    @agent ||= Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }    
  end
  
  def tmp_dir
    @tmpdir ||= Dir.tmpdir
  end
  
  def homepage
    agent
    @homepage ||= @agent.get('http://www.fontsquirrel.com/')
  end

  def file_to_base64(filename)
    [File.open(filename).read].pack('m').gsub("\n",'')
  end
  
  def get_search_result_fonts(homepage, search_str)
    result = homepage.form_with(:action => '/search') do |search|
      search.search = search_str
    end.submit
    font_links =  result.links_with(:text => 'View')
  end
  
  # displays the results of the search and asks for a choice
  def ask_which_font(font_links)
    font_links.each_with_index { |x,i|
      puts "#{i + 1}:  #{x.href}"
    }
    font_index = ask "Which one do you want? [1-#{font_links.length}] :"
    font_links[font_index.to_i - 1]    
  end

  #returns path to downloaded font in tmp
  def download_font(link)
    res =  @agent.click link
    fontkit_form = res.forms.detect { |x| x.action.match /fontfacekit/ }
    if fontkit_form
      # dont do woff if inlining just increases filesize
      #      puts fontkit_form.checkboxes.inspect
      fontkit_form.checkbox_with(:value => 'woff').checked = false

      result = fontkit_form.submit
      filename = result.filename.gsub('"', '')
      path = File.join(tmp_dir, filename.gsub('.zip', ''))
      ret_path = ''
      inside(path) do |dir|
        result.save(filename)
        `unzip #{dir}/#{filename}`
        `rm *html *zip *txt`
      end
      return filename.gsub('.zip', '')
    end    
  end
  
  def font_path(font_name)
    File.join(tmp_dir, font_name)
  end
  
  def stylesheet_path(font_name)
    File.join(font_path(font_name), 'stylesheet.css')
  end
end
