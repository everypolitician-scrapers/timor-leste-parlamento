#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('#text table').xpath('tr[td]').each do |tr|
    tds = tr.css('td')
    link = tds[0].css('a/@href').text
    link = URI.join(url, URI.escape(link)).to_s unless link.to_s.empty?

    data = {
      name:   tds[0].text.tidy,
      # role: tds[1].text.tidy,
      party:  tds[2].text.tidy,
      term:   2012,
      source: url,
    }.merge(scrape_person(link))
    data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
    puts data
    ScraperWiki.save_sqlite(%i(name term), data)
  end
end

def scrape_person(url)
  return {} if url.to_s.empty?
  noko = noko_for(url)
  box = noko.css('#main4')
  data = {
    image:  box.css('img/@src').text,
    area:   box.xpath('.//strong[text()="Distrito:"]/ancestor::td[1]').text.split(':', 2).last.to_s.tidy,
    source: url.to_s,
  }
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://www.parlamento.tl/deputadus/2012-2017/pt/index.php')
