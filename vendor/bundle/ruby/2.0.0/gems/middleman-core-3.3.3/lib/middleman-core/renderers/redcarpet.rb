require 'redcarpet'

module Middleman
  module Renderers
    class RedcarpetTemplate < ::Tilt::RedcarpetTemplate::Redcarpet2
      # because tilt has decided to convert these
      # in the wrong direction
      ALIASES = {
        escape_html: :filter_html
      }

      # Overwrite built-in Tilt version.
      # Don't overload :renderer option with smartypants
      # Support renderer-level options
      def generate_renderer
        return options.delete(:renderer) if options.key?(:renderer)

        covert_options_to_aliases!

        # Pick a renderer
        renderer = MiddlemanRedcarpetHTML

        # Support SmartyPants
        if options.delete(:smartypants)
          renderer = Class.new(renderer) do
            include ::Redcarpet::Render::SmartyPants
          end
        end

        # Renderer Options
        possible_render_opts = [:filter_html, :no_images, :no_links, :no_styles, :safe_links_only, :with_toc_data, :hard_wrap, :xhtml, :prettify, :link_attributes]

        render_options = possible_render_opts.reduce({}) do |sum, opt|
          sum[opt] = options.delete(opt) if options.key?(opt)
          sum
        end

        renderer.new(render_options)
      end

      private

      def covert_options_to_aliases!
        ALIASES.each do |aka, actual|
          options[actual] = options.delete(aka) if options.key? aka
        end
      end
    end

    # Custom Redcarpet renderer that uses our helpers for images and links
    class MiddlemanRedcarpetHTML < ::Redcarpet::Render::HTML
      cattr_accessor :middleman_app

      def initialize(options={})
        @local_options = options.dup

        super
      end

      def image(link, title, alt_text)
        if !@local_options[:no_images]
          middleman_app.image_tag(link, title: title, alt: alt_text)
        else
          link_string = link.dup
          link_string << %Q("#{title}") if title && title.length > 0 && title != alt_text
          %Q{![#{alt_text}](#{link_string})}
        end
      end

      def link(link, title, content)
        if !@local_options[:no_links]
          attributes = { title: title }
          attributes.merge!(@local_options[:link_attributes]) if @local_options[:link_attributes]

          middleman_app.link_to(content, link, attributes)
        else
          link_string = link.dup
          link_string << %Q("#{title}") if title && title.length > 0 && title != alt_text
          %Q{[#{content}](#{link_string})}
        end
      end
    end

    ::Tilt.register RedcarpetTemplate, 'markdown', 'mkd', 'md'
  end
end
