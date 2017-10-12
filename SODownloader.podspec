#
# Be sure to run `pod lib lint SODownloader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SODownloader'
  s.version          = '0.1.2'
  s.summary          = 'A simple downloader base on AFNetworking.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

#  s.description      = <<-DESC
#A simple downloader base on AFNetworking.
#                       DESC

  s.homepage         = 'https://github.com/scfhao/SODownloader'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'scfhao' => 'scfhao@126.com' }
  s.source           = { :git => 'https://github.com/scfhao/SODownloader.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'SODownloader/Classes/*.{h,m}'

  # s.resource_bundles = {
  #   'SODownloader' => ['SODownloader/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking', '~> 3.0'
end
