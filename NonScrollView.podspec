Pod::Spec.new do |s|
    
  s.name             = 'NonScrollView'
  s.version          = '0.1.1'
  s.summary          = 'NonScrollView is not a scroll view.'

  s.description      = 'NonScrollView is not a scroll view. Yes.'

  s.homepage         = 'https://github.com/intitni/NonScrollView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'intitni' => 'int123c@gmail.com' }
  s.source           = { :git => 'https://github.com/intitni/NonScrollView.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/intitni'

  s.ios.deployment_target = '9.0'
  s.swift_version = '5'

  s.source_files = 'NonScrollView/Classes/**/*'
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |sa|
      sa.source_files = 'NonScrollView/Classes/Core/**/*'
  end
  
  s.subspec 'Containers' do |sb|
      sb.source_files = 'NonScrollView/Classes/Containers/**/*'
      sb.dependency 'NonScrollView/Core'
  end

end
