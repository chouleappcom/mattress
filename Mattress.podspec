Pod::Spec.new do |s|
  s.name = 'Mattress'
  s.version = '1.0.4'
  s.license = 'MIT'
  s.summary = 'iOS Offline Caching for Web Content'
  s.homepage = 'https://github.com/buzzfeed/mattress'
  s.social_media_url = 'http://twitter.com/buzzfeed'
  s.authors = { 'David Mauro' => 'david.mauro@buzzfeed.com',
		'Kevin Lord'  => 'kevin.lord@buzzfeed.com' }
  s.source = { :git => 'https://github.com/buzzfeed/mattress.git', :tag => s.version }
  s.swift_version = ['5.0', '5.1', '5.2']    
  s.requires_arc = true
  s.ios.deployment_target = '11.0'
  s.source_files = 'Source/*.swift', 'Source/Extensions/*.swift'
  s.ios.dependency 'CryptoSwift', '~> 1.3.1'  
end