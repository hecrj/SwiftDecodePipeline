#
# Be sure to run `pod lib lint SwiftDecodePipeline.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftDecodePipeline'
  s.version          = '0.0.2'
  s.summary          = 'A library for building JSON decoders using the pipeline (|>) operator and plain function calls.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A library for building JSON decoders using the pipeline (|>) operator and plain function calls. Inspired by elm-decode-pipeline.
                       DESC

  s.homepage         = 'https://github.com/hecrj/SwiftDecodePipeline'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Héctor Ramón Jiménez' => 'hector0193@gmail.com' }
  s.source           = { :git => 'https://github.com/hecrj/SwiftDecodePipeline.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hecrj'

  s.ios.deployment_target = '8.0'

  s.source_files = 'SwiftDecodePipeline/**/*'

  s.dependency 'SwiftyJSON', '~> 3.0'
  s.dependency 'Curry', '~> 3.0'
end
