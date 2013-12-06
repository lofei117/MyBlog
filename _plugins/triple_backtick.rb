require 'pygments'
require 'redcarpet'

module Jekyll
  module Converters
    class Markdown < Converter
      alias old_convert convert

      def extensions
        Hash[ *@config['redcarpet']['extensions'].map {|e| [e.to_sym, true] }.flatten ]
      end

      def markdown
        @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions)
      end
  
      def convert(content)
        if @config['markdown'] == 'redcarpet2' then        
          
          content.gsub!(/(?:^|\n)```(\w*)\s*(.*?\n)```\n/m) do |text|
                cls = $1.empty? ? "text" : "#{$1}"
                #  "<div class=\"highlight\"><pre><code class=\"#{cls}\">#{$2}</code></pre></div>"                
                result = Pygments.highlight($2, :lexer => cls)   
                File.open("G:/Blog/lofei117.github.com/_cache/123.txt", 'a') {|f| f.print(result) }
                result             
              end          
          markdown.render(content) 
        else
          old_convert(content)     
        end    
      end 
    end
  end
end
