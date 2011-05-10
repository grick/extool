class HomeController < ApplicationController

require 'net/http'
require 'uri'
LN = 3
HN = 150

  public
  def index
	  	@title = get_title params[:url]
		@content = get_content params[:url]
  end

  private

# 抓取页面
	def fetch(uri)
		if uri =~ /http:\/\/([\w-]+\.)+[\w-]+(\/[\w\.\/?%=-]*)?/
		html = Net::HTTP.get_response(URI.parse(uri)).body
		else
			html = "<title>This URL is bad</title>"
		end
	end
# 去除HTML
	def filter(html, mode)
		case mode
		when 'a'
			text = html.gsub(/<!doctype.*?>|<!--.*?-->|<script.*?>.*?<\/script>|<style.*?>.*?<\/style>/im,'').gsub(/<.*?>/,'')
		when 'f'
			text = html.gsub(/<!doctype.*?>|<!--.*?-->|<script.*?>.*?<\/script>|<style.*?>.*?<\/style>/im,'')
			text = text.gsub(/<(\/?p)>/, "[\1]").gsub(/<(br[ \/]{0,2})>/,"[\1]").gsub(/<(img(.*?)\/)>/,"[\1]")
			text = text.gsub(/<.*?>/,'')
			text = text.gsub(/[(\/?p)]/, "<\1>").gsub(/[(br[ \/]{0,2})]/,"<\1>").gsub(/[(img(.*?)\/)]/,"<\1>")
		else
			text = html.gsub(/<!doctype.*?>|<!--.*?-->|<script.*?>.*?<\/script>|<style.*?>.*?<\/style>/im,'').gsub(/<.*?>/,'')
		end
	end
# 分析正文开始和结束
	def html_to_block(text)
		text_array = []
		i = 1
		text.each_line do |line|
			if (i%LN == 0)
				text_array << line
			else
				text_array << line.chomp
			end
			i = i + 1
		end
		block_array = text_array.join.split(/\n/)
	end

	def get_start_no(block_array)
		preline = ''
		ib = 1
		start_no = 0
		block_array.each do |line|
			if (line.strip.size - preline.strip.size) > HN
				start_no = ib
				break
			end
			preline = line
			ib = ib + 1
		end
		start_no
	end

	def output_content_from(block_array, start_no)
		if !start_no.eql?(0)
			content = []
			start_no.upto(block_array.length-1) do |no|
				content << block_array[no-1]
				if block_array[no].strip == ''
					break
				end
			end

			return content

		else
			return ["Can not extract this page :("]
		end
	end

	def get_content(uri)
	  html = fetch uri
	  text = filter html
	  block = html_to_block text
	  start_no = get_start_no block
	  output_content_from(block, start_no).join
	end

	def get_title(uri)
		html = fetch uri
		title = html.match(/<title>(.*?)<\/title>/)[1].gsub(/[_|-](.*)/,'')
	end
end
