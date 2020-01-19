require 'net/http'
require 'yaml'
require 'json'

url = 'https://raw.githubusercontent.com/oneclick/rubyinstaller.org-website/master/_data/downloads.yaml'
entries = YAML.load(Net::HTTP.get(URI(url)), symbolize_names: true)

versions = entries.select { |entry|
  entry[:filetype] == 'rubyinstaller7z' and
  entry[:name].include?('(x64)')
}.group_by { |entry|
  entry[:name][/Ruby (\d+\.\d+\.\d+)/, 1]
}.map { |version, builds|
  unless builds.sort_by { |build| build[:name] } == builds.reverse
    raise "not sorted as expected for #{version}"
  end
  [version, builds.first]
}.sort_by { |version, entry|
  version
}.select { |version, entry|
  version >= "2.4"
}.map { |version, entry|
  [version, entry[:href]]
}.to_h

js = "export const versions = #{JSON.pretty_generate(versions)}\n"
File.write 'ruby-installer-versions.js', js
