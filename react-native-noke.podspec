require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']

  s.authors      = package['author']
  s.homepage     = package['homepage']
  s.platforms    = { :ios => "10" }

  s.source       = { :git => "https://github.com/codeback/react-native-noke.git", :tag => "master" }
  s.source_files  = "ios/**/*.{swift,h,m,c}"
  s.requires_arc = true

  s.dependency "React"

end
