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
    cufon_font(font_name)
    if options[:s3]
      store_on_s3(font_name)      
    else
      store(font_name)
    end
  end

  desc "cufon_font _font_name",  "generates the cufon js for the varients of this font"
  def cufon_font(font_name)
    varients = get_varients(font_name)
    say varients.inspect
    varients.each do |varient| 
      say files_for_font_varient(font_name, varient).inspect
      f = files_for_font_varient(font_name, varient).detect { |x| x.match /\.ttf$/ }
      css = files_for_font_varient(font_name, varient).detect { |x| x.match /\.css$/ }
      name = File.basename(css).split('.').first
      
      js_path = File.join(font_path(font_name), 'varients', varient, name + '.js')
      `php /Users/bhauman/workspace/cufon/generate/convert.php --fontforge /Applications/FontForge.app/Contents/MacOS/FontForge -u "U+??" #{f} 1> #{js_path}.temp`
       say "generating #{js_path}.temp"
       say "fixing font family name"
       font_js = File.open(%{#{js_path}.temp}).read
       font_js.sub!(%r{"font-family"\:"[^"]*"}, %{"font-family":"#{name}"})
       new_file = File.open(js_path, 'w')
       font_js.each(':') do |chunk|
         new_file.write chunk
       end
       new_file.close
       FileUtils.rm(js_path + '.temp')
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
        act_font_file_name = part.match(%r{src:\surl\('([^\)]*)\.eot'\)})[1]
        var_dir = fonts_varient_directory(font_name, name, act_font_file_name)

        new_file = File.open(File.join(var_dir, "#{name}.css"), 'w')
        new_file.write('@font-face' + part)
        new_file.close
      end
    end
  end

  def fonts_varient_directory(font_name, name, act_font_names)
      dir = File.join( font_path(font_name),'varients', name )    
      FileUtils.mkdir_p dir
      ffiles = Dir[font_path(font_name) + "/#{act_font_names}.ttf"]
      ffiles += Dir[font_path(font_name) + "/#{act_font_names}.eot"]
      ffiles += Dir[font_path(font_name) + "/#{act_font_names}.svg"]
      ffiles.each do |f|
        FileUtils.cp(ffiles, dir)
      end
      dir
  end

  desc "process _zip_file", "process a downloaded fontsquirrel zip"
  method_options :s3 => false
  def process(zip_file)
    filename = File.basename zip_file
    path = File.join(tmp_dir, filename.gsub('.zip', ''))
    FileUtils.mkdir_p(path)
    FileUtils.cp(zip_file, path)
    inside(path) do |dir|
      `unzip #{dir}/#{filename}`
      `rm *html *zip *txt`
    end
    font_name = filename.gsub('.zip', '')
    say "saved " + font_name
    inline_font(font_name)
    cufon_font(font_name)
    if options[:s3]
      store_on_s3(font_name)      
    else
      store(font_name)
    end
  end

  desc "store _font_name", "stores into current project (assumes the presence of a /public directory)"
  def store(font_name)
    varients = get_varients(font_name)
    varients.each do |varient|
      files = files_for_font_varient(font_name, varient)
      puts files.inspect
      vname = File.basename(files.detect {|x| x.match(/\.css$/) }).gsub('.css', '')
      files.each do |file|
        FileUtils.mkdir_p("public/webfonts/#{vname}")
        store_path = "public/webfonts/#{vname}/#{File.basename file}"
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
      vname = File.basename(files.detect {|x| x.match(/\.css$/) }).gsub('.css', '')
      files.each do |file|
        options = { :access => :public_read,
          :cache_control => 'public, max-age=31557600',
          :content_type => 'text/plain'}
        if file.match /\.css$/
          options = options.merge({ :content_type => 'text/css' })
        end
        store_path = "webfonts/#{vname}/#{File.basename file}"
        AWS::S3::S3Object.store(store_path, open(file), ENV['S3_FONT_BUCKET'], options)
        puts "stored: http://#{ENV['S3_FONT_BUCKET']}.s3.amazonaws.com/" + store_path
      end
    end
  end
  
  protected
  
  def get_varients(font_name)
    Dir[font_path(font_name) + '/varients/*'].collect {|x| File.basename(x)}
  end

  def files_for_font_varient(font_name, varient)
    say font_path(font_name) + '/varients/#{varient}/*'
    Dir[font_path(font_name) + "/varients/#{varient}/*"]
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
