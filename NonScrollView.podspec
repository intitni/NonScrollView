Pod::Spec.new do |s|
    
  s.name             = 'NonScrollView'
  s.version          = '0.1.0'
  s.summary          = 'A short description of NonScrollView.'

  s.description      = 'NonScrollView is not a scroll view.'

  s.homepage         = 'https://github.com/int123c/NonScrollView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'int123c' => 'int123c@gmail.com' }
  s.source           = { :git => 'https://github.com/int123c/NonScrollView.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/int123c'

  s.ios.deployment_target = '9.0'
  s.swift_version = '4.2'

  s.source_files = 'NonScrollView/Classes/**/*'
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |sa|
      sa.source_files = 'NonScrollView/Classes/Core/**/*'
  end
  
  s.subspec 'Containers' do |sb|
      sb.source_files = 'NonScrollView/Classes/Containers/**/*'
  end

end
