# for Liquid 2.3.0
module Liquid
  class Block < Tag
  private
    def render_all(list, context)
      list.collect do |token|
        begin
          # https://github.com/Shopify/liquid/issues/5
          token.force_encoding('utf-8') if token.respond_to?(:force_encoding)
          token.respond_to?(:render) ? token.render(context) : token
        rescue ::StandardError => e
          context.handle_error(e)
        end
      end.join
    end
  end
end

class Strip < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
  end

  def render(context)
    super.split(/\r?\n/).map{|line| line.strip }.join("")
  end
end

Liquid::Template.register_tag('strip', Strip)

